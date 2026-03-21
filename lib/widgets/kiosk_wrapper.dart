import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

/// Kiosk mode wrapper that provides:
/// - Fullscreen toggle (F11 or double-tap)
/// - Hidden mouse cursor after inactivity
/// - Attract/screensaver mode after extended idle time
class KioskWrapper extends StatefulWidget {
  final Widget child;
  final Duration cursorHideDelay;
  final Duration attractModeDelay;

  const KioskWrapper({
    super.key,
    required this.child,
    this.cursorHideDelay = const Duration(seconds: 5),
    this.attractModeDelay = const Duration(minutes: 5),
  });

  @override
  State<KioskWrapper> createState() => KioskWrapperState();

  /// Access kiosk state from anywhere in the tree.
  static KioskWrapperState? of(BuildContext context) {
    return context.findAncestorStateOfType<KioskWrapperState>();
  }
}

class KioskWrapperState extends State<KioskWrapper>
    with TickerProviderStateMixin {
  bool _cursorVisible = true;
  bool _attractModeActive = false;
  bool _isFullscreen = false;
  Timer? _cursorTimer;
  Timer? _attractTimer;
  late AnimationController _attractAnimController;

  bool get isAttractMode => _attractModeActive;
  bool get isFullscreen => _isFullscreen;

  @override
  void initState() {
    super.initState();
    _attractAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _resetTimers();
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _attractTimer?.cancel();
    _attractAnimController.dispose();
    super.dispose();
  }

  void _resetTimers() {
    // Reset cursor hide timer
    _cursorTimer?.cancel();
    if (!_cursorVisible) {
      setState(() => _cursorVisible = true);
    }
    _cursorTimer = Timer(widget.cursorHideDelay, () {
      if (mounted) setState(() => _cursorVisible = false);
    });

    // Reset attract mode timer
    _attractTimer?.cancel();
    if (_attractModeActive) {
      setState(() => _attractModeActive = false);
    }
    _attractTimer = Timer(widget.attractModeDelay, () {
      if (mounted) setState(() => _attractModeActive = true);
    });
  }

  void _onUserInteraction() {
    _resetTimers();
  }

  void toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        _onUserInteraction();
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.f11) {
            toggleFullscreen();
          }
          // Escape exits attract mode or fullscreen
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            if (_attractModeActive) {
              setState(() => _attractModeActive = false);
              _resetTimers();
            } else if (_isFullscreen) {
              toggleFullscreen();
            }
          }
        }
      },
      child: Listener(
        onPointerDown: (_) => _onUserInteraction(),
        onPointerMove: (_) => _onUserInteraction(),
        onPointerHover: (_) => _onUserInteraction(),
        child: MouseRegion(
          cursor: _cursorVisible
              ? SystemMouseCursors.basic
              : SystemMouseCursors.none,
          child: GestureDetector(
            onDoubleTap: toggleFullscreen,
            child: Stack(
              children: [
                widget.child,
                if (_attractModeActive)
                  _AttractModeOverlay(
                    animationController: _attractAnimController,
                    onDismiss: () {
                      setState(() => _attractModeActive = false);
                      _resetTimers();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The attract mode screensaver — scrolls through random game covers
/// with a subtle animation and the app title.
class _AttractModeOverlay extends StatelessWidget {
  final AnimationController animationController;
  final VoidCallback onDismiss;

  const _AttractModeOverlay({
    required this.animationController,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      onPanDown: (_) => onDismiss(),
      child: Container(
        color: AppTheme.primaryDark,
        child: Stack(
          children: [
            // Floating game covers background
            _FloatingCovers(animation: animationController),
            // Center title
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: animationController,
                    builder: (context, child) {
                      final pulse =
                          0.8 + 0.2 * sin(animationController.value * 2 * pi);
                      return Opacity(
                        opacity: pulse,
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videogame_asset,
                            color: AppTheme.accentGold, size: 52),
                        const SizedBox(width: 16),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              AppTheme.accentGold,
                              Color(0xFFFF9500),
                              AppTheme.accentGold,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'STASH 64',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 8,
                              shadows: [
                                Shadow(
                                  blurRadius: 30,
                                  color:
                                      AppTheme.accentGold.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Touch anywhere to browse',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textSecondary.withOpacity(0.7),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays floating, slowly drifting game cover placeholders
/// as background decoration for attract mode.
class _FloatingCovers extends StatelessWidget {
  final Animation<double> animation;

  const _FloatingCovers({required this.animation});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();
    final games = provider.games;

    if (games.isEmpty) return const SizedBox.shrink();

    // Pick a random subset of games to display
    final random = Random(42); // Fixed seed for consistent layout
    final displayGames = List<Game>.from(games)..shuffle(random);
    final coverCount = min(12, displayGames.length);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          children: List.generate(coverCount, (index) {
            final game = displayGames[index];
            final xBase = (index % 4) * 0.25 + 0.02;
            final yBase = (index ~/ 4) * 0.33 + 0.05;
            // Gentle floating motion
            final offset = sin(animation.value * 2 * pi + index * 0.8) * 10;

            return Positioned(
              left: MediaQuery.of(context).size.width * xBase,
              top: MediaQuery.of(context).size.height * yBase + offset,
              child: Opacity(
                opacity: 0.18,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 100,
                    height: 140,
                    child: game.coverArtPath != null &&
                            game.coverArtPath!.isNotEmpty
                        ? Image.file(
                            File(game.coverArtPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholder(game),
                          )
                        : _placeholder(game),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _placeholder(Game game) {
    return Container(
      color: AppTheme.cardDark,
      child: Center(
        child: Text(
          game.consoleAbbreviation ?? '?',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
