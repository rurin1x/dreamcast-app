import 'package:dream_cast/core/errors/app_exception.dart';
import 'package:dream_cast/core/utils/url_normalizer.dart';
import 'package:html/parser.dart' as html_parser;

final class ParsedDreamReleasePage {
  const ParsedDreamReleasePage({
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.playerPayload,
    required this.playerScriptUrl,
  });

  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String playerPayload;
  final String playerScriptUrl;
}

final class DreamCastHtmlParser {
  const DreamCastHtmlParser({this.baseUrl = 'https://dreamerscast.com'});

  final String baseUrl;

  static final _playerPayloadPatterns = [
    RegExp(r'''new\s+Playerjs\s*\(\s*["']([^"']+)["']\s*\)'''),
    RegExp(r'''Playerjs\s*\(\s*["']([^"']+)["']\s*\)'''),
  ];

  static final _playerScriptPattern = RegExp(
    r'''<script[^>]+src=["']([^"']*?/js/playerjs[^"']*)["']''',
    caseSensitive: false,
  );

  ParsedDreamReleasePage parse(String html) {
    if (html.trim().isEmpty) {
      throw const ParserException('Страница релиза пуста.');
    }

    final document = html_parser.parse(html);
    final rawHtml = document.outerHtml;
    final title =
        _normalizedText(document.querySelector('h3')?.text) ??
        _metaContent(document, 'og:title') ??
        _normalizedText(document.querySelector('title')?.text);
    final payload = _firstMatch(rawHtml, _playerPayloadPatterns);
    final scriptUrl = _scriptUrl(document, rawHtml);

    if (title == null || title.isEmpty) {
      throw const ParserException('Не удалось прочитать название релиза.');
    }
    if (payload == null || payload.isEmpty) {
      throw const ParserException('Не найден PlayerJS payload.');
    }
    if (scriptUrl == null || scriptUrl.isEmpty) {
      throw const ParserException('Не найден скрипт PlayerJS.');
    }

    return ParsedDreamReleasePage(
      title: title,
      description:
          _normalizedText(document.querySelector('.postDesc')?.text) ??
          _metaContent(document, 'description') ??
          _metaContent(document, 'og:description'),
      thumbnailUrl: normalizeDreamCastImageUrl(
        document.querySelector('.details_poster img')?.attributes['src'] ??
            _metaContent(document, 'og:image'),
      ),
      playerPayload: payload,
      playerScriptUrl: normalizeDreamCastUrl(scriptUrl, baseUrl: baseUrl)!,
    );
  }

  String? _scriptUrl(dynamic document, String rawHtml) {
    for (final script in document.querySelectorAll('script')) {
      final src = script.attributes['src'] as String?;
      if (src != null && src.contains('/js/playerjs')) {
        return src;
      }
    }
    return _playerScriptPattern.firstMatch(rawHtml)?.group(1);
  }

  static String? _firstMatch(String input, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String? _metaContent(dynamic document, String key) {
    final property = document.querySelector('meta[property="$key"]');
    final name = document.querySelector('meta[name="$key"]');
    return property?.attributes['content'] ?? name?.attributes['content'];
  }

  static String? _normalizedText(String? value) {
    final normalized = value?.trim().split(RegExp(r'\s+')).join(' ');
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
