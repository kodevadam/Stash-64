import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/app_theme.dart';
import 'game_image_builder.dart';

/// A touch-friendly card displaying a game's cover art, title, and key info.
class GameCard extends StatefulWidget {
  final Game game;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool autofocus;

  const GameCard({
    super.key,
    required this.game,
    required this.onTap,
    this.onFavoriteToggle,
    this.autofocus = false,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _focused = false;

  Game get game => widget.game;

  @override
  Widget build(BuildContext context) {
    // The focus ring only paints when the card actually holds focus (D-pad /
    // remote). Touch taps don't trigger focus, so touch UX is unchanged.
    final borderRadius = BorderRadius.circular(10);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      transform: Matrix4.identity()..scale(_focused ? 1.04 : 1.0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: _focused ? AppTheme.accentGold : Colors.transparent,
          width: 3,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppTheme.accentGold.withOpacity(0.4),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: InkWell(
          onTap: widget.onTap,
          autofocus: widget.autofocus,
          onFocusChange: (hasFocus) {
            if (mounted) setState(() => _focused = hasFocus);
          },
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover art area
            Expanded(
              flex: 3,
              child: _buildCoverArt(),
            ),
            // Info area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Console + region badges + player count
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (game.consoleAbbreviation != null)
                          _buildBadge(game.consoleAbbreviation!,
                              AppTheme.accentGold),
                        if (game.region.isNotEmpty)
                          _buildBadge(game.region, AppTheme.accentCyan),
                        _buildPlayerBadge(),
                      ],
                    ),
                    const Spacer(),
                    // Location (only shown if set) + favorite star
                    Row(
                      children: [
                        if (game.fullLocation.isNotEmpty) ...[
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: AppTheme.textSecondary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              game.fullLocation,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    AppTheme.textSecondary.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else
                          const Spacer(),
                        if (game.isFavorite)
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: AppTheme.accentGold,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildPlayerBadge() {
    final label = game.maxPlayers > 1
        ? '${game.maxPlayers}'
        : '1';
    final color = game.maxPlayers > 1
        ? AppTheme.accentCyan
        : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.textSecondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_esports,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverArt() {
    if (game.coverArtPath != null && game.coverArtPath!.isNotEmpty) {
      // Grid tiles max out around 400px wide on a 4K TV; decoding a 2000px
      // source bitmap to fill them is wasteful. Cap decoded width to keep
      // the GPU / heap happy on Chromecast-class hardware.
      return buildPlatformImage(
        path: game.coverArtPath!,
        fit: BoxFit.cover,
        cacheWidth: 400,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.surfaceDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videogame_asset,
              size: 44,
              color: AppTheme.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 4),
            Text(
              game.consoleAbbreviation ?? '',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
