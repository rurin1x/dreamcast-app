import 'package:dio/dio.dart';
import 'package:dream_cast/core/cache/cache_repository.dart';
import 'package:dream_cast/core/errors/app_exception.dart';
import 'package:dream_cast/features/releases/data/dream_cast_api.dart';
import 'package:dream_cast/features/releases/data/dream_cast_diagnostics.dart';
import 'package:dream_cast/features/releases/data/dream_cast_parser_service.dart';
import 'package:dream_cast/features/releases/data/dto/dream_release_dto.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/schedule/domain/release_schedule.dart';

final class DreamData<T> {
  const DreamData({
    required this.value,
    required this.isStale,
    this.diagnostics,
  });

  final T value;
  final bool isStale;
  final String? diagnostics;
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
  static const scheduleTtl = Duration(minutes: 30);

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
        'thumb="${parsed.thumbnailUrl}", script="${parsed.playerScriptUrl}", '
        'payloadLength=${parsed.playerPayload.length}, payloadPreview="${_snippet(parsed.playerPayload)}"',
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
    } catch (error, stackTrace) {
      logDreamCastDiagnostic(
        'Repository detail parse failed: release=${release.id}, '
        'errorType=${error.runtimeType}, error=$error, stackTrace=$stackTrace',
      );
      final cached = await _detailFromCache(cacheKey, release);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<DreamData<ReleaseSchedule>> getSchedule({
    CancelToken? cancelToken,
  }) async {
    const cacheKey = 'dreamcast:schedule';

    try {
      final html = await _api.getScheduleHtml(cancelToken: cancelToken);
      final schedule = _parser.parseSchedule(html);
      final itemCount = schedule.days.fold<int>(
        0,
        (sum, day) => sum + day.releases.length,
      );
      if (itemCount == 0) {
        throw const ParserException(
          'Расписание загрузилось, но релизы в нём не найдены.',
        );
      }
      logDreamCastDiagnostic(
        'Repository schedule parsed: days=${schedule.days.length}, '
        'items=$itemCount',
      );
      await _cache.putJson(
        cacheKey,
        _scheduleToJson(schedule),
        ttl: scheduleTtl,
      );
      return DreamData(value: schedule, isStale: false);
    } catch (error, stackTrace) {
      logDreamCastDiagnostic(
        'Repository schedule failed: errorType=${error.runtimeType}, '
        'error=$error, stackTrace=$stackTrace',
      );
      final cached = await _scheduleFromCache(cacheKey);
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
      logDreamCastDiagnostic(
        'Repository episodes decode start: release=${detail.release.id}, '
        'payloadLength=${detail.playerPayload.length}, payloadPreview="${_snippet(detail.playerPayload)}", '
        'scriptLength=${script.length}, scriptPreview="${_snippet(script)}"',
      );
      final result = _parser.extractEpisodesWithDiagnostics(
        releaseId: detail.release.id,
        playerScript: script,
        encodedPayload: detail.playerPayload,
      );
      final episodes = result.episodes;
      logDreamCastDiagnostic(
        'Repository episodes parsed: release=${detail.release.id}, count=${episodes.length}, '
        'first="${episodes.isEmpty ? null : episodes.first.title}", '
        'diagnostics=${result.diagnostics}',
      );
      await _cache.putJson(cacheKey, {
        'episodes': episodes.map(_episodeToJson).toList(),
        'diagnostics': result.diagnostics,
      }, ttl: detailsTtl);
      return DreamData(
        value: episodes,
        isStale: false,
        diagnostics: result.diagnostics,
      );
    } catch (error, stackTrace) {
      logDreamCastDiagnostic(
        'Repository episodes failed: release=${detail.release.id}, '
        'errorType=${error.runtimeType}, error=$error, stackTrace=$stackTrace, '
        'payloadSnippet="${_snippet(detail.playerPayload)}"',
      );
      final cached = await _episodesFromCache(cacheKey);
      if (cached != null) {
        logDreamCastDiagnostic(
          'Repository episodes returning stale cache after failure: '
          'release=${detail.release.id}, cachedCount=${cached.value.length}',
        );
        return DreamData(
          value: cached.value,
          isStale: true,
          diagnostics:
              'Ошибка свежего декодирования: ${error.runtimeType}: $error\n'
              'Возвращён кэш: ${cached.value.length} серий.\n'
              '${cached.diagnostics ?? ''}',
        );
      }
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
      return DreamData(value: pageData, isStale: false);
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
      return DreamData(value: pageData, isStale: true);
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
      diagnostics: cached.value['diagnostics'] as String?,
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

  Future<DreamData<ReleaseSchedule>?> _scheduleFromCache(
    String cacheKey,
  ) async {
    final cached = await _cache.getJsonMap(cacheKey);
    if (cached == null) return null;
    final daysRaw = cached.value['days'];
    if (daysRaw is! List) return null;

    final days = daysRaw
        .whereType<Map>()
        .map((item) => _scheduleDayFromJson(item.cast<String, Object?>()))
        .toList(growable: false);
    if (days.every((day) => day.releases.isEmpty)) return null;

    return DreamData(value: ReleaseSchedule(days: days), isStale: true);
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

  Map<String, Object?> _scheduleToJson(ReleaseSchedule schedule) => {
    'days': schedule.days
        .map(
          (day) => {
            'title': day.title,
            'releases': day.releases.map(_releaseToJson).toList(),
          },
        )
        .toList(),
  };

  ReleaseScheduleDay _scheduleDayFromJson(Map<String, Object?> json) {
    final releasesRaw = json['releases'];
    return ReleaseScheduleDay(
      title: json['title'] as String? ?? '',
      releases: releasesRaw is List
          ? releasesRaw
                .whereType<Map>()
                .map((item) => _releaseFromJson(item.cast<String, Object?>()))
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, Object?> _releaseToJson(DreamRelease release) => {
    'id': release.id,
    'title': release.title,
    'originalTitle': release.originalTitle,
    'url': release.url,
    'posterUrl': release.posterUrl,
    'wallUrl': release.wallUrl,
    'description': release.description,
    'status': release.status,
    'type': release.type,
    'year': release.year,
    'season': release.season,
    'genres': release.genres,
    'studio': release.studio,
    'durationMinutes': release.durationMinutes,
    'totalEpisodes': release.totalEpisodes,
    'currentEpisodes': release.currentEpisodes,
    'rating': release.rating,
    'raw': release.raw,
  };

  DreamRelease _releaseFromJson(Map<String, Object?> json) {
    return DreamRelease(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      originalTitle: json['originalTitle'] as String? ?? '',
      url: json['url'] as String? ?? '',
      posterUrl: json['posterUrl'] as String?,
      wallUrl: json['wallUrl'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String?,
      type: json['type'] as String?,
      year: (json['year'] as num?)?.toInt(),
      season: json['season'] as String?,
      genres: json['genres'] as String?,
      studio: json['studio'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      totalEpisodes: (json['totalEpisodes'] as num?)?.toInt(),
      currentEpisodes: (json['currentEpisodes'] as num?)?.toInt(),
      rating: json['rating'] as String?,
      raw: (json['raw'] as Map?)?.cast<String, Object?>() ?? const {},
    );
  }
}

String _snippet(String value, {int max = 500}) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= max) return normalized;
  return '${normalized.substring(0, max)}...';
}
