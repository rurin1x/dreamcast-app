import 'package:dream_cast/core/errors/app_exception.dart';
import 'package:dream_cast/features/releases/domain/release.dart';

final class PlayerPlaylistDto {
  const PlayerPlaylistDto({
    required this.id,
    required this.files,
    this.poster,
    this.url,
    this.cuid,
    this.raw = const {},
  });

  final String? id;
  final List<PlayerFileItemDto> files;
  final String? poster;
  final String? url;
  final String? cuid;
  final Map<String, Object?> raw;

  factory PlayerPlaylistDto.fromJson(Map<String, Object?> json) {
    final file = json['file'];
    final files = switch (file) {
      final String single when single.trim().isNotEmpty => [
        PlayerFileItemDto(file: single, title: 'Серия 1'),
      ],
      final List list =>
        list
            .whereType<Map>()
            .map(
              (item) =>
                  PlayerFileItemDto.fromJson(item.cast<String, Object?>()),
            )
            .where((item) => item.file.trim().isNotEmpty)
            .toList(growable: false),
      _ => const <PlayerFileItemDto>[],
    };

    if (files.isEmpty) {
      throw const ParserException('В плейлисте не найдены серии.');
    }

    return PlayerPlaylistDto(
      id: json['id'] as String?,
      files: files,
      poster: json['poster'] as String?,
      url: json['url'] as String?,
      cuid: json['cuid'] as String?,
      raw: json,
    );
  }

  List<DreamEpisode> toEpisodes(int releaseId) {
    return [
      for (var i = 0; i < files.length; i++)
        files[i].toEpisode(releaseId: releaseId, ordinal: i + 1),
    ];
  }
}

final class PlayerFileItemDto {
  const PlayerFileItemDto({
    required this.file,
    this.label,
    this.title,
    this.thumbnails,
    this.embed,
    this.id,
    this.vars = const {},
  });

  final String file;
  final String? label;
  final String? title;
  final String? thumbnails;
  final String? embed;
  final String? id;
  final Map<String, String> vars;

  factory PlayerFileItemDto.fromJson(Map<String, Object?> json) {
    final vars = json['vars'];
    return PlayerFileItemDto(
      file: json['file'] as String? ?? '',
      label: json['label'] as String?,
      title: json['title'] as String?,
      thumbnails: json['thumbnails'] as String?,
      embed: json['embed'] as String?,
      id: json['id'] as String?,
      vars: vars is Map
          ? vars.map((key, value) => MapEntry('$key', value?.toString() ?? ''))
          : const {},
    );
  }

  DreamEpisode toEpisode({required int releaseId, required int ordinal}) {
    final resolvedTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : label?.trim().isNotEmpty == true
        ? label!.trim()
        : 'Серия $ordinal';

    return DreamEpisode(
      id: id?.trim().isNotEmpty == true ? id!.trim() : '$releaseId-$ordinal',
      releaseId: releaseId,
      ordinal: ordinal,
      title: resolvedTitle,
      file: file,
      label: label,
      thumbnailUrl: thumbnails,
      embedUrl: embed,
      vars: vars,
    );
  }
}
