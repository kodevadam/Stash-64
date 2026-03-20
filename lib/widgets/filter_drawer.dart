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

    return Drawer(
      backgroundColor: AppTheme.surfaceDark,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: AppTheme.accentGold),
                  const SizedBox(width: 8),
                  Text(
                    'FILTERS',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 20,
                          letterSpacing: 2,
                        ),
                  ),
                  const Spacer(),
                  if (filter.hasActiveFilters)
                    TextButton(
                      onPressed: () => provider.clearFilters(),
                      child: const Text('CLEAR ALL'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Game count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${provider.games.length} of ${provider.totalGameCount} games',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),

            // Console filter
            _buildSectionHeader(context, 'Console'),
            _buildConsoleChips(context, provider, filter),
            const Divider(),

            // Genre filter
            _buildSectionHeader(context, 'Genre'),
            _buildGenreChips(context, provider, filter),
            const Divider(),

            // Player count filter
            _buildSectionHeader(context, 'Players'),
            _buildPlayerChips(context, provider, filter),
            const Divider(),

            // Storage location filter
            _buildSectionHeader(context, 'Storage Location'),
            _buildStorageChips(context, provider, filter),
            const Divider(),

            // Favorites toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: AppTheme.touchTargetSize,
                child: FilterChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 16),
                      SizedBox(width: 6),
                      Text('Favorites Only'),
                    ],
                  ),
                  selected: filter.favoritesOnly == true,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }

  Widget _buildConsoleChips(
      BuildContext context, GameProvider provider, FilterState filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: provider.consoles.map((console) {
          final isSelected = filter.consoleId == console.id;
          return FilterChip(
            label: Text(console.abbreviation),
            selected: isSelected,
            onSelected: (selected) {
              provider.setFilter(filter.copyWith(
                consoleId: selected ? console.id : null,
                clearConsole: !selected,
              ));
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenreChips(
      BuildContext context, GameProvider provider, FilterState filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: provider.genres.map((genre) {
          final isSelected = filter.genre == genre;
          return FilterChip(
            label: Text(genre),
            selected: isSelected,
            onSelected: (selected) {
              provider.setFilter(filter.copyWith(
                genre: selected ? genre : null,
                clearGenre: !selected,
              ));
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlayerChips(
      BuildContext context, GameProvider provider, FilterState filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [1, 2, 3, 4].map((count) {
          final isSelected = filter.playerCount == count;
          return FilterChip(
            label: Text('$count${count == 4 ? '+' : ''} player${count > 1 ? 's' : ''}'),
            selected: isSelected,
            onSelected: (selected) {
              provider.setFilter(filter.copyWith(
                playerCount: selected ? count : null,
                clearPlayerCount: !selected,
              ));
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStorageChips(
      BuildContext context, GameProvider provider, FilterState filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: provider.storageLocations.map((location) {
          final isSelected = filter.storageLocation == location;
          return FilterChip(
            label: Text(location),
            selected: isSelected,
            onSelected: (selected) {
              provider.setFilter(filter.copyWith(
                storageLocation: selected ? location : null,
                clearStorageLocation: !selected,
              ));
            },
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: sortOptions.entries.map((entry) {
          final isSelected = filter.sortField == entry.key;
          return SizedBox(
            height: AppTheme.touchTargetSize,
            child: ListTile(
              dense: true,
              title: Text(entry.value),
              trailing: isSelected
                  ? Icon(
                      filter.sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: AppTheme.accentGold,
                      size: 18,
                    )
                  : null,
              selected: isSelected,
              selectedTileColor: AppTheme.accentGold.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () {
                if (isSelected) {
                  // Toggle sort direction
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
          );
        }).toList(),
      ),
    );
  }
}
