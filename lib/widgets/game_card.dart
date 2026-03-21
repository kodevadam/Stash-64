import 'dart:io';

import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/app_theme.dart';

/// A touch-friendly card displaying a game's cover art, title, and key info.
class GameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const GameCard({
    super.key,
    required this.game,
    required this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
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
        ? '${game.maxPlayers}P'
        : '1P';
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
            size: 12,
            color: game.maxPlayers > 1
                ? AppTheme.accentCyan
                : AppTheme.textSecondary,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: game.maxPlayers > 1
                  ? AppTheme.accentCyan
                  : AppTheme.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverArt() {
    if (game.coverArtPath != null && game.coverArtPath!.isNotEmpty) {
      final file = File(game.coverArtPath!);
      return Image.file(
        file,
        fit: BoxFit.cover,
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
