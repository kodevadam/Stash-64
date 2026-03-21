import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/filter_state.dart';
import '../../providers/game_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mobile/mobile_game_tile.dart';
import '../game_detail_screen.dart';
import '../game_search_screen.dart';
import 'mobile_settings_screen.dart';

/// Mobile-optimized home screen with bottom navigation.
class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _currentTab = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          _BrowseTab(searchController: _searchController),
          const _AddTab(),
          const MobileSettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        backgroundColor: AppTheme.surfaceDark,
        indicatorColor: AppTheme.accentGold.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view),
            selectedIcon: Icon(Icons.grid_view, color: AppTheme.accentGold),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle, color: AppTheme.accentGold),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppTheme.accentGold),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Browse tab — search bar + filter chips + game list.
class _BrowseTab extends StatelessWidget {
  final TextEditingController searchController;
  const _BrowseTab({required this.searchController});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final filter = provider.filterState;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videogame_asset,
                color: AppTheme.accentGold, size: 22),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  AppTheme.accentGold,
                  Color(0xFFFF9500),
                  AppTheme.accentGold
                ],
              ).createShader(bounds),
              child: const Text(
                'STASH 64',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.casino, size: 22),
            tooltip: 'Random Game',
            onPressed: () => _pickRandomGame(context),
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 22),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search games...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            searchController.clear();
                            provider.setSearchQuery('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.cardDark,
                ),
                onChanged: (v) => provider.setSearchQuery(v),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

          // Active filter chips
          if (filter.hasActiveFilters)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ..._buildFilterChips(context, provider, filter),
                  const SizedBox(width: 4),
                  ActionChip(
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => provider.clearFilters(),
                  ),
                ],
              ),
            ),

          // Game count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Text(
                  '${provider.games.length} game${provider.games.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                // Sort toggle
                GestureDetector(
                  onTap: () => _showSortSheet(context),
                  child: Row(
                    children: [
                      Text(
                        _sortLabel(filter.sortField),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentGold,
                        ),
                      ),
                      Icon(
                        filter.sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 14,
                        color: AppTheme.accentGold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Game list
          Expanded(child: _buildGameList(context, provider)),
        ],
      ),
    );
  }

  String _sortLabel(SortField field) {
    switch (field) {
      case SortField.title:
        return 'Title';
      case SortField.console:
        return 'Console';
      case SortField.genre:
        return 'Genre';
      case SortField.releaseYear:
        return 'Year';
      case SortField.storageLocation:
        return 'Location';
    }
  }

  Widget _buildGameList(BuildContext context, GameProvider provider) {
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
            Icon(Icons.videogame_asset_off,
                size: 56, color: AppTheme.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              provider.filterState.hasActiveFilters
                  ? 'No games match filters'
                  : 'No games yet',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: provider.games.length,
      itemBuilder: (context, index) {
        final game = provider.games[index];
        return MobileGameTile(
          game: game,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GameDetailScreen(gameId: game.id!),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFilterChips(
      BuildContext context, GameProvider provider, FilterState filter) {
    final chips = <Widget>[];

    if (filter.consoleId != null) {
      final console = provider.consoles
          .where((c) => c.id == filter.consoleId)
          .firstOrNull;
      if (console != null) {
        chips.add(Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Chip(
            label: Text(console.abbreviation,
                style: const TextStyle(fontSize: 11)),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () =>
                provider.setFilter(filter.copyWith(clearConsole: true)),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            backgroundColor: AppTheme.accentGold.withOpacity(0.2),
            deleteIconColor: AppTheme.accentGold,
          ),
        ));
      }
    }
    if (filter.genre != null) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Chip(
          label: Text(filter.genre!, style: const TextStyle(fontSize: 11)),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: () =>
              provider.setFilter(filter.copyWith(clearGenre: true)),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          backgroundColor: AppTheme.accentGold.withOpacity(0.2),
          deleteIconColor: AppTheme.accentGold,
        ),
      ));
    }
    if (filter.favoritesOnly == true) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Chip(
          label: const Text('Favorites', style: TextStyle(fontSize: 11)),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: () =>
              provider.setFilter(filter.copyWith(clearFavorites: true)),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          backgroundColor: AppTheme.accentGold.withOpacity(0.2),
          deleteIconColor: AppTheme.accentGold,
        ),
      ));
    }

    return chips;
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameDetailScreen(gameId: game.id!),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final provider = context.watch<GameProvider>();
          final filter = provider.filterState;

          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Text('Filters',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (filter.hasActiveFilters)
                    TextButton(
                      onPressed: () => provider.clearFilters(),
                      child: const Text('Clear all'),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Consoles
              const Text('Console',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.consoles.map((c) {
                  final sel = filter.consoleId == c.id;
                  return FilterChip(
                    label: Text(c.abbreviation,
                        style: const TextStyle(fontSize: 13)),
                    selected: sel,
                    onSelected: (s) => provider.setFilter(filter.copyWith(
                      consoleId: s ? c.id : null,
                      clearConsole: !s,
                    )),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Genres
              const Text('Genre',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.genres.map((g) {
                  final sel = filter.genre == g;
                  return FilterChip(
                    label: Text(g, style: const TextStyle(fontSize: 13)),
                    selected: sel,
                    onSelected: (s) => provider.setFilter(filter.copyWith(
                      genre: s ? g : null,
                      clearGenre: !s,
                    )),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Players
              const Text('Players',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [1, 2, 3, 4].map((n) {
                  final sel = filter.playerCount == n;
                  return FilterChip(
                    label: Text('$n${n == 4 ? '+' : ''}P',
                        style: const TextStyle(fontSize: 13)),
                    selected: sel,
                    onSelected: (s) => provider.setFilter(filter.copyWith(
                      playerCount: s ? n : null,
                      clearPlayerCount: !s,
                    )),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Favorites
              FilterChip(
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16, color: AppTheme.accentGold),
                    SizedBox(width: 6),
                    Text('Favorites only', style: TextStyle(fontSize: 13)),
                  ],
                ),
                selected: filter.favoritesOnly == true,
                onSelected: (s) => provider.setFilter(filter.copyWith(
                  favoritesOnly: s ? true : null,
                  clearFavorites: !s,
                )),
              ),

              // Storage locations
              if (provider.storageLocations.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Location',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.storageLocations.map((loc) {
                    final sel = filter.storageLocation == loc;
                    return FilterChip(
                      label:
                          Text(loc, style: const TextStyle(fontSize: 13)),
                      selected: sel,
                      onSelected: (s) => provider.setFilter(filter.copyWith(
                        storageLocation: s ? loc : null,
                        clearStorageLocation: !s,
                      )),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final provider = context.read<GameProvider>();
    final filter = provider.filterState;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Sort By',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              for (final entry in {
                SortField.title: 'Title',
                SortField.console: 'Console',
                SortField.genre: 'Genre',
                SortField.releaseYear: 'Year',
                SortField.storageLocation: 'Location',
              }.entries)
                ListTile(
                  title: Text(entry.value),
                  trailing: filter.sortField == entry.key
                      ? Icon(
                          filter.sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: AppTheme.accentGold,
                          size: 20,
                        )
                      : null,
                  selected: filter.sortField == entry.key,
                  selectedTileColor: AppTheme.accentGold.withOpacity(0.1),
                  onTap: () {
                    if (filter.sortField == entry.key) {
                      provider.setFilter(filter.copyWith(
                        sortAscending: !filter.sortAscending,
                      ));
                    } else {
                      provider.setFilter(filter.copyWith(
                        sortField: entry.key,
                        sortAscending: true,
                      ));
                    }
                    Navigator.pop(ctx);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

/// Add tab — shows a quick-action page to jump into adding games.
class _AddTab extends StatelessWidget {
  const _AddTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADD GAME'),
        toolbarHeight: 48,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.library_add,
                  size: 64, color: AppTheme.accentGold.withOpacity(0.6)),
              const SizedBox(height: 16),
              const Text(
                'Add games to your collection',
                style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                '${provider.totalGameCount} games across ${provider.consoles.length} consoles',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GameSearchScreen()),
                  ),
                  icon: const Icon(Icons.search, size: 22),
                  label: const Text('Search & Add Game',
                      style: TextStyle(fontSize: 16)),
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
      ),
    );
  }
}
