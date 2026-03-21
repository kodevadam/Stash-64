import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/filter_state.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

/// A side drawer for filtering and sorting the game collection.
/// Designed with large touch targets for Raspberry Pi touchscreen use.
class FilterDrawer extends StatelessWidget {
  const FilterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final filter = provider.filterState;
    final screenWidth = MediaQuery.of(context).size.width;
    // Use 80% of screen width on small screens, max 400
    final drawerWidth = (screenWidth * 0.85).clamp(320.0, 420.0);

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        backgroundColor: AppTheme.surfaceDark,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.tune, color: AppTheme.accentGold, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'FILTERS',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 24,
                            letterSpacing: 2,
                          ),
                    ),
                    const Spacer(),
                    if (filter.hasActiveFilters)
                      SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: () => provider.clearFilters(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('CLEAR ALL',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Game count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${provider.games.length} of ${provider.totalGameCount} games',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),

              // Console filter
              _buildSectionHeader(context, 'Console'),
              _buildConsoleChips(context, provider, filter),
              const SizedBox(height: 8),
              const Divider(),

              // Genre filter
              _buildSectionHeader(context, 'Genre'),
              _buildGenreChips(context, provider, filter),
              const SizedBox(height: 8),
              const Divider(),

              // Player count filter
              _buildSectionHeader(context, 'Players'),
              _buildPlayerChips(context, provider, filter),
              const SizedBox(height: 8),
              const Divider(),

              // Storage location filter
              _buildSectionHeader(context, 'Storage Location'),
              _buildStorageChips(context, provider, filter),
              const SizedBox(height: 8),
              const Divider(),

              // Favorites toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: SizedBox(
                  height: 56,
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star,
                            size: 22,
                            color: filter.favoritesOnly == true
                                ? AppTheme.accentGold
                                : AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        const Text('Favorites Only',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    selected: filter.favoritesOnly == true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    onSelected: (selected) {
                      provider.setFilter(filter.copyWith(
                        favoritesOnly: selected ? true : null,
                        clearFavorites: !selected,
                      ));
                    },
                  ),
                ),
              ),
              const Divider(),

              // Sort options
              _buildSectionHeader(context, 'Sort By'),
              _buildSortOptions(context, provider, filter),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildConsoleChips(
      BuildContext context, GameProvider provider, FilterState filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: provider.ownedConsoles.map((console) {
          final isSelected = filter.consoleId == console.id;
          return SizedBox(
            height: 48,
            child: FilterChip(
              label: Text(console.abbreviation,
                  style: const TextStyle(fontSize: 15)),
              selected: isSelected,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              onSelected: (selected) {
                provider.setFilter(filter.copyWith(
                  consoleId: selected ? console.id : null,
                  clearConsole: !selected,
                ));
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenreChips(
      BuildContext context, GameProvider provider, FilterState filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: provider.genres.map((genre) {
          final isSelected = filter.genre == genre;
          return SizedBox(
            height: 48,
            child: FilterChip(
              label: Text(genre, style: const TextStyle(fontSize: 15)),
              selected: isSelected,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              onSelected: (selected) {
                provider.setFilter(filter.copyWith(
                  genre: selected ? genre : null,
                  clearGenre: !selected,
                ));
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlayerChips(
      BuildContext context, GameProvider provider, FilterState filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [1, 2, 3, 4].map((count) {
          final isSelected = filter.playerCount == count;
          return SizedBox(
            height: 48,
            child: FilterChip(
              label: Text(
                  '$count${count == 4 ? '+' : ''} player${count > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 15)),
              selected: isSelected,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              onSelected: (selected) {
                provider.setFilter(filter.copyWith(
                  playerCount: selected ? count : null,
                  clearPlayerCount: !selected,
                ));
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStorageChips(
      BuildContext context, GameProvider provider, FilterState filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: provider.storageLocations.map((location) {
          final isSelected = filter.storageLocation == location;
          return SizedBox(
            height: 48,
            child: FilterChip(
              label: Text(location, style: const TextStyle(fontSize: 15)),
              selected: isSelected,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              onSelected: (selected) {
                provider.setFilter(filter.copyWith(
                  storageLocation: selected ? location : null,
                  clearStorageLocation: !selected,
                ));
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortOptions(
      BuildContext context, GameProvider provider, FilterState filter) {
    final sortOptions = {
      SortField.title: 'Title',
      SortField.console: 'Console',
      SortField.genre: 'Genre',
      SortField.releaseYear: 'Year',
      SortField.storageLocation: 'Location',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: sortOptions.entries.map((entry) {
          final isSelected = filter.sortField == entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SizedBox(
              height: 60,
              child: ListTile(
                title: Text(entry.value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? AppTheme.accentGold
                          : AppTheme.textPrimary,
                    )),
                trailing: isSelected
                    ? Icon(
                        filter.sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: AppTheme.accentGold,
                        size: 24,
                      )
                    : null,
                selected: isSelected,
                selectedTileColor: AppTheme.accentGold.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                onTap: () {
                  if (isSelected) {
                    provider.setFilter(filter.copyWith(
                      sortAscending: !filter.sortAscending,
                    ));
                  } else {
                    provider.setFilter(filter.copyWith(
                      sortField: entry.key,
                      sortAscending: true,
                    ));
                  }
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
