import 'package:dream_cast/core/errors/app_exception.dart';
import 'package:dream_cast/core/utils/url_normalizer.dart';
import 'package:dream_cast/features/releases/domain/release.dart';

final class DreamReleaseDto {
  const DreamReleaseDto({
    required this.id,
    required this.russian,
    required this.original,
    required this.url,
    this.image,
    this.wallImage,
    this.descriptionText,
    this.descriptionHtml,
    this.descriptionShort,
    this.statusName,
    this.airing,
    this.progress,
    this.type,
    this.dateIssue,
    this.season,
    this.genres,
    this.studio,
    this.duration,
    this.series,
    this.currentSeries,
    this.dubbers,
    this.timers,
    this.views,
    this.rating,
    this.raw = const {},
  });

  final int id;
  final String russian;
  final String original;
  final String url;
  final String? image;
  final String? wallImage;
  final String? descriptionText;
  final String? descriptionHtml;
  final String? descriptionShort;
  final String? statusName;
  final bool? airing;
  final String? progress;
  final String? type;
  final int? dateIssue;
  final String? season;
  final String? genres;
  final String? studio;
  final int? duration;
  final int? series;
  final int? currentSeries;
  final String? dubbers;
  final String? timers;
  final int? views;
  final String? rating;
  final Map<String, Object?> raw;

  factory DreamReleaseDto.fromJson(Map<String, Object?> json) {
    final id = (json['id'] as num?)?.toInt();
    final url = json['url'] as String?;
    if (id == null || url == null || url.trim().isEmpty) {
      throw const ParserException('Релиз содержит неполные данные.');
    }

    final wall = json['wall'];
    final description = json['description'];
    final status = json['status'];

    return DreamReleaseDto(
      id: id,
      russian: (json['russian'] as String?)?.trim() ?? '',
      original: (json['original'] as String?)?.trim() ?? '',
      url: url,
      image: json['image'] as String?,
      wallImage: wall is Map ? wall['image'] as String? : null,
      descriptionText: description is Map
          ? description['text'] as String?
          : null,
      descriptionHtml: description is Map
          ? description['html'] as String?
          : null,
      descriptionShort: description is Map
          ? description['short'] as String?
          : null,
      statusName: status is Map ? status['statusName'] as String? : null,
      airing: status is Map ? status['airing'] as bool? : null,
      progress: status is Map ? status['progress'] as String? : null,
      type: json['type'] as String?,
      dateIssue: (json['dateissue'] as num?)?.toInt(),
      season: json['season'] as String?,
      genres: json['genres'] as String?,
      studio: json['studio'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      series: (json['series'] as num?)?.toInt(),
      currentSeries: (json['currentSeries'] as num?)?.toInt(),
      dubbers: json['dubbers'] as String?,
      timers: json['timers'] as String?,
      views: (json['views'] as num?)?.toInt(),
      rating: json['rating'] as String?,
      raw: json,
    );
  }

  DreamRelease toDomain({String baseUrl = 'https://dreamerscast.com'}) {
    final title = russian.isNotEmpty ? russian : original;
    return DreamRelease(
      id: id,
      title: title,
      originalTitle: original,
      url: normalizeDreamCastUrl(url, baseUrl: baseUrl)!,
      posterUrl: normalizeDreamCastImageUrl(image),
      wallUrl: normalizeDreamCastImageUrl(wallImage),
      description: descriptionText ?? descriptionShort,
      status: statusName,
      type: type,
      year: _yearFromDateIssue(dateIssue),
      season: season,
      genres: genres,
      studio: studio,
      durationMinutes: duration,
      totalEpisodes: currentSeries,
      currentEpisodes: series,
      rating: rating,
      raw: raw,
    );
  }

  Map<String, Object?> toJson() => raw.isNotEmpty
      ? raw
      : {
          'id': id,
          'russian': russian,
          'original': original,
          'url': url,
          'image': image,
          'wall': {'image': wallImage},
          'description': {
            'text': descriptionText,
            'html': descriptionHtml,
            'short': descriptionShort,
          },
          'status': {
            'statusName': statusName,
            'airing': airing,
            'progress': progress,
          },
          'type': type,
          'dateissue': dateIssue,
          'season': season,
          'genres': genres,
          'studio': studio,
          'duration': duration,
          'series': series,
          'currentSeries': currentSeries,
          'dubbers': dubbers,
          'timers': timers,
          'views': views,
          'rating': rating,
        };

  static int? _yearFromDateIssue(int? value) {
    if (value == null) return null;
    final raw = value.toString();
    if (raw.length >= 4) return int.tryParse(raw.substring(0, 4));
    return value;
  }
}

final class DreamReleaseListDto {
  const DreamReleaseListDto({required this.releases, required this.count});

  final List<DreamReleaseDto> releases;
  final int count;

  factory DreamReleaseListDto.fromJson(Map<String, Object?> json) {
    final releasesRaw = json['releases'];
    if (releasesRaw is! List) {
      throw const ParserException('В ответе нет списка релизов.');
    }

    return DreamReleaseListDto(
      releases: releasesRaw
          .whereType<Map>()
          .map((item) => DreamReleaseDto.fromJson(item.cast<String, Object?>()))
          .toList(growable: false),
      count: (json['count'] as num?)?.toInt() ?? releasesRaw.length,
    );
  }

  Map<String, Object?> toJson() => {
    'releases': releases.map((release) => release.toJson()).toList(),
    'count': count,
  };
}
