import 'dart:async';

import 'package:dream_cast/features/player/data/player_providers.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:dream_cast/features/releases/data/release_providers.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/release_title_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({required this.request, super.key});

  final PlaybackRequest request;

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  DreamStream? _currentStream;
  late PlaybackRequest _request;
  Timer? _progressTimer;
  Timer? _uiTimer;
  Timer? _controlsHideTimer;
  bool _showControls = true;
  bool _isInitializing = true;
  bool _completionHandled = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    _currentStream = _request.initialStream;
    unawaited(_enterPlayerMode());
    unawaited(_initialize(stream: _request.initialStream, resume: true));
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _uiTimer?.cancel();
    _controlsHideTimer?.cancel();
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    unawaited(_exitPlayerMode());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControlsVisibility,
          child: Stack(
            children: [
              Center(
                child: _error != null
                    ? _PlayerError(error: _error!, onRetry: _retry)
                    : _isInitializing ||
                          controller == null ||
                          !controller.value.isInitialized
                    ? const CircularProgressIndicator()
                    : AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
              ),
              if (_showControls && controller != null)
                _PlayerControls(
                  controller: controller,
                  title: _request.episode.title,
                  subtitle: displayReleaseTitle(_request.release),
                  streams: _request.streams,
                  currentStream: _currentStream,
                  onBack: () => Navigator.pop(context),
                  onTogglePlay: () {
                    _togglePlay();
                    _scheduleControlsAutoHide();
                  },
                  onSeekRelative: (offset) {
                    unawaited(_seekRelative(offset));
                    _scheduleControlsAutoHide();
                  },
                  onStreamSelected: _switchStream,
                  onSubtitleTap: () {
                    _showSubtitlePlaceholder();
                    _scheduleControlsAutoHide();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initialize({
    required DreamStream stream,
    required bool resume,
    Duration? preservePosition,
  }) async {
    setState(() {
      _isInitializing = true;
      _error = null;
      _currentStream = stream;
      _showControls = true;
      _completionHandled = false;
    });

    _uiTimer?.cancel();
    _controlsHideTimer?.cancel();
    final old = _controller;
    old?.removeListener(_onControllerChanged);
    await old?.dispose();

    try {
      final controller = VideoPlayerController.networkUrl(
        stream.url,
        httpHeaders: stream.headers,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
      _controller = controller;
      controller.addListener(_onControllerChanged);
      unawaited(
        ref
            .read(playbackRepositoryProvider)
            .saveDreamStreamSession(
              release: _request.release,
              episode: _request.episode,
              stream: stream,
            ),
      );
      await controller.initialize();

      final resumePosition =
          preservePosition ??
          (resume
              ? (await ref
                        .read(playbackRepositoryProvider)
                        .getPosition(
                          releaseId: '${_request.release.id}',
                          episodeId: _request.episode.id,
                        ))
                    ?.position
              : null);
      if (resumePosition != null &&
          resumePosition > const Duration(seconds: 5)) {
        await controller.seekTo(resumePosition);
      }
      await controller.play();
      _startProgressTimer();
      _startUiTimer();
      _scheduleControlsAutoHide();

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _switchStream(DreamStream stream) async {
    final position = _controller?.value.position;
    Navigator.pop(context);
    await _saveProgress();
    await _initialize(
      stream: stream,
      resume: false,
      preservePosition: position,
    );
  }

  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    if (controller.value.hasError) {
      setState(
        () => _error =
            controller.value.errorDescription ?? 'Ошибка воспроизведения',
      );
      return;
    }

    final duration = controller.value.duration;
    final position = controller.value.position;
    if (!_completionHandled &&
        duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 700)) {
      _completionHandled = true;
      unawaited(_handlePlaybackCompleted());
    }
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
    setState(() {});
  }

  Future<void> _seekRelative(Duration offset) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final target = controller.value.position + offset;
    await controller.seekTo(_clampDuration(target, controller.value.duration));
    if (mounted) setState(() {});
  }

  Future<void> _retry() async {
    final stream = _currentStream;
    if (stream == null) return;
    await _initialize(stream: stream, resume: true);
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_saveProgress());
    });
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final controller = _controller;
      if (!mounted || controller == null || !controller.value.isInitialized) {
        return;
      }
      setState(() {});
    });
  }

  void _toggleControlsVisibility() {
    if (_showControls) {
      _controlsHideTimer?.cancel();
      setState(() => _showControls = false);
      return;
    }
    _showControlsNow();
  }

  void _showControlsNow() {
    if (!mounted) return;
    setState(() => _showControls = true);
    _scheduleControlsAutoHide();
  }

  void _scheduleControlsAutoHide() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  Future<void> _handlePlaybackCompleted() async {
    await _saveProgress();
    if (!mounted) return;

    final nextEpisode = _nextEpisode();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Серия закончилась'),
        content: Text(
          nextEpisode == null
              ? 'Это последняя доступная серия.'
              : 'Перейти к следующей серии?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context);
            },
            child: const Text('К тайтлу'),
          ),
          if (nextEpisode != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                unawaited(_playNextEpisode(nextEpisode));
              },
              child: const Text('Следующая серия'),
            ),
        ],
      ),
    );
  }

  DreamEpisode? _nextEpisode() {
    final queue = _request.episodeQueue;
    if (queue.isEmpty) return null;
    final currentIndex = queue.indexWhere(
      (episode) => episode.id == _request.episode.id,
    );
    if (currentIndex < 0 || currentIndex + 1 >= queue.length) return null;
    return queue[currentIndex + 1];
  }

  Future<void> _playNextEpisode(DreamEpisode episode) async {
    setState(() {
      _isInitializing = true;
      _showControls = true;
      _error = null;
    });

    try {
      final data = await ref
          .read(releaseRepositoryProvider)
          .getStreams(episode);
      if (data.value.isEmpty) {
        throw StateError('Для следующей серии не найден поток.');
      }
      final preferred = _pickPreferredStream(data.value);
      _request = PlaybackRequest(
        release: _request.release,
        episode: episode,
        streams: data.value,
        initialStream: preferred,
        episodeQueue: _request.episodeQueue,
      );
      await _initialize(stream: preferred, resume: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isInitializing = false;
      });
    }
  }

  DreamStream _pickPreferredStream(List<DreamStream> streams) {
    final current = _currentStream;
    if (current == null) return streams.first;
    return streams.firstWhere(
      (stream) =>
          stream.type == current.type && stream.quality == current.quality,
      orElse: () => streams.first,
    );
  }

  Future<void> _saveProgress() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await ref
        .read(playbackRepositoryProvider)
        .saveWatchProgress(
          release: _request.release,
          episode: _request.episode,
          position: controller.value.position,
          duration: controller.value.duration,
        );
  }

  void _showSubtitlePlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Субтитры будут подключены отдельным слоем. Основа уже готова.',
        ),
      ),
    );
  }

  Future<void> _enterPlayerMode() async {
    await WakelockPlus.enable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _exitPlayerMode() async {
    await _saveProgress();
    await WakelockPlus.disable();
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  Duration _clampDuration(Duration value, Duration max) {
    if (value < Duration.zero) return Duration.zero;
    if (max > Duration.zero && value > max) return max;
    return value;
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({
    required this.controller,
    required this.title,
    required this.subtitle,
    required this.streams,
    required this.currentStream,
    required this.onBack,
    required this.onTogglePlay,
    required this.onSeekRelative,
    required this.onStreamSelected,
    required this.onSubtitleTap,
  });

  final VideoPlayerController controller;
  final String title;
  final String subtitle;
  final List<DreamStream> streams;
  final DreamStream? currentStream;
  final VoidCallback onBack;
  final VoidCallback onTogglePlay;
  final ValueChanged<Duration> onSeekRelative;
  final ValueChanged<DreamStream> onStreamSelected;
  final VoidCallback onSubtitleTap;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.72),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.78),
          ],
        ),
      ),
      child: Column(
        children: [
          _TopBar(
            title: title,
            subtitle: subtitle,
            onBack: onBack,
            onQualityTap: () => _showQualitySheet(context),
            onSubtitleTap: onSubtitleTap,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Назад на 10 секунд',
                onPressed: () => onSeekRelative(const Duration(seconds: -10)),
                icon: const Icon(Icons.replay_10),
              ),
              const SizedBox(width: 22),
              IconButton.filled(
                tooltip: value.isPlaying ? 'Пауза' : 'Воспроизвести',
                iconSize: 38,
                onPressed: onTogglePlay,
                icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 22),
              IconButton.filledTonal(
                tooltip: 'Вперёд на 10 секунд',
                onPressed: () => onSeekRelative(const Duration(seconds: 10)),
                icon: const Icon(Icons.forward_10),
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: Column(
              children: [
                VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white24,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _formatDuration(value.position),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(value.duration),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQualitySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Качество',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final stream in streams)
              ListTile(
                selected: stream == currentStream,
                onTap: () => onStreamSelected(stream),
                leading: Icon(
                  stream == currentStream
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(
                  '${_streamLabel(stream.type)} • ${stream.quality}p',
                ),
                subtitle: Text(stream.url.host),
              ),
          ],
        ),
      ),
    );
  }

  String _streamLabel(DreamStreamType type) {
    return switch (type) {
      DreamStreamType.hls => 'HLS',
      DreamStreamType.dash => 'DASH',
      DreamStreamType.mp4 => 'MP4',
      DreamStreamType.webm => 'WebM',
      DreamStreamType.audio => 'Аудио',
      DreamStreamType.unknown => 'Поток',
    };
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onQualityTap,
    required this.onSubtitleTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onQualityTap;
  final VoidCallback onSubtitleTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Назад',
            color: Colors.white,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Субтитры',
            color: Colors.white,
            onPressed: onSubtitleTap,
            icon: const Icon(Icons.subtitles_outlined),
          ),
          IconButton(
            tooltip: 'Качество',
            color: Colors.white,
            onPressed: onQualityTap,
            icon: const Icon(Icons.high_quality_outlined),
          ),
        ],
      ),
    );
  }
}

class _PlayerError extends StatelessWidget {
  const _PlayerError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 44),
          const SizedBox(height: 16),
          const Text(
            'Не удалось воспроизвести поток',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
