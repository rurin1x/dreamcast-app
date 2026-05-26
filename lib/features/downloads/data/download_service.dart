import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dream_cast/core/database/app_database.dart';
import 'package:dream_cast/features/downloads/data/download_notification_service.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:drift/drift.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const downloadEpisodeTaskName = 'dream_cast_download_episode';
const downloadEpisodeBatchTaskName = 'dream_cast_download_episode_batch';
const _downloadForegroundPayloadKey = 'download.foreground.payload';
const _downloadForegroundServiceId =
    DownloadNotificationService.activeForegroundNotificationId;

@pragma('vm:entry-point')
void downloadForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_DownloadForegroundTaskHandler());
}

final class _DownloadForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final raw = await FlutterForegroundTask.getData<String>(
      key: _downloadForegroundPayloadKey,
    );
    if (raw == null || raw.isEmpty) {
      await FlutterForegroundTask.stopService();
      return;
    }

    try {
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      await FlutterForegroundTask.updateService(
        notificationTitle: payload['title'] as String? ?? 'Загрузка серии',
        notificationText: payload['text'] as String? ?? 'Подготовка...',
      );

      final type = payload['type'] as String? ?? downloadEpisodeTaskName;
      final input = (payload['input'] as Map<String, dynamic>?) ?? {};
      if (type == downloadEpisodeBatchTaskName) {
        await DownloadService.runBackgroundBatchTask(input);
      } else {
        await DownloadService.runBackgroundTask(input);
      }
    } finally {
      await FlutterForegroundTask.removeData(
        key: _downloadForegroundPayloadKey,
      );
      await FlutterForegroundTask.stopService();
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

final class DownloadService {
  DownloadService(this._database, this._dio, {bool useForegroundTask = true})
    : _useForegroundTask = useForegroundTask;

  // HLS has many small media segments. Downloading them one by one is very
  // slow, while unlimited parallel requests can overload the server or radio.
  static const _segmentDownloadConcurrency = 4;

  final AppDatabase _database;
  final Dio _dio;
  final bool _useForegroundTask;
  final Map<String, CancelToken> _activeCancelTokens = {};

  Future<void> startDownload({
    required DreamRelease release,
    required DreamEpisode episode,
    required DreamStream stream,
    DownloadBatch? batch,
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
    if (batch == null) {
      await DownloadNotificationService.showQueued(
        release: release,
        episode: episode,
        notificationId: _downloadForegroundServiceId,
      );
    } else {
      await DownloadNotificationService.showBatchProgress(
        batchId: batch.id,
        title: batch.title,
        completed: 0,
        failed: 0,
        total: batch.episodeIds.length,
        notificationId: _downloadForegroundServiceId,
      );
    }

    if (_useForegroundTask) {
      await _startForegroundDownload(
        title: batch == null ? 'Загрузка серии' : 'Загрузка серий',
        text: '${release.title} • ${episode.title}',
        type: downloadEpisodeTaskName,
        input: _taskInputData(
          release: release,
          episode: episode,
          stream: stream,
          batch: batch,
        ),
      );
    }
  }

  Future<void> startBatchDownload({
    required DreamRelease release,
    required List<DreamEpisodeDownloadRequest> requests,
  }) async {
    if (requests.isEmpty) return;

    final batch = DownloadBatch(
      id: 'release_${release.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: release.title,
      episodeIds: requests.map((request) => request.episode.id).toSet(),
    );

    for (final request in requests) {
      await _database.saveDownloadedEpisode(
        DownloadedEpisodesCompanion(
          releaseId: Value(release.id),
          episodeId: Value(request.episode.id),
          releaseTitle: Value(release.title),
          episodeTitle: Value(request.episode.title),
          posterUrl: Value(release.posterUrl),
          episodeOrdinal: Value(request.episode.ordinal),
          localFilePath: const Value(''),
          fileSize: const Value(0),
          downloadedBytes: const Value(0),
          status: const Value('pending'),
          streamQuality: Value(request.stream.quality),
          createdAt: Value(DateTime.now()),
        ),
      );
    }

    await DownloadNotificationService.showBatchProgress(
      batchId: batch.id,
      title: batch.title,
      completed: 0,
      failed: 0,
      total: batch.episodeIds.length,
      notificationId: _downloadForegroundServiceId,
    );

    if (_useForegroundTask) {
      await _startForegroundDownload(
        title: 'Загрузка серий',
        text: release.title,
        type: downloadEpisodeBatchTaskName,
        input: _batchTaskInputData(
          release: release,
          requests: requests,
          batch: batch,
        ),
      );
    }
  }

  Future<void> cancelDownload(int releaseId, String episodeId) async {
    final key = _taskKey(releaseId, episodeId);
    final cancelToken = _activeCancelTokens.remove(key);
    cancelToken?.cancel('User cancelled download');
    await DownloadNotificationService.cancel(
      releaseId: releaseId,
      episodeId: episodeId,
    );
    await deleteDownload(releaseId, episodeId);
  }

  Future<void> deleteDownload(int releaseId, String episodeId) async {
    final record = await _database.downloadedEpisode(releaseId, episodeId);
    if (record != null && record.localFilePath.isNotEmpty) {
      await _deleteLocalDownloadPath(record.localFilePath);
    }
    await _database.deleteDownloadedEpisode(releaseId, episodeId);
    await DownloadNotificationService.cancel(
      releaseId: releaseId,
      episodeId: episodeId,
    );
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

  Future<void> runDownload({
    required DreamRelease release,
    required DreamEpisode episode,
    required DreamStream stream,
    DownloadBatch? batch,
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
      await _showDownloadNotificationState(
        release: release,
        episode: episode,
        batch: batch,
        downloaded: 0,
        total: playlist.segments.length,
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
          await _showDownloadNotificationState(
            release: release,
            episode: episode,
            batch: batch,
            downloaded: downloadedCount,
            total: playlist.segments.length,
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
      await _showDownloadNotificationState(
        release: release,
        episode: episode,
        batch: batch,
        completed: true,
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
        await _showDownloadNotificationState(
          release: release,
          episode: episode,
          batch: batch,
          failed: true,
        );
      }
    } finally {
      _activeCancelTokens.remove(key);
    }
  }

  static Future<bool> runBackgroundTask(Map<String, dynamic>? inputData) async {
    if (inputData == null) return false;

    final database = AppDatabase();
    try {
      final service = DownloadService(database, _createBackgroundDio());
      await service.runDownload(
        release: _releaseFromInput(inputData),
        episode: _episodeFromInput(inputData),
        stream: _streamFromInput(inputData),
        batch: _batchFromInput(inputData),
        cancelToken: CancelToken(),
      );
      return true;
    } finally {
      await database.close();
    }
  }

  static Future<bool> runBackgroundBatchTask(
    Map<String, dynamic>? inputData,
  ) async {
    if (inputData == null) return false;

    final database = AppDatabase();
    try {
      final service = DownloadService(database, _createBackgroundDio());
      await service.runBatchDownload(
        release: _releaseFromInput(inputData),
        requests: _downloadRequestsFromInput(inputData),
        batch: _batchFromInput(inputData),
        stopOnCancel: true,
      );
      return true;
    } finally {
      await database.close();
    }
  }

  Future<void> runBatchDownload({
    required DreamRelease release,
    required List<DreamEpisodeDownloadRequest> requests,
    required DownloadBatch? batch,
    required bool stopOnCancel,
  }) async {
    for (final request in requests) {
      final token = CancelToken();
      final key = _taskKey(release.id, request.episode.id);
      _activeCancelTokens[key] = token;

      await runDownload(
        release: release,
        episode: request.episode,
        stream: request.stream,
        batch: batch,
        cancelToken: token,
      );

      if (stopOnCancel && token.isCancelled) return;
    }
  }

  static Future<void> _startForegroundDownload({
    required String title,
    required String text,
    required String type,
    required Map<String, dynamic> input,
  }) async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: DownloadNotificationService.channelId,
        channelName: DownloadNotificationService.channelName,
        channelDescription: DownloadNotificationService.channelDescription,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }

    await FlutterForegroundTask.saveData(
      key: _downloadForegroundPayloadKey,
      value: jsonEncode({
        'type': type,
        'title': title,
        'text': text,
        'input': input,
      }),
    );

    final result = await FlutterForegroundTask.startService(
      serviceId: _downloadForegroundServiceId,
      serviceTypes: [ForegroundServiceTypes.dataSync],
      notificationTitle: title,
      notificationText: text,
      callback: downloadForegroundTaskCallback,
    );
    if (result is ServiceRequestFailure) {
      throw result.error;
    }
  }

  static Dio _createBackgroundDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
        followRedirects: true,
        maxRedirects: 5,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Mobile Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
          'Referer': 'https://dreamerscast.com/',
          'Origin': 'https://dreamerscast.com',
        },
      ),
    );
  }

  static Map<String, dynamic> _taskInputData({
    required DreamRelease release,
    required DreamEpisode episode,
    required DreamStream stream,
    DownloadBatch? batch,
  }) {
    return {
      'releaseId': release.id,
      'releaseTitle': release.title,
      'releaseOriginalTitle': release.originalTitle,
      'releaseUrl': release.url,
      if (release.posterUrl != null) 'releasePosterUrl': release.posterUrl!,
      'episodeId': episode.id,
      'episodeReleaseId': episode.releaseId,
      'episodeOrdinal': episode.ordinal,
      'episodeTitle': episode.title,
      'episodeFile': episode.file,
      'streamId': stream.id,
      'streamReleaseId': stream.releaseId,
      'streamEpisodeId': stream.episodeId,
      'streamUrl': stream.url.toString(),
      'streamType': stream.type.name,
      'streamQuality': stream.quality,
      'streamHeadersJson': jsonEncode(stream.headers),
      if (batch != null) 'batchId': batch.id,
      if (batch != null) 'batchTitle': batch.title,
      if (batch != null) 'batchEpisodeIdsJson': jsonEncode(batch.episodeIds),
    };
  }

  static Map<String, dynamic> _batchTaskInputData({
    required DreamRelease release,
    required List<DreamEpisodeDownloadRequest> requests,
    required DownloadBatch batch,
  }) {
    return {
      'releaseId': release.id,
      'releaseTitle': release.title,
      'releaseOriginalTitle': release.originalTitle,
      'releaseUrl': release.url,
      if (release.posterUrl != null) 'releasePosterUrl': release.posterUrl!,
      'batchId': batch.id,
      'batchTitle': batch.title,
      'batchEpisodeIdsJson': jsonEncode(batch.episodeIds.toList()),
      'downloadRequestsJson': jsonEncode(
        requests.map((request) => _downloadRequestToJson(request)).toList(),
      ),
    };
  }

  static Map<String, Object?> _downloadRequestToJson(
    DreamEpisodeDownloadRequest request,
  ) {
    return {
      'episode': {
        'id': request.episode.id,
        'releaseId': request.episode.releaseId,
        'ordinal': request.episode.ordinal,
        'title': request.episode.title,
        'file': request.episode.file,
        'label': request.episode.label,
        'thumbnailUrl': request.episode.thumbnailUrl,
        'embedUrl': request.episode.embedUrl,
        'vars': request.episode.vars,
      },
      'stream': {
        'id': request.stream.id,
        'releaseId': request.stream.releaseId,
        'episodeId': request.stream.episodeId,
        'url': request.stream.url.toString(),
        'type': request.stream.type.name,
        'quality': request.stream.quality,
        'headers': request.stream.headers,
        'expiresAt': request.stream.expiresAt?.toIso8601String(),
      },
    };
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

  Future<void> _showDownloadNotificationState({
    required DreamRelease release,
    required DreamEpisode episode,
    required DownloadBatch? batch,
    int downloaded = 0,
    int total = 0,
    bool completed = false,
    bool failed = false,
  }) async {
    if (batch == null) {
      if (completed) {
        await _updateForegroundDownloadNotification(
          title: 'Серия скачана',
          text: '${release.title} • ${episode.title}',
        );
        await DownloadNotificationService.showCompleted(
          release: release,
          episode: episode,
          notificationId: _downloadForegroundServiceId,
        );
      } else if (failed) {
        await _updateForegroundDownloadNotification(
          title: 'Загрузка не удалась',
          text: '${release.title} • ${episode.title}',
        );
        await DownloadNotificationService.showFailed(
          release: release,
          episode: episode,
          notificationId: _downloadForegroundServiceId,
        );
      } else {
        await _updateForegroundDownloadNotification(
          title: 'Загрузка серии',
          text: '${release.title} • ${episode.title}',
        );
        await DownloadNotificationService.showProgress(
          release: release,
          episode: episode,
          downloaded: downloaded,
          total: total,
          notificationId: _downloadForegroundServiceId,
        );
      }
      return;
    }

    final downloads = await _database.allDownloadedEpisodes();
    final batchEpisodes = downloads.where(
      (download) =>
          download.releaseId == release.id &&
          batch.episodeIds.contains(download.episodeId),
    );
    final completedCount = batchEpisodes
        .where((download) => download.status == 'completed')
        .length;
    final failedCount = batchEpisodes
        .where((download) => download.status == 'failed')
        .length;
    final safeTotal = batch.episodeIds.isEmpty ? 1 : batch.episodeIds.length;
    final doneCount = (completedCount + failedCount).clamp(0, safeTotal);
    final isFinished = doneCount >= safeTotal;
    final title = isFinished
        ? (failedCount > 0 ? 'Загрузка завершена с ошибками' : 'Серии скачаны')
        : 'Загрузка серий';
    final currentProgress = completed || failed
        ? 'готово $doneCount из $safeTotal'
        : 'готово $doneCount из $safeTotal • скачивается: ${episode.title}';
    final failedSuffix = failedCount > 0 ? ', ошибок: $failedCount' : '';
    await _updateForegroundDownloadNotification(
      title: title,
      text: '${batch.title} • $currentProgress$failedSuffix',
    );
    await DownloadNotificationService.showBatchProgress(
      batchId: batch.id,
      title: batch.title,
      completed: completedCount,
      failed: failedCount,
      total: batch.episodeIds.length,
      notificationId: _downloadForegroundServiceId,
    );
  }

  static Future<void> _updateForegroundDownloadNotification({
    required String title,
    required String text,
  }) async {
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    } catch (_) {
      // The foreground-task notification is absent in tests and old local
      // fallback paths. Final state is still published by the notification
      // service below.
    }
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

  static DreamRelease _releaseFromInput(Map<String, dynamic> input) {
    return DreamRelease(
      id: input['releaseId'] as int,
      title: input['releaseTitle'] as String,
      originalTitle: input['releaseOriginalTitle'] as String? ?? '',
      url: input['releaseUrl'] as String? ?? '',
      posterUrl: input['releasePosterUrl'] as String?,
    );
  }

  static DreamEpisode _episodeFromInput(Map<String, dynamic> input) {
    return DreamEpisode(
      id: input['episodeId'] as String,
      releaseId: input['episodeReleaseId'] as int,
      ordinal: input['episodeOrdinal'] as int,
      title: input['episodeTitle'] as String,
      file: input['episodeFile'] as String,
    );
  }

  static DreamStream _streamFromInput(Map<String, dynamic> input) {
    final headersJson = input['streamHeadersJson'] as String? ?? '{}';
    final headers = (jsonDecode(headersJson) as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, '$value'),
    );

    return DreamStream(
      id: input['streamId'] as String,
      releaseId: input['streamReleaseId'] as int,
      episodeId: input['streamEpisodeId'] as String,
      url: Uri.parse(input['streamUrl'] as String),
      type: DreamStreamType.values.firstWhere(
        (type) => type.name == input['streamType'],
        orElse: () => DreamStreamType.hls,
      ),
      quality: input['streamQuality'] as int,
      headers: headers,
    );
  }

  static DownloadBatch? _batchFromInput(Map<String, dynamic> input) {
    final id = input['batchId'] as String?;
    if (id == null || id.isEmpty) return null;
    final episodeIdsJson = input['batchEpisodeIdsJson'] as String? ?? '[]';
    return DownloadBatch(
      id: id,
      title: input['batchTitle'] as String? ?? 'Серии',
      episodeIds: (jsonDecode(episodeIdsJson) as List<dynamic>)
          .map((value) => '$value')
          .toSet(),
    );
  }

  static List<DreamEpisodeDownloadRequest> _downloadRequestsFromInput(
    Map<String, dynamic> input,
  ) {
    final raw = input['downloadRequestsJson'] as String? ?? '[]';
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_downloadRequestFromJson)
        .toList();
  }

  static DreamEpisodeDownloadRequest _downloadRequestFromJson(
    Map<String, dynamic> json,
  ) {
    final episodeJson = json['episode'] as Map<String, dynamic>;
    final streamJson = json['stream'] as Map<String, dynamic>;
    final headers = (streamJson['headers'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(key, '$value'),
    );

    return DreamEpisodeDownloadRequest(
      episode: DreamEpisode(
        id: episodeJson['id'] as String,
        releaseId: episodeJson['releaseId'] as int,
        ordinal: episodeJson['ordinal'] as int,
        title: episodeJson['title'] as String,
        file: episodeJson['file'] as String,
        label: episodeJson['label'] as String?,
        thumbnailUrl: episodeJson['thumbnailUrl'] as String?,
        embedUrl: episodeJson['embedUrl'] as String?,
        vars: (episodeJson['vars'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, '$value'),
        ),
      ),
      stream: DreamStream(
        id: streamJson['id'] as String,
        releaseId: streamJson['releaseId'] as int,
        episodeId: streamJson['episodeId'] as String,
        url: Uri.parse(streamJson['url'] as String),
        type: DreamStreamType.values.firstWhere(
          (type) => type.name == streamJson['type'],
          orElse: () => DreamStreamType.hls,
        ),
        quality: streamJson['quality'] as int,
        headers: headers,
        expiresAt: streamJson['expiresAt'] == null
            ? null
            : DateTime.tryParse(streamJson['expiresAt'] as String),
      ),
    );
  }
}

final class DreamEpisodeDownloadRequest {
  const DreamEpisodeDownloadRequest({
    required this.episode,
    required this.stream,
  });

  final DreamEpisode episode;
  final DreamStream stream;
}

final class DownloadBatch {
  const DownloadBatch({
    required this.id,
    required this.title,
    required this.episodeIds,
  });

  final String id;
  final String title;
  final Set<String> episodeIds;
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
