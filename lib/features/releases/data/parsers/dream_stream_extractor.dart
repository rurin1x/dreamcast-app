import 'package:dream_cast/features/releases/domain/release.dart';

final class DreamStreamExtractor {
  const DreamStreamExtractor();

  List<DreamStream> extract(DreamEpisode episode) {
    final urls = RegExp(r'https?://[^\s]+')
        .allMatches(episode.file)
        .map((match) => match.group(0)!)
        .toList(growable: false);

    final streams = <DreamStream>[];
    for (final raw in urls) {
      final uri = Uri.tryParse(raw);
      if (uri == null || !uri.hasScheme) continue;

      final type = _typeFromPath(uri.path);
      streams.add(
        DreamStream(
          id: '${episode.id}-${streams.length + 1}',
          releaseId: episode.releaseId,
          episodeId: episode.id,
          url: uri,
          type: type,
          quality: _qualityFromUrl(uri) ?? 1080,
          expiresAt: DateTime.now().add(const Duration(hours: 2)),
        ),
      );
    }

    streams.sort((a, b) {
      if (a.type == DreamStreamType.hls && b.type != DreamStreamType.hls) {
        return -1;
      }
      if (a.type != DreamStreamType.hls && b.type == DreamStreamType.hls) {
        return 1;
      }
      return b.quality.compareTo(a.quality);
    });

    return streams;
  }

  DreamStreamType _typeFromPath(String path) {
    final clean = path.toLowerCase();
    if (clean.endsWith('.m3u8')) return DreamStreamType.hls;
    if (clean.endsWith('.mpd')) return DreamStreamType.dash;
    if (clean.endsWith('.mp4')) return DreamStreamType.mp4;
    if (clean.endsWith('.webm')) return DreamStreamType.webm;
    if (clean.endsWith('.mp3') || clean.endsWith('.aac')) {
      return DreamStreamType.audio;
    }
    return DreamStreamType.unknown;
  }

  int? _qualityFromUrl(Uri uri) {
    final source = uri.toString();
    final match = RegExp(
      r'(?<!\d)(2160|1080|720|480|360|240|144)(?:p)?(?!\d)',
    ).firstMatch(source);
    return int.tryParse(match?.group(1) ?? '');
  }
}
