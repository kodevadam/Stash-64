import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_drawer.dart';
import '../widgets/game_card.dart';
import '../widgets/search_bar_widget.dart';
import 'game_detail_screen.dart';
import 'game_search_screen.dart';
import 'settings_screen.dart';

/// The main browse screen — a kiosk-style grid of game cover art.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videogame_asset, color: AppTheme.accentGold, size: 28),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.accentGold, Color(0xFFFF9500), AppTheme.accentGold],
              ).createShader(bounds),
              child: const Text(
                'STASH 64',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
        toolbarHeight: 64,
        leading: Builder(
          builder: (context) => SizedBox(
            width: 56,
            height: 56,
            child: IconButton(
              icon: const Icon(Icons.tune),
              iconSize: 30,
              tooltip: 'Filters',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: 56,
            height: 56,
            child: IconButton(
              icon: const Icon(Icons.casino),
              iconSize: 30,
              tooltip: 'Random Game',
              onPressed: () => _pickRandomGame(context),
            ),
          ),
          SizedBox(
            width: 56,
            height: 56,
            child: IconButton(
              icon: const Icon(Icons.add),
              iconSize: 30,
              tooltip: 'Add Game',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const GameSearchScreen()),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            height: 56,
            child: IconButton(
              icon: const Icon(Icons.settings),
              iconSize: 30,
              tooltip: 'Settings',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ),
        ],
      ),
      drawer: const FilterDrawer(),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: const SearchBarWidget(),
          ),
          // Active filter chips
          _buildActiveFilterBar(context),
          // Game grid
          Expanded(
            child: _buildGameGrid(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterBar(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final filter = provider.filterState;

    if (!filter.hasActiveFilters) return const SizedBox.shrink();

    final chips = <Widget>[];

    if (filter.consoleId != null) {
      final console = provider.consoles
          .where((c) => c.id == filter.consoleId)
          .firstOrNull;
      if (console != null) {
        chips.add(_buildFilterChip(
          context,
          console.abbreviation,
          () => provider.setFilter(filter.copyWith(clearConsole: true)),
        ));
      }
    }
    if (filter.genre != null) {
      chips.add(_buildFilterChip(
        context,
        filter.genre!,
        () => provider.setFilter(filter.copyWith(clearGenre: true)),
      ));
    }
    if (filter.playerCount != null) {
      chips.add(_buildFilterChip(
        context,
        '${filter.playerCount}P',
        () => provider.setFilter(filter.copyWith(clearPlayerCount: true)),
      ));
    }
    if (filter.storageLocation != null) {
      chips.add(_buildFilterChip(
        context,
        filter.storageLocation!,
        () => provider.setFilter(filter.copyWith(clearStorageLocation: true)),
      ));
    }
    if (filter.favoritesOnly == true) {
      chips.add(_buildFilterChip(
        context,
        'Favorites',
        () => provider.setFilter(filter.copyWith(clearFavorites: true)),
      ));
    }

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...chips,
          const SizedBox(width: 8),
          ActionChip(
            label: const Text('Clear all',
                style: TextStyle(fontSize: 14)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            onPressed: () => provider.clearFilters(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context, String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 14)),
        deleteIcon: const Icon(Icons.close, size: 20),
        onDeleted: onRemove,
        backgroundColor: AppTheme.accentGold.withOpacity(0.2),
        deleteIconColor: AppTheme.accentGold,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
    );
  }

  Widget _buildGameGrid(BuildContext context) {
    final provider = context.watch<GameProvider>();

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentGold),
      );
    }

    if (provider.games.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videogame_asset_off,
                size: 80,
                color: AppTheme.textSecondary.withOpacity(0.4),
              ),
              const SizedBox(height: 20),
              Text(
                provider.filterState.hasActiveFilters
                    ? 'No games match your filters'
                    : 'No games in your collection yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 18,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (provider.filterState.hasActiveFilters)
                SizedBox(
                  height: 52,
                  child: TextButton(
                    onPressed: () => provider.clearFilters(),
                    child: const Text('Clear filters',
                        style: TextStyle(fontSize: 16)),
                  ),
                )
              else
                SizedBox(
                  height: 60,
                  width: 280,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GameSearchScreen()),
                    ),
                    icon: const Icon(Icons.add, size: 28),
                    label: const Text('Add Game',
                        style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    // Android TV / Leanback reports directional navigation. Only auto-focus
    // the first card in that mode, so touch devices don't boot up with a
    // focus ring painted on nothing the user asked for.
    final isDirectionalNav =
        mediaQuery.navigationMode == NavigationMode.directional;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppTheme.gridCrossAxisCount(screenWidth),
        childAspectRatio: AppTheme.gridChildAspectRatio(screenWidth),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.games.length,
      itemBuilder: (context, index) {
        final game = provider.games[index];
        return GameCard(
          game: game,
          autofocus: isDirectionalNav && index == 0,
          onTap: () => _navigateToGameDetail(context, game.id!),
        );
      },
    );
  }

  void _navigateToGameDetail(BuildContext context, int gameId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameDetailScreen(gameId: gameId),
      ),
    );
  }

  void _pickRandomGame(BuildContext context) {
    final provider = context.read<GameProvider>();
    final games = provider.games;
    if (games.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No games to pick from!')),
      );
      return;
    }
    final random = Random();
    final game = games[random.nextInt(games.length)];
    _navigateToGameDetail(context, game.id!);
  }
}
