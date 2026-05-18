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
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => PlayerFileItemDto.fromJson(_toStringKeyMap(item)))
            .where((item) => item.file.trim().isNotEmpty)
            .toList(growable: false),
      _ => const <PlayerFileItemDto>[],
    };

    if (files.isEmpty) {
      throw const ParserException('В плейлисте не найдены серии.');
    }

    return PlayerPlaylistDto(
      id: _stringValue(json['id']),
      files: files,
      poster: _stringValue(json['poster']),
      url: _stringValue(json['url']),
      cuid: _stringValue(json['cuid']),
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
      file: _stringValue(json['file']) ?? '',
      label: _stringValue(json['label']),
      title: _stringValue(json['title']),
      thumbnails: _stringValue(json['thumbnails']),
      embed: _stringValue(json['embed']),
      id: _stringValue(json['id']),
      vars: vars is Map<dynamic, dynamic> ? _toStringMap(vars) : const {},
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

Map<String, Object?> _toStringKeyMap(Map<dynamic, dynamic> source) {
  final result = <String, Object?>{};
  source.forEach((key, value) {
    result[key.toString()] = value;
  });
  return result;
}

Map<String, String> _toStringMap(Map<dynamic, dynamic> source) {
  final result = <String, String>{};
  source.forEach((key, value) {
    result[key.toString()] = value?.toString() ?? '';
  });
  return result;
}

String? _stringValue(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}
