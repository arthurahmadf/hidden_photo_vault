import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../style/app_colors.dart';

class DarkVideoPlayer extends StatefulWidget {
  final String sourcePath;
  final bool active;
  final bool autoplay;
  final bool compact;
  final BoxFit fit;
  final double controlsBottomInset;

  const DarkVideoPlayer({
    super.key,
    required this.sourcePath,
    this.active = true,
    this.autoplay = false,
    this.compact = false,
    this.fit = BoxFit.contain,
    this.controlsBottomInset = 0,
  });

  @override
  State<DarkVideoPlayer> createState() => _DarkVideoPlayerState();
}

class _DarkVideoPlayerState extends State<DarkVideoPlayer> {
  late final Player _player;
  late final VideoController _videoController;
  StreamSubscription<String>? _errorSubscription;
  Timer? _controlsTimer;
  bool _controlsVisible = true;
  bool _opening = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _errorSubscription = _player.stream.error.listen((message) {
      if (!mounted || message.trim().isEmpty) return;
      setState(() {
        _opening = false;
        _error = 'This video could not be played.';
      });
    });
    unawaited(_open());
  }

  @override
  void didUpdateWidget(covariant DarkVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourcePath != widget.sourcePath) {
      unawaited(_open());
    }
    if (oldWidget.active && !widget.active) {
      unawaited(_player.pause());
      _controlsTimer?.cancel();
      _controlsVisible = true;
    }
  }

  Future<void> _open() async {
    if (mounted) {
      setState(() {
        _opening = true;
        _error = null;
      });
    }
    try {
      await _player.open(
        Media(widget.sourcePath),
        play: widget.autoplay && widget.active,
      );
      if (mounted) setState(() => _opening = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _opening = false;
        _error = 'This video format is not supported.';
      });
    }
  }

  void _showControls({bool scheduleHide = true}) {
    _controlsTimer?.cancel();
    if (mounted) setState(() => _controlsVisible = true);
    if (scheduleHide && _player.state.playing) {
      _controlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _controlsVisible = false);
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_player.state.completed) {
      await _player.seek(Duration.zero);
      await _player.play();
    } else {
      await _player.playOrPause();
    }
    _showControls(scheduleHide: _player.state.playing);
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    final errorSubscription = _errorSubscription;
    if (errorSubscription != null) {
      unawaited(errorSubscription.cancel());
    }
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _VideoError(message: _error!);
    }

    return ColoredBox(
      color: Colors.black,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_controlsVisible && _player.state.playing) {
            _controlsTimer?.cancel();
            setState(() => _controlsVisible = false);
          } else {
            _showControls();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Video(
              controller: _videoController,
              fit: widget.fit,
              fill: Colors.black,
              controls: NoVideoControls,
              pauseUponEnteringBackgroundMode: true,
              resumeUponEnteringForegroundMode: false,
            ),
            if (_opening)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              ),
            StreamBuilder<bool>(
              stream: _player.stream.buffering,
              initialData: _player.state.buffering,
              builder: (_, snapshot) {
                if (_opening || snapshot.data != true) {
                  return const SizedBox.shrink();
                }
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2,
                  ),
                );
              },
            ),
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: _ControlsOverlay(
                    player: _player,
                    compact: widget.compact,
                    bottomInset: widget.controlsBottomInset,
                    onTogglePlayback: _togglePlayback,
                    onInteraction: (scheduleHide) => _showControls(scheduleHide: scheduleHide),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  final Player player;
  final bool compact;
  final double bottomInset;
  final VoidCallback onTogglePlayback;
  final ValueChanged<bool> onInteraction;

  const _ControlsOverlay({
    required this.player,
    required this.compact,
    required this.bottomInset,
    required this.onTogglePlayback,
    required this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomInset,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              compact ? 8 : 12,
              compact ? 22 : 32,
              compact ? 8 : 12,
              compact ? 6 : 10,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: _Timeline(
              player: player,
              compact: compact,
              onTogglePlayback: onTogglePlayback,
              onInteraction: onInteraction,
            ),
          ),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  final Player player;
  final bool compact;
  final VoidCallback onTogglePlayback;
  final ValueChanged<bool> onInteraction;

  const _Timeline({
    required this.player,
    required this.compact,
    required this.onTogglePlayback,
    required this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.stream.duration,
      initialData: player.state.duration,
      builder: (_, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: player.stream.position,
          initialData: player.state.position,
          builder: (_, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final maximum = duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds;
            final value = position.inMilliseconds.clamp(0, maximum).toDouble();

            return Row(
              children: [
                StreamBuilder<bool>(
                  stream: player.stream.playing,
                  initialData: player.state.playing,
                  builder: (_, snapshot) => IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: compact ? 30 : 38,
                      height: compact ? 30 : 38,
                    ),
                    onPressed: onTogglePlayback,
                    color: Colors.white,
                    iconSize: compact ? 22 : 28,
                    icon: Icon(
                      snapshot.data == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 4 : 6),
                Text(
                  _formatDuration(position),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: compact ? 10 : 12,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white30,
                      thumbColor: Colors.white,
                      overlayColor: Colors.white12,
                      trackHeight: 2,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: compact ? 4 : 5,
                      ),
                    ),
                    child: Slider(
                      value: value,
                      max: maximum.toDouble(),
                      onChangeStart: (_) => onInteraction(false),
                      onChanged: (next) => player.seek(Duration(milliseconds: next.round())),
                      onChangeEnd: (_) => onInteraction(true),
                    ),
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: compact ? 10 : 12,
                  ),
                ),
                if (!compact)
                  StreamBuilder<double>(
                    stream: player.stream.volume,
                    initialData: player.state.volume,
                    builder: (_, volumeSnapshot) {
                      final muted = (volumeSnapshot.data ?? 100) == 0;
                      return IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          player.setVolume(muted ? 100 : 0);
                          onInteraction(true);
                        },
                        icon: Icon(
                          muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _VideoError extends StatelessWidget {
  final String message;

  const _VideoError({required this.message});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
