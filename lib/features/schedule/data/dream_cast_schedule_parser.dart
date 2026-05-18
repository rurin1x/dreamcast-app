import 'package:dream_cast/core/errors/app_exception.dart';
import 'package:dream_cast/core/utils/url_normalizer.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/schedule/domain/release_schedule.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

final class DreamCastScheduleParser {
  const DreamCastScheduleParser({this.baseUrl = 'https://dreamerscast.com'});

  final String baseUrl;

  ReleaseSchedule parse(String html) {
    if (html.trim().isEmpty) {
      throw const ParserException('Страница расписания пуста.');
    }

    final document = html_parser.parse(html);
    final container = document.querySelector('#Content') ?? document.body;
    if (container == null) {
      throw const ParserException('Не удалось прочитать расписание.');
    }

    final dayMarkers = container.querySelectorAll('.timetable');
    final fallbackMarkers = dayMarkers.isEmpty
        ? container.querySelectorAll('h4')
        : dayMarkers;

    final days = <ReleaseScheduleDay>[];
    for (final marker in fallbackMarkers) {
      final dayTitle = _normalizedText(
        marker.localName == 'h4'
            ? marker.text
            : marker.querySelector('h4')?.text,
      );
      if (dayTitle == null) continue;

      final row = _nextReleaseRowAfter(marker);
      final releases =
          row
              ?.querySelectorAll('.poster')
              .map(_parseReleaseCard)
              .whereType<DreamRelease>()
              .toList(growable: false) ??
          const <DreamRelease>[];

      days.add(ReleaseScheduleDay(title: dayTitle, releases: releases));
    }

    if (days.isEmpty) {
      throw const ParserException('Расписание не найдено.');
    }

    return ReleaseSchedule(days: days);
  }

  Element? _nextReleaseRowAfter(Element marker) {
    final parent = marker.parent;
    if (parent == null) return null;

    final children = parent.children;
    final start = children.indexOf(marker) + 1;
    if (start <= 0) return null;

    for (var index = start; index < children.length; index++) {
      final element = children[index];
      if (element.classes.contains('timetable') ||
          element.querySelector('h4') != null) {
        return null;
      }
      if (element.classes.contains('row') &&
          element.querySelector('.poster') != null) {
        return element;
      }
    }
    return null;
  }

  DreamRelease? _parseReleaseCard(Element card) {
    final link = card.querySelector('a[href*="/home/release/"]');
    final href = link?.attributes['href'];
    final url = normalizeDreamCastUrl(href, baseUrl: baseUrl);
    if (url == null) return null;

    final id = _releaseIdFromUrl(url);
    if (id == null) return null;

    final russian = _normalizedText(
      card.querySelector('.s-title-russian')?.text,
    );
    final original = _normalizedText(
      card.querySelector('.s-title-original')?.text,
    );
    final title = russian?.isNotEmpty == true ? russian! : original ?? '';
    if (title.isEmpty) return null;

    final metadata = _metadata(card);
    final episodes = metadata['Эпизодов'];
    final currentEpisodes = _currentEpisodes(episodes);
    final totalEpisodes = _totalEpisodes(episodes);

    return DreamRelease(
      id: id,
      title: title,
      originalTitle: original ?? '',
      url: url,
      posterUrl: normalizeDreamCastImageUrl(_posterUrl(card)),
      type: metadata['Тип'],
      year: int.tryParse(metadata['Год'] ?? ''),
      season: metadata['Сезон'],
      studio: metadata['Студия'],
      genres: metadata['Жанр'],
      currentEpisodes: currentEpisodes,
      totalEpisodes: totalEpisodes,
      rating: _normalizedText(card.querySelector('.poster-rating')?.text),
      raw: {'source': 'schedule', 'scheduleMetadata': metadata},
    );
  }

  Map<String, String> _metadata(Element card) {
    final result = <String, String>{};
    for (final row in card.querySelectorAll('.poster_info')) {
      final label = _normalizedText(
        row.querySelector('.s-item')?.text,
      )?.replaceAll(':', '').trim();
      final value = _normalizedText(row.querySelector('span')?.text);
      if (label != null && label.isNotEmpty && value != null) {
        result[label] = value;
      }
    }
    return result;
  }

  String? _posterUrl(Element card) {
    final style = card.querySelector('.poster-img')?.attributes['style'];
    if (style == null) return null;
    return RegExp(
      r'''url\(['"]?([^'")]+)['"]?\)''',
    ).firstMatch(style)?.group(1);
  }

  int? _releaseIdFromUrl(String url) {
    final match = RegExp(r'/release/(\d+)').firstMatch(url);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  int? _currentEpisodes(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^\s*(\d+)').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  int? _totalEpisodes(String? value) {
    if (value == null) return null;
    final match = RegExp(r'из\s+(\d+)').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  String? _normalizedText(String? value) {
    final normalized = value?.trim().split(RegExp(r'\s+')).join(' ');
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
