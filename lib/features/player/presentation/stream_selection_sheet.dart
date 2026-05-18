import 'package:dream_cast/features/player/data/player_providers.dart';
import 'package:dream_cast/features/player/data/stream_preference_providers.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/widgets/stale_cache_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StreamSelectionSheet extends ConsumerStatefulWidget {
  const StreamSelectionSheet({
    required this.release,
    required this.episode,
    required this.streams,
    required this.episodeQueue,
    required this.isStale,
    super.key,
  });

  final DreamRelease release;
  final DreamEpisode episode;
  final List<DreamStream> streams;
  final List<DreamEpisode> episodeQueue;
  final bool isStale;

  @override
  ConsumerState<StreamSelectionSheet> createState() =>
      _StreamSelectionSheetState();
}

class _StreamSelectionSheetState extends ConsumerState<StreamSelectionSheet> {
  bool _rememberChoice = false;

  @override
  Widget build(BuildContext context) {
    final preference = ref.watch(preferredStreamTechnologyProvider);
    final streams = sortStreamsByPreference(widget.streams, preference);
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          Text(
            widget.episode.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.isStale) const StaleCacheBanner(),
          Material(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: CheckboxListTile(
              value: _rememberChoice,
              onChanged: (value) {
                setState(() => _rememberChoice = value ?? false);
                if (value == true) _showRememberNotice(context);
              },
              secondary: const Icon(Icons.check_circle_outline),
              title: const Text('Запомнить выбор по умолчанию'),
              subtitle: Text(
                preference == PreferredStreamTechnology.none
                    ? 'Технология будет сохранена после выбора потока.'
                    : 'Сейчас по умолчанию: ${preference.label}',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          const SizedBox(height: 8),
          for (final stream in streams)
            ListTile(
              leading: Icon(
                technologyFromStreamType(stream.type) == preference
                    ? Icons.verified_outlined
                    : Icons.play_circle_outline,
              ),
              title: Text(
                '${_streamTypeLabel(stream.type)} • ${stream.quality}p',
              ),
              subtitle: Text(
                stream.url.host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _openStream(context, ref, stream),
            ),
        ],
      ),
    );
  }

  Future<void> _openStream(
    BuildContext context,
    WidgetRef ref,
    DreamStream stream,
  ) async {
    if (_rememberChoice) {
      final technology = technologyFromStreamType(stream.type);
      if (technology != PreferredStreamTechnology.none) {
        await ref
            .read(preferredStreamTechnologyProvider.notifier)
            .setTechnology(technology);
      }
    }
    if (!context.mounted) return;
    Navigator.pop(context);
    await context.push(
      '/watch',
      extra: PlaybackRequest(
        release: widget.release,
        episode: widget.episode,
        streams: widget.streams,
        initialStream: stream,
        episodeQueue: widget.episodeQueue,
      ),
    );
    invalidatePlaybackProgressForEpisodes(
      ref,
      release: widget.release,
      episodes: {widget.episode, ...widget.episodeQueue},
    );
  }

  void _showRememberNotice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: const [
            Icon(Icons.tune, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Изменить технологию потока передачи видео можно будет в настройках.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _streamTypeLabel(DreamStreamType type) {
    return switch (type) {
      DreamStreamType.hls => 'HLS',
      DreamStreamType.dash => 'DASH',
      DreamStreamType.mp4 => 'MP4',
      DreamStreamType.webm => 'WebM',
      DreamStreamType.audio => 'Аудио',
      DreamStreamType.unknown => 'Поток',
    };
  }
}
