import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_drawer.dart';
import '../widgets/game_card.dart';
import '../widgets/search_bar_widget.dart';
import 'game_detail_screen.dart';
import 'game_form_screen.dart';

/// The main browse screen — a kiosk-style grid of game cover art.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STASH 64'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.tune),
            iconSize: 28,
            tooltip: 'Filters',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            iconSize: 28,
            tooltip: 'Add Game',
            onPressed: () => _navigateToAddGame(context),
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
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...chips,
          const SizedBox(width: 8),
          ActionChip(
            label: const Text('Clear all'),
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
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: AppTheme.accentGold.withOpacity(0.2),
        deleteIconColor: AppTheme.accentGold,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videogame_asset_off,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              provider.filterState.hasActiveFilters
                  ? 'No games match your filters'
                  : 'No games in your collection yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            if (provider.filterState.hasActiveFilters)
              TextButton(
                onPressed: () => provider.clearFilters(),
                child: const Text('Clear filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _navigateToAddGame(context),
                icon: const Icon(Icons.add),
                label: const Text('Add your first game'),
              ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

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

  void _navigateToAddGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GameFormScreen(),
      ),
    );
  }
}
