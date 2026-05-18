import 'dart:async';
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:dream_cast/features/player/data/player_providers.dart';
import 'package:dream_cast/features/player/data/stream_preference_providers.dart';
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
  Timer? _seekFeedbackTimer;
  bool _showControls = true;
  bool _isInitializing = true;
  bool _completionHandled = false;
  bool _isClosing = false;
  bool _playerModeExited = false;
  String? _seekFeedbackText;
  int _seekFeedbackSeconds = 0;
  bool? _seekFeedbackBackward;
  Alignment _seekFeedbackAlignment = Alignment.centerRight;
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
    _seekFeedbackTimer?.cancel();
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    if (!_playerModeExited) unawaited(_exitPlayerMode(saveProgress: false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_closePlayer());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControlsVisibility,
          onDoubleTapDown: _handleDoubleTapSeek,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: _error != null
                    ? _PlayerError(error: _error!, onRetry: _retry)
                    : _isInitializing ||
                          controller == null ||
                          !controller.value.isInitialized
                    ? const _PlayerLoading()
                    : AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
              ),
              if (_seekFeedbackText != null)
                _SeekFeedback(
                  text: _seekFeedbackText!,
                  alignment: _seekFeedbackAlignment,
                ),
              if (controller != null)
                _PlayerControls(
                  visible: _showControls,
                  controller: controller,
                  title: _request.episode.title,
                  subtitle: displayReleaseTitle(_request.release),
                  streams: _request.streams,
                  currentStream: _currentStream,
                  onBack: _closePlayer,
                  onTogglePlay: () {
                    _togglePlay();
                    _scheduleControlsAutoHide();
                  },
                  onSeek: (position) {
                    unawaited(_seekTo(position));
                    _scheduleControlsAutoHide();
                  },
                  onSeekRelative: (offset) {
                    unawaited(_seekRelative(offset));
                    _scheduleControlsAutoHide();
                  },
                  onStreamSelected: _switchStream,
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

  Future<void> _seekTo(Duration position) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.seekTo(
      _clampDuration(position, controller.value.duration),
    );
    if (mounted) setState(() {});
  }

  Future<void> _seekRelative(Duration offset) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final target = controller.value.position + offset;
    await controller.seekTo(_clampDuration(target, controller.value.duration));
    if (mounted) setState(() {});
  }

  void _handleDoubleTapSeek(TapDownDetails details) {
    final width = MediaQuery.sizeOf(context).width;
    final backward = details.localPosition.dx < width / 2;
    final offset = Duration(seconds: backward ? -10 : 10);
    unawaited(_seekRelative(offset));
    _showSeekFeedback(backward);
    _scheduleControlsAutoHide();
  }

  void _showSeekFeedback(bool backward) {
    _seekFeedbackTimer?.cancel();
    setState(() {
      if (_seekFeedbackBackward == backward && _seekFeedbackText != null) {
        _seekFeedbackSeconds += 10;
      } else {
        _seekFeedbackBackward = backward;
        _seekFeedbackSeconds = 10;
      }
      _seekFeedbackText = backward
          ? '-$_seekFeedbackSeconds сек'
          : '+$_seekFeedbackSeconds сек';
      _seekFeedbackAlignment = backward
          ? Alignment.centerLeft
          : Alignment.centerRight;
    });
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _seekFeedbackText = null;
        _seekFeedbackSeconds = 0;
        _seekFeedbackBackward = null;
      });
    });
  }

  Future<void> _closePlayer() async {
    if (_isClosing) return;
    _isClosing = true;
    await _exitPlayerMode();
    if (mounted) Navigator.pop(context);
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
              unawaited(_closePlayer());
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
    final preference = ref.read(preferredStreamTechnologyProvider);
    final current = _currentStream;
    return pickPreferredStream(streams, preference, fallback: current);
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

  Future<void> _enterPlayerMode() async {
    _playerModeExited = false;
    await WakelockPlus.enable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _exitPlayerMode({bool saveProgress = true}) async {
    if (_playerModeExited) return;
    _playerModeExited = true;
    if (saveProgress) await _saveProgress();
    await WakelockPlus.disable();
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
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
    required this.visible,
    required this.controller,
    required this.title,
    required this.subtitle,
    required this.streams,
    required this.currentStream,
    required this.onBack,
    required this.onTogglePlay,
    required this.onSeek,
    required this.onSeekRelative,
    required this.onStreamSelected,
  });

  final bool visible;
  final VideoPlayerController controller;
  final String title;
  final String subtitle;
  final List<DreamStream> streams;
  final DreamStream? currentStream;
  final VoidCallback onBack;
  final VoidCallback onTogglePlay;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration> onSeekRelative;
  final ValueChanged<DreamStream> onStreamSelected;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 640 || size.height < 420;
    final horizontalPadding = compact ? 12.0 : 28.0;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.58),
                Colors.black.withValues(alpha: 0.08),
                Colors.black.withValues(alpha: 0.64),
              ],
              stops: const [0, 0.48, 1],
            ),
          ),
          child: SafeArea(
            minimum: EdgeInsets.fromLTRB(
              horizontalPadding,
              compact ? 8 : 12,
              horizontalPadding,
              compact ? 8 : 14,
            ),
            child: Column(
              children: [
                _TopBar(
                  title: title,
                  subtitle: subtitle,
                  compact: compact,
                  currentStream: currentStream,
                  onBack: onBack,
                  onQualityTap: () => _showQualitySheet(context),
                ),
                const Spacer(),
                AnimatedScale(
                  scale: visible ? 1 : 0.96,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: _CenterTransportControls(
                    isPlaying: value.isPlaying,
                    compact: compact,
                    onTogglePlay: onTogglePlay,
                    onSeekRelative: onSeekRelative,
                  ),
                ),
                const Spacer(),
                _BottomControls(
                  position: value.position,
                  duration: value.duration,
                  compact: compact,
                  accentColor: colors.primary,
                  onSeek: onSeek,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQualitySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Качество потока',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.compact,
    required this.currentStream,
    required this.onBack,
    required this.onQualityTap,
  });

  final String title;
  final String subtitle;
  final bool compact;
  final DreamStream? currentStream;
  final VoidCallback onBack;
  final VoidCallback onQualityTap;

  @override
  Widget build(BuildContext context) {
    final stream = currentStream;

    return Row(
      children: [
        _FloatingIconButton(
          tooltip: 'Назад',
          icon: Icons.arrow_back,
          onPressed: onBack,
          size: compact ? 48 : 56,
        ),
        SizedBox(width: compact ? 8 : 12),
        Expanded(
          child: _FloatingPill(
            minHeight: compact ? 48 : 56,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 18,
              vertical: compact ? 7 : 9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 15 : 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: compact ? 8 : 12),
        _FloatingTextButton(
          tooltip: 'Качество',
          label: stream == null
              ? 'Поток'
              : '${_streamLabel(stream.type)} ${stream.quality}p',
          icon: Icons.high_quality_outlined,
          compact: compact,
          onPressed: onQualityTap,
        ),
      ],
    );
  }
}

class _CenterTransportControls extends StatelessWidget {
  const _CenterTransportControls({
    required this.isPlaying,
    required this.compact,
    required this.onTogglePlay,
    required this.onSeekRelative,
  });

  final bool isPlaying;
  final bool compact;
  final VoidCallback onTogglePlay;
  final ValueChanged<Duration> onSeekRelative;

  @override
  Widget build(BuildContext context) {
    final sideSize = compact ? 58.0 : 72.0;
    final playSize = compact ? 72.0 : 88.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FloatingIconButton(
          tooltip: 'Назад на 10 секунд',
          icon: Icons.replay_10,
          onPressed: () => onSeekRelative(const Duration(seconds: -10)),
          size: sideSize,
          iconSize: compact ? 30 : 34,
        ),
        SizedBox(width: compact ? 18 : 30),
        _FloatingIconButton(
          tooltip: isPlaying ? 'Пауза' : 'Воспроизвести',
          icon: isPlaying ? Icons.pause : Icons.play_arrow,
          onPressed: onTogglePlay,
          size: playSize,
          iconSize: compact ? 42 : 50,
          accent: true,
        ),
        SizedBox(width: compact ? 18 : 30),
        _FloatingIconButton(
          tooltip: 'Вперёд на 10 секунд',
          icon: Icons.forward_10,
          onPressed: () => onSeekRelative(const Duration(seconds: 10)),
          size: sideSize,
          iconSize: compact ? 30 : 34,
        ),
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.position,
    required this.duration,
    required this.compact,
    required this.accentColor,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final bool compact;
  final Color accentColor;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = duration <= Duration.zero
        ? const Duration(seconds: 1)
        : duration;
    final max = effectiveDuration.inMilliseconds.toDouble();
    final value = position.inMilliseconds.clamp(0, max.toInt()).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _TimeLabel(_formatDuration(position)),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: compact ? 5 : 7,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: compact ? 6 : 7,
                  ),
                  overlayShape: RoundSliderOverlayShape(
                    overlayRadius: compact ? 18 : 22,
                  ),
                  activeTrackColor: accentColor,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.26),
                  thumbColor: accentColor,
                  overlayColor: accentColor.withValues(alpha: 0.18),
                ),
                child: Slider(
                  min: 0,
                  max: max,
                  value: value,
                  onChanged: (next) {
                    onSeek(Duration(milliseconds: next.round()));
                  },
                ),
              ),
            ),
            _TimeLabel(_formatDuration(duration)),
          ],
        ),
      ],
    );
  }
}

class _FloatingPill extends StatelessWidget {
  const _FloatingPill({
    required this.child,
    required this.minHeight,
    required this.padding,
  });

  final Widget child;
  final double minHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: _BackdropFilterLayer(
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _FloatingIconButton extends StatelessWidget {
  const _FloatingIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.size,
    this.iconSize = 28,
    this.accent = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: accent
              ? colors.primary.withValues(alpha: 0.86)
              : Colors.black.withValues(alpha: 0.42),
          shape: CircleBorder(
            side: BorderSide(
              color: accent
                  ? colors.primaryContainer.withValues(alpha: 0.38)
                  : Colors.white.withValues(alpha: 0.13),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Icon(
              icon,
              color: accent ? colors.onPrimary : Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingTextButton extends StatelessWidget {
  const _FloatingTextButton({
    required this.tooltip,
    required this.label,
    required this.icon,
    required this.compact,
    required this.onPressed,
  });

  final String tooltip;
  final String label;
  final IconData icon;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.42),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.13)),
        ),
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 12 : 16,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: compact ? 20 : 22),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackdropFilterLayer extends StatelessWidget {
  const _BackdropFilterLayer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // A tiny blur gives dark controls a soft Material surface feeling without
    // turning the whole player into a glassmorphism layout.
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: child,
    );
  }
}

class _SeekFeedback extends StatelessWidget {
  const _SeekFeedback({required this.text, required this.alignment});

  final String text;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 42),
        child: AnimatedScale(
          scale: 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              child: Text(
                text,
                style: TextStyle(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _PlayerLoading extends StatelessWidget {
  const _PlayerLoading();

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

class _PlayerError extends StatelessWidget {
  const _PlayerError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: colors.primary, size: 44),
          const SizedBox(height: 16),
          const Text(
            'Не удалось воспроизвести поток',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
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
  final normalized = duration < Duration.zero ? Duration.zero : duration;
  final hours = normalized.inHours;
  final minutes = normalized.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = normalized.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
