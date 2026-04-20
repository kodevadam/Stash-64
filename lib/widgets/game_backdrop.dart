import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/backdrop.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'game_image_builder.dart';

/// Full-bleed backdrop for the game detail page.
///
/// Rendering order, back to front:
///   1. Media (image / gif / video) at BoxFit.cover
///   2. Gaussian blur (configurable sigma)
///   3. Black scrim at configurable opacity
///   4. Child content passed in by the caller
///
/// When [backdrops] is empty, falls back to a slow Ken-Burns pan on
/// [fallbackImagePath] (usually the cover art), which keeps the same
/// aesthetic with zero extra user effort.
class GameBackdrop extends StatefulWidget {
  final List<Backdrop> backdrops;
  final String? fallbackImagePath;
  final BackdropPlayback playback;
  final double blurSigma;
  final double scrimOpacity;
  final Widget child;

  const GameBackdrop({
    super.key,
    required this.backdrops,
    required this.fallbackImagePath,
    required this.playback,
    required this.blurSigma,
    required this.scrimOpacity,
    required this.child,
  });

  @override
  State<GameBackdrop> createState() => _GameBackdropState();
}

class _GameBackdropState extends State<GameBackdrop> {
  /// The order we'll present backdrops in for this page visit. Fixed at
  /// mount-time so rebuilds from setState don't re-shuffle.
  late List<Backdrop> _order;

  /// Currently-playing index into [_order].
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _order = List<Backdrop>.from(widget.backdrops);
    if (widget.playback == BackdropPlayback.shuffle && _order.length > 1) {
      _order.shuffle(Random());
    }
  }

  void _advance() {
    if (_order.length <= 1) return;
    if (mounted) {
      setState(() => _current = (_current + 1) % _order.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backdrop = _order.isEmpty ? null : _order[_current];
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: the actual media, or Ken-Burns cover-art fallback.
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: backdrop != null
                ? KeyedSubtree(
                    key: ValueKey(backdrop.id ?? backdrop.filePath),
                    child: _MediaLayer(
                      backdrop: backdrop,
                      onVideoEnded: _advance,
                    ),
                  )
                : _KenBurns(
                    key: ValueKey('fallback-${widget.fallbackImagePath}'),
                    imagePath: widget.fallbackImagePath,
                  ),
          ),
        ),

        // Layer 2: blur over everything.
        if (widget.blurSigma > 0)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blurSigma,
                sigmaY: widget.blurSigma,
              ),
              child: const SizedBox.shrink(),
            ),
          ),

        // Layer 3: scrim for text readability.
        if (widget.scrimOpacity > 0)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(widget.scrimOpacity),
            ),
          ),

        // Layer 4: caller's content.
        widget.child,
      ],
    );
  }
}

/// Displays a single backdrop file (image, gif, or video). Video gets
/// its own stateful lifecycle for the VideoPlayerController.
class _MediaLayer extends StatefulWidget {
  final Backdrop backdrop;
  final VoidCallback onVideoEnded;

  const _MediaLayer({
    required this.backdrop,
    required this.onVideoEnded,
  });

  @override
  State<_MediaLayer> createState() => _MediaLayerState();
}

class _MediaLayerState extends State<_MediaLayer> {
  VideoPlayerController? _controller;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.backdrop.mediaType == BackdropMediaType.video && !kIsWeb) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final ctl = VideoPlayerController.file(File(widget.backdrop.filePath));
    _controller = ctl;
    try {
      await ctl.initialize();
      await ctl.setLooping(true);
      await ctl.setVolume(0.0);
      await ctl.play();
      if (mounted) setState(() => _videoReady = true);
      ctl.addListener(_videoListener);
    } catch (_) {
      // Malformed / unsupported video — fall through to placeholder.
    }
  }

  void _videoListener() {
    final ctl = _controller;
    if (ctl == null) return;
    // With looping on, position never equals duration, so 'ended' only
    // matters when callers disable looping. We still notify in case.
    if (ctl.value.position >= ctl.value.duration &&
        ctl.value.duration > Duration.zero) {
      widget.onVideoEnded();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.backdrop.mediaType) {
      case BackdropMediaType.video:
        if (_videoReady && _controller != null) {
          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          );
        }
        return const ColoredBox(color: AppTheme.primaryDark);
      case BackdropMediaType.image:
      case BackdropMediaType.gif:
        // Flutter's Image widget animates GIFs natively.
        return buildPlatformImage(
          path: widget.backdrop.filePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: AppTheme.primaryDark),
        );
    }
  }
}

/// Slow pan + zoom over a single still image. Used as the zero-config
/// backdrop when no per-game media is attached.
class _KenBurns extends StatefulWidget {
  final String? imagePath;

  const _KenBurns({super.key, required this.imagePath});

  @override
  State<_KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<_KenBurns>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagePath == null || widget.imagePath!.isEmpty) {
      return const ColoredBox(color: AppTheme.primaryDark);
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;
        // Scale 1.08 -> 1.15, gentle horizontal drift.
        final scale = 1.08 + 0.07 * t;
        final dx = (t - 0.5) * 40;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(dx, 0.0)
            ..scale(scale),
          child: buildPlatformImage(
            path: widget.imagePath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: AppTheme.primaryDark),
          ),
        );
      },
    );
  }
}
