final class DreamRelease {
  const DreamRelease({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.url,
    this.posterUrl,
    this.wallUrl,
    this.description,
    this.status,
    this.type,
    this.year,
    this.season,
    this.genres,
    this.studio,
    this.durationMinutes,
    this.totalEpisodes,
    this.currentEpisodes,
    this.rating,
    this.raw = const {},
  });

  final int id;
  final String title;
  final String originalTitle;
  final String url;
  final String? posterUrl;
  final String? wallUrl;
  final String? description;
  final String? status;
  final String? type;
  final int? year;
  final String? season;
  final String? genres;
  final String? studio;
  final int? durationMinutes;
  final int? totalEpisodes;
  final int? currentEpisodes;
  final String? rating;
  final Map<String, Object?> raw;
}

final class DreamReleaseDetail {
  const DreamReleaseDetail({
    required this.release,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.playerPayload,
    required this.playerScriptUrl,
    required this.fetchedAt,
  });

  final DreamRelease release;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String playerPayload;
  final String playerScriptUrl;
  final DateTime fetchedAt;
}

final class DreamEpisode {
  const DreamEpisode({
    required this.id,
    required this.releaseId,
    required this.ordinal,
    required this.title,
    required this.file,
    this.label,
    this.thumbnailUrl,
    this.embedUrl,
    this.vars = const {},
  });

  final String id;
  final int releaseId;
  final int ordinal;
  final String title;
  final String file;
  final String? label;
  final String? thumbnailUrl;
  final String? embedUrl;
  final Map<String, String> vars;
}

final class DreamStream {
  const DreamStream({
    required this.id,
    required this.releaseId,
    required this.episodeId,
    required this.url,
    required this.type,
    required this.quality,
    this.headers = const {},
    this.expiresAt,
  });

  final String id;
  final int releaseId;
  final String episodeId;
  final Uri url;
  final DreamStreamType type;
  final int quality;
  final Map<String, String> headers;
  final DateTime? expiresAt;
}

enum DreamStreamType { hls, dash, mp4, webm, audio, unknown }

final class ReleasePage<T> {
  const ReleasePage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
}
