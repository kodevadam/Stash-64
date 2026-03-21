import 'package:flutter/material.dart';

import '../../models/game.dart';
import '../../theme/app_theme.dart';
import '../game_image.dart';

/// A compact list tile for displaying games in mobile view.
class MobileGameTile extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  const MobileGameTile({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Cover art thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 52,
                  height: 68,
                  child: GameImage(
                    imagePath: game.coverArtPath,
                    placeholderText: game.consoleAbbreviation ?? '?',
                    width: 52,
                    height: 68,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (game.consoleAbbreviation != null) ...[
                          _badge(game.consoleAbbreviation!, AppTheme.accentGold),
                          const SizedBox(width: 6),
                        ],
                        if (game.region.isNotEmpty) ...[
                          _badge(game.region, AppTheme.accentCyan),
                          const SizedBox(width: 6),
                        ],
                        _playerBadge(),
                      ],
                    ),
                    if (game.fullLocation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 12,
                              color: AppTheme.textSecondary.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              game.fullLocation,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Trailing icons
              Column(
                children: [
                  if (game.isFavorite)
                    const Icon(Icons.star, size: 18, color: AppTheme.accentGold),
                  if (game.pricechartingPrice != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '\$${game.pricechartingPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 20, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _playerBadge() {
    final label = '${game.maxPlayers}';
    final isMulti = game.maxPlayers > 1;
    final color = isMulti ? AppTheme.accentCyan : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.textSecondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_esports, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
