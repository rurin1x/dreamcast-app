import 'package:dio/dio.dart';
import 'package:dream_cast/core/cache/cache_repository.dart';
import 'package:dream_cast/core/errors/app_exception.dart';
import 'package:dream_cast/features/releases/data/dream_cast_api.dart';
import 'package:dream_cast/features/releases/data/dream_cast_diagnostics.dart';
import 'package:dream_cast/features/releases/data/dream_cast_parser_service.dart';
import 'package:dream_cast/features/releases/data/dto/dream_release_dto.dart';
import 'package:dream_cast/features/releases/domain/release.dart';

final class DreamData<T> {
  const DreamData({required this.value, required this.isStale});

  final T value;
  final bool isStale;
}

final class ReleaseRepository {
  const ReleaseRepository({
    required DreamCastApi api,
    required CacheRepository cache,
    required DreamCastParserService parser,
  }) : _api = api,
       _cache = cache,
       _parser = parser;

  static const releasesTtl = Duration(minutes: 20);
  static const detailsTtl = Duration(hours: 8);
  static const streamsTtl = Duration(hours: 2);

  final DreamCastApi _api;
  final CacheRepository _cache;
  final DreamCastParserService _parser;

  Future<ReleasePage<DreamRelease>> ongoing({
    int page = 1,
    int pageSize = 16,
    CancelToken? cancelToken,
  }) async {
    return (await ongoingCached(
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    )).value;
  }

  Future<DreamData<ReleasePage<DreamRelease>>> ongoingCached({
    int page = 1,
    int pageSize = 16,
    CancelToken? cancelToken,
  }) {
    return _getReleasePage(
      cacheKey: 'dreamcast:releases:ongoing:$page:$pageSize',
      page: page,
      pageSize: pageSize,
      request: () => _api.getReleases(
        page: page,
        pageSize: pageSize,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<ReleasePage<DreamRelease>> search(
    String query, {
    int page = 1,
    int pageSize = 16,
    CancelToken? cancelToken,
  }) async {
    return (await searchCached(
      query,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    )).value;
  }

  Future<DreamData<ReleasePage<DreamRelease>>> searchCached(
    String query, {
    int page = 1,
    int pageSize = 16,
    CancelToken? cancelToken,
  }) {
    final normalized = query.trim().toLowerCase();
    return _getReleasePage(
      cacheKey: 'dreamcast:releases:search:$normalized:$page:$pageSize',
      page: page,
      pageSize: pageSize,
      request: () => _api.getReleases(
        query: normalized,
        page: page,
        pageSize: pageSize,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<DreamData<DreamReleaseDetail>> getDetail(
    DreamRelease release, {
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'dreamcast:detail:${release.id}';

    try {
      final html = await _api.getReleaseHtml(
        release.url,
        cancelToken: cancelToken,
      );
      final parsed = _parser.parseReleasePage(html);
      logDreamCastDiagnostic(
        'Repository detail parsed: id=${release.id}, title="${parsed.title}", '
        'thumb="${parsed.thumbnailUrl}", script="${parsed.playerScriptUrl}"',
      );
      final detail = DreamReleaseDetail(
        release: release,
        title: parsed.title,
        description: parsed.description,
        thumbnailUrl: parsed.thumbnailUrl,
        playerPayload: parsed.playerPayload,
        playerScriptUrl: parsed.playerScriptUrl,
        fetchedAt: DateTime.now(),
      );
      await _cache.putJson(cacheKey, _detailToJson(detail), ttl: detailsTtl);
      return DreamData(value: detail, isStale: false);
    } catch (error) {
      final cached = await _detailFromCache(cacheKey, release);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<DreamData<List<DreamEpisode>>> getEpisodes(
    DreamReleaseDetail detail, {
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'dreamcast:episodes:${detail.release.id}';

    try {
      final script = await _api.getPlayerScript(
        detail.playerScriptUrl,
        cancelToken: cancelToken,
      );
      final episodes = _parser.extractEpisodes(
        releaseId: detail.release.id,
        playerScript: script,
        encodedPayload: detail.playerPayload,
      );
      logDreamCastDiagnostic(
        'Repository episodes parsed: release=${detail.release.id}, count=${episodes.length}, '
        'first="${episodes.isEmpty ? null : episodes.first.title}"',
      );
      await _cache.putJson(cacheKey, {
        'episodes': episodes.map(_episodeToJson).toList(),
      }, ttl: detailsTtl);
      return DreamData(value: episodes, isStale: false);
    } catch (error) {
      final cached = await _episodesFromCache(cacheKey);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<DreamData<List<DreamStream>>> getStreams(DreamEpisode episode) async {
    final cacheKey = 'dreamcast:streams:${episode.releaseId}:${episode.id}';

    final cached = await _streamsFromCache(cacheKey);
    if (cached != null && !cached.isStale) return cached;

    final streams = _parser.extractStreams(episode);
    logDreamCastDiagnostic(
      'Repository streams extracted: release=${episode.releaseId}, episode=${episode.id}, '
      'count=${streams.length}, first="${streams.isEmpty ? null : streams.first.url}"',
    );
    if (streams.isEmpty) {
      throw const ParserException('Для серии не найдены потоки видео.');
    }

    await _cache.putJson(cacheKey, {
      'streams': streams.map(_streamToJson).toList(),
    }, ttl: streamsTtl);
    return DreamData(value: streams, isStale: false);
  }

  Future<DreamData<ReleasePage<DreamRelease>>> _getReleasePage({
    required String cacheKey,
    required int page,
    required int pageSize,
    required Future<DreamReleaseListDto> Function() request,
  }) async {
    try {
      final dto = await request();
      await _cache.putJson(cacheKey, dto.toJson(), ttl: releasesTtl);
      final pageData = _releasePageFromDto(dto, page: page, pageSize: pageSize);
      logReleaseSample(
        source: 'Repository releases network page=$page',
        releases: pageData.items,
        totalCount: pageData.totalCount,
        isStale: false,
      );
      return DreamData(
        value: pageData,
        isStale: false,
      );
    } catch (error) {
      final cached = await _cache.getJsonMap(cacheKey);
      if (cached == null) rethrow;
      final dto = DreamReleaseListDto.fromJson(cached.value);
      final pageData = _releasePageFromDto(dto, page: page, pageSize: pageSize);
      logReleaseSample(
        source: 'Repository releases cache page=$page',
        releases: pageData.items,
        totalCount: pageData.totalCount,
        isStale: true,
      );
      return DreamData(
        value: pageData,
        isStale: true,
      );
    }
  }

  ReleasePage<DreamRelease> _releasePageFromDto(
    DreamReleaseListDto dto, {
    required int page,
    required int pageSize,
  }) {
    return ReleasePage<DreamRelease>(
      items: dto.releases
          .map((release) => release.toDomain())
          .toList(growable: false),
      totalCount: dto.count,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<DreamData<DreamReleaseDetail>?> _detailFromCache(
    String cacheKey,
    DreamRelease release,
  ) async {
    final cached = await _cache.getJsonMap(cacheKey);
    if (cached == null) return null;
    return DreamData(
      value: _detailFromJson(cached.value, release),
      isStale: true,
    );
  }

  Future<DreamData<List<DreamEpisode>>?> _episodesFromCache(
    String cacheKey,
  ) async {
    final cached = await _cache.getJsonMap(cacheKey);
    if (cached == null) return null;
    final raw = cached.value['episodes'];
    if (raw is! List) return null;
    return DreamData(
      value: raw
          .whereType<Map>()
          .map((item) => _episodeFromJson(item.cast<String, Object?>()))
          .toList(growable: false),
      isStale: true,
    );
  }

  Future<DreamData<List<DreamStream>>?> _streamsFromCache(
    String cacheKey,
  ) async {
    final cached = await _cache.getJsonMap(cacheKey);
    if (cached == null) return null;
    final raw = cached.value['streams'];
    if (raw is! List) return null;
    return DreamData(
      value: raw
          .whereType<Map>()
          .map((item) => _streamFromJson(item.cast<String, Object?>()))
          .toList(growable: false),
      isStale: cached.isStale,
    );
  }

  Map<String, Object?> _detailToJson(DreamReleaseDetail detail) => {
    'title': detail.title,
    'description': detail.description,
    'thumbnailUrl': detail.thumbnailUrl,
    'playerPayload': detail.playerPayload,
    'playerScriptUrl': detail.playerScriptUrl,
    'fetchedAt': detail.fetchedAt.toIso8601String(),
  };

  DreamReleaseDetail _detailFromJson(
    Map<String, Object?> json,
    DreamRelease release,
  ) {
    final playerPayload = json['playerPayload'] as String?;
    final playerScriptUrl = json['playerScriptUrl'] as String?;
    if (playerPayload == null || playerScriptUrl == null) {
      throw const CacheException('Кэш страницы релиза повреждён.');
    }

    return DreamReleaseDetail(
      release: release,
      title: json['title'] as String? ?? release.title,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      playerPayload: playerPayload,
      playerScriptUrl: playerScriptUrl,
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, Object?> _episodeToJson(DreamEpisode episode) => {
    'id': episode.id,
    'releaseId': episode.releaseId,
    'ordinal': episode.ordinal,
    'title': episode.title,
    'file': episode.file,
    'label': episode.label,
    'thumbnailUrl': episode.thumbnailUrl,
    'embedUrl': episode.embedUrl,
    'vars': episode.vars,
  };

  DreamEpisode _episodeFromJson(Map<String, Object?> json) {
    return DreamEpisode(
      id: json['id'] as String,
      releaseId: (json['releaseId'] as num).toInt(),
      ordinal: (json['ordinal'] as num).toInt(),
      title: json['title'] as String,
      file: json['file'] as String,
      label: json['label'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      embedUrl: json['embedUrl'] as String?,
      vars:
          (json['vars'] as Map?)?.map(
            (key, value) => MapEntry('$key', '$value'),
          ) ??
          const {},
    );
  }

  Map<String, Object?> _streamToJson(DreamStream stream) => {
    'id': stream.id,
    'releaseId': stream.releaseId,
    'episodeId': stream.episodeId,
    'url': stream.url.toString(),
    'type': stream.type.name,
    'quality': stream.quality,
    'headers': stream.headers,
    'expiresAt': stream.expiresAt?.toIso8601String(),
  };

  DreamStream _streamFromJson(Map<String, Object?> json) {
    return DreamStream(
      id: json['id'] as String,
      releaseId: (json['releaseId'] as num).toInt(),
      episodeId: json['episodeId'] as String,
      url: Uri.parse(json['url'] as String),
      type: DreamStreamType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => DreamStreamType.unknown,
      ),
      quality: (json['quality'] as num).toInt(),
      headers:
          (json['headers'] as Map?)?.map(
            (key, value) => MapEntry('$key', '$value'),
          ) ??
          const {},
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
    );
  }
}
