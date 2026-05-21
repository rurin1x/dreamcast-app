import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dream_cast/core/database/app_database.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final class DownloadService {
  DownloadService(this._database, this._dio);

  // HLS has many small media segments. Downloading them one by one is very
  // slow, while unlimited parallel requests can overload the server or radio.
  static const _segmentDownloadConcurrency = 6;

  final AppDatabase _database;
  final Dio _dio;
  final Map<String, CancelToken> _activeCancelTokens = {};

  Future<void> startDownload({
    required DreamRelease release,
    required DreamEpisode episode,
    required DreamStream stream,
  }) async {
    final key = _taskKey(release.id, episode.id);
    if (_activeCancelTokens.containsKey(key)) return;

    final cancelToken = CancelToken();
    _activeCancelTokens[key] = cancelToken;

    await _database.saveDownloadedEpisode(
      DownloadedEpisodesCompanion(
        releaseId: Value(release.id),
        episodeId: Value(episode.id),
        releaseTitle: Value(release.title),
        episodeTitle: Value(episode.title),
        posterUrl: Value(release.posterUrl),
        episodeOrdinal: Value(episode.ordinal),
        localFilePath: const Value(''),
        fileSize: const Value(0),
        downloadedBytes: const Value(0),
        status: const Value('pending'),
        streamQuality: Value(stream.quality),
        createdAt: Value(DateTime.now()),
      ),
    );

    unawaited(
      _runDownload(
        release: release,
        episode: episode,
        stream: stream,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<void> cancelDownload(int releaseId, String episodeId) async {
    final key = _taskKey(releaseId, episodeId);
    final cancelToken = _activeCancelTokens.remove(key);
    cancelToken?.cancel('User cancelled download');
    await deleteDownload(releaseId, episodeId);
  }

  Future<void> deleteDownload(int releaseId, String episodeId) async {
    final record = await _database.downloadedEpisode(releaseId, episodeId);
    if (record != null && record.localFilePath.isNotEmpty) {
      await _deleteLocalDownloadPath(record.localFilePath);
    }
    await _database.deleteDownloadedEpisode(releaseId, episodeId);
  }

  Future<void> deleteAllDownloads() async {
    for (final token in _activeCancelTokens.values) {
      token.cancel('All downloads cleared');
    }
    _activeCancelTokens.clear();

    final downloads = await _database.allDownloadedEpisodes();
    for (final record in downloads) {
      if (record.localFilePath.isEmpty) continue;
      await _deleteLocalDownloadPath(record.localFilePath);
    }
    await _database.deleteAllDownloadedEpisodes();
  }

  String _taskKey(int releaseId, String episodeId) => '${releaseId}_$episodeId';

  Future<void> _runDownload({
    required DreamRelease release,
    required DreamEpisode episode,
    required DreamStream stream,
    required CancelToken cancelToken,
  }) async {
    final key = _taskKey(release.id, episode.id);
    File? tempPlaylist;
    Directory? episodeDir;

    try {
      if (stream.type != DreamStreamType.hls) {
        throw StateError(
          'Для офлайн-загрузки сейчас поддерживается только HLS.',
        );
      }

      final playlistUrl = await _resolveHlsUrl(
        stream.url.toString(),
        stream.quality,
        stream.headers,
        cancelToken,
      );
      if (playlistUrl == null) {
        throw StateError('Не удалось открыть HLS-плейлист.');
      }

      final playlist = await _getHlsMediaPlaylist(
        playlistUrl,
        stream.headers,
        cancelToken,
      );
      if (playlist.segments.isEmpty) {
        throw StateError('В HLS-плейлисте нет сегментов.');
      }

      await _database.updateDownloadedEpisode(
        release.id,
        episode.id,
        DownloadedEpisodesCompanion(
          status: const Value('downloading'),
          fileSize: Value(playlist.segments.length),
          downloadedBytes: const Value(0),
        ),
      );

      final docDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(p.join(docDir.path, 'downloads'));
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      episodeDir = Directory(
        p.join(
          downloadsDir.path,
          'ep_${release.id}_${_safeFilePart(episode.id)}',
        ),
      );
      if (await episodeDir.exists()) {
        await episodeDir.delete(recursive: true);
      }
      await episodeDir.create(recursive: true);

      tempPlaylist = File(p.join(episodeDir.path, 'playlist.tmp'));
      final playlistUri = Uri.parse(playlistUrl);
      final localResourceNames = <String, String>{};
      var downloadedCount = 0;
      var downloadedSize = 0;
      var lastUpdateTime = DateTime.now();

      var resourceIndex = 0;
      for (final resourcePath in playlist.uriAttributes) {
        final resourceUrl = playlistUri.resolve(resourcePath).toString();
        final resourceName = _resourceFileName(resourceIndex++, resourceUrl);
        final resourceFile = File(p.join(episodeDir.path, resourceName));
        final resource = await _downloadHlsResource(
          sourcePath: resourcePath,
          sourceUrl: resourceUrl,
          localName: resourceName,
          targetFile: resourceFile,
          headers: stream.headers,
          cancelToken: cancelToken,
          emptyMessage: 'Пустой HLS-ресурс: $resourceUrl',
        );
        localResourceNames[resource.sourcePath] = resource.localName;
        downloadedSize += resource.bytes;
      }

      for (
        var start = 0;
        start < playlist.segments.length;
        start += _segmentDownloadConcurrency
      ) {
        if (cancelToken.isCancelled) {
          throw DioException(
            requestOptions: RequestOptions(path: playlistUrl),
            type: DioExceptionType.cancel,
            message: 'Download cancelled',
          );
        }

        final end = (start + _segmentDownloadConcurrency).clamp(
          0,
          playlist.segments.length,
        );
        final chunk = <Future<_DownloadedHlsResource>>[];
        for (var index = start; index < end; index++) {
          final segmentPath = playlist.segments[index];
          final segmentUrl = playlistUri.resolve(segmentPath).toString();
          final segmentName = _segmentFileName(index, segmentUrl);
          final segmentFile = File(p.join(episodeDir.path, segmentName));
          chunk.add(
            _downloadHlsResource(
              sourcePath: segmentPath,
              sourceUrl: segmentUrl,
              localName: segmentName,
              targetFile: segmentFile,
              headers: stream.headers,
              cancelToken: cancelToken,
              emptyMessage: 'Пустой HLS-сегмент: $segmentUrl',
              flush: index % 10 == 0,
            ),
          );
        }

        final downloaded = await Future.wait(chunk);
        for (final resource in downloaded) {
          localResourceNames[resource.sourcePath] = resource.localName;
          downloadedSize += resource.bytes;
          downloadedCount++;
        }

        final now = DateTime.now();
        if (now.difference(lastUpdateTime) >= const Duration(seconds: 1) ||
            downloadedCount == playlist.segments.length) {
          await _database.updateDownloadedEpisode(
            release.id,
            episode.id,
            DownloadedEpisodesCompanion(
              downloadedBytes: Value(downloadedCount),
            ),
          );
          lastUpdateTime = now;
        }
      }

      await tempPlaylist.writeAsString(
        _rewritePlaylistForOffline(playlist.lines, localResourceNames),
        flush: true,
      );
      final finalPlaylist = File(p.join(episodeDir.path, 'playlist.m3u8'));
      if (await finalPlaylist.exists()) await finalPlaylist.delete();
      await tempPlaylist.rename(finalPlaylist.path);
      tempPlaylist = null;

      await _database.updateDownloadedEpisode(
        release.id,
        episode.id,
        DownloadedEpisodesCompanion(
          status: const Value('completed'),
          localFilePath: Value(finalPlaylist.path),
          fileSize: Value(downloadedSize),
          downloadedBytes: Value(downloadedSize),
        ),
      );
    } catch (_) {
      if (tempPlaylist != null && await tempPlaylist.exists()) {
        try {
          await tempPlaylist.delete();
        } catch (_) {}
      }

      if (!cancelToken.isCancelled) {
        await _database.updateDownloadedEpisode(
          release.id,
          episode.id,
          const DownloadedEpisodesCompanion(status: Value('failed')),
        );
      }
    } finally {
      _activeCancelTokens.remove(key);
    }
  }

  Future<_DownloadedHlsResource> _downloadHlsResource({
    required String sourcePath,
    required String sourceUrl,
    required String localName,
    required File targetFile,
    required Map<String, String> headers,
    required CancelToken cancelToken,
    required String emptyMessage,
    bool flush = false,
  }) async {
    final response = await _dio.get<List<int>>(
      sourceUrl,
      options: Options(responseType: ResponseType.bytes, headers: headers),
      cancelToken: cancelToken,
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw StateError(emptyMessage);
    }

    await targetFile.writeAsBytes(bytes, flush: flush);
    return _DownloadedHlsResource(
      sourcePath: sourcePath,
      localName: localName,
      bytes: bytes.length,
    );
  }

  Future<String?> _resolveHlsUrl(
    String url,
    int preferredQuality,
    Map<String, String> headers,
    CancelToken cancelToken,
  ) async {
    final response = await _dio.get<String>(
      url,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
    final content = response.data;
    if (content == null) return null;

    if (!content.contains('#EXT-X-STREAM-INF')) return url;

    final lines = content.split('\n');
    int? bestQuality;
    String? bestPath;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('#EXT-X-STREAM-INF:')) continue;

      var quality = preferredQuality;
      final resolutionMatch = RegExp(
        r'RESOLUTION=(\d+)x(\d+)',
      ).firstMatch(line);
      if (resolutionMatch != null) {
        quality = int.parse(resolutionMatch.group(2)!);
      }

      if (i + 1 >= lines.length) continue;
      final nextLine = lines[i + 1].trim();
      if (nextLine.isEmpty || nextLine.startsWith('#')) continue;

      if (bestQuality == null ||
          (quality - preferredQuality).abs() <
              (bestQuality - preferredQuality).abs()) {
        bestQuality = quality;
        bestPath = nextLine;
      }
    }

    return bestPath == null ? url : Uri.parse(url).resolve(bestPath).toString();
  }

  Future<_HlsMediaPlaylist> _getHlsMediaPlaylist(
    String playlistUrl,
    Map<String, String> headers,
    CancelToken cancelToken,
  ) async {
    final response = await _dio.get<String>(
      playlistUrl,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
    final content = response.data;
    if (content == null) return const _HlsMediaPlaylist([], [], []);

    final lines = content.split('\n');
    final segments = <String>[];
    final uriAttributes = <String>[];
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) {
        final uri = RegExp(r'URI="([^"]+)"').firstMatch(line)?.group(1);
        if (uri != null && uri.isNotEmpty && !uri.startsWith('data:')) {
          uriAttributes.add(uri);
        }
        continue;
      }
      segments.add(line);
    }
    return _HlsMediaPlaylist(lines, segments, uriAttributes);
  }

  String _rewritePlaylistForOffline(
    List<String> lines,
    Map<String, String> localResourceNames,
  ) {
    return lines
        .map((rawLine) {
          final line = rawLine.trim();
          if (line.isEmpty) return rawLine;
          if (line.startsWith('#')) {
            return rawLine.replaceAllMapped(RegExp(r'URI="([^"]+)"'), (match) {
              final original = match.group(1)!;
              final local = localResourceNames[original];
              return local == null ? match.group(0)! : 'URI="$local"';
            });
          }
          return localResourceNames[line] ?? rawLine;
        })
        .join('\n');
  }

  Future<void> _deleteLocalDownloadPath(String localFilePath) async {
    final file = File(localFilePath);
    final parent = file.parent;
    try {
      if (p.basename(file.path) == 'playlist.m3u8' && await parent.exists()) {
        await parent.delete(recursive: true);
      } else if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best effort cleanup.
    }
  }

  String _segmentFileName(int index, String segmentUrl) {
    final uri = Uri.parse(segmentUrl);
    final extension = p.extension(uri.path).isEmpty
        ? '.ts'
        : p.extension(uri.path);
    return 'segment_${index.toString().padLeft(5, '0')}$extension';
  }

  String _resourceFileName(int index, String resourceUrl) {
    final uri = Uri.parse(resourceUrl);
    final extension = p.extension(uri.path).isEmpty
        ? '.bin'
        : p.extension(uri.path);
    return 'resource_${index.toString().padLeft(3, '0')}$extension';
  }

  String _safeFilePart(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }
}

final class _DownloadedHlsResource {
  const _DownloadedHlsResource({
    required this.sourcePath,
    required this.localName,
    required this.bytes,
  });

  final String sourcePath;
  final String localName;
  final int bytes;
}

final class _HlsMediaPlaylist {
  const _HlsMediaPlaylist(this.lines, this.segments, this.uriAttributes);

  final List<String> lines;
  final List<String> segments;
  final List<String> uriAttributes;
}
