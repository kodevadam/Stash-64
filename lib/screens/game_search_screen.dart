import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../data/game_catalog.dart';
import '../models/game.dart';
import '../models/game_console.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/touch_keyboard.dart';

/// Screen for searching the game catalog and adding games to the collection.
/// Users search by title, optionally filter by console, then pick a game
/// from results. The game's data is pre-filled and can be adjusted.
class GameSearchScreen extends StatefulWidget {
  const GameSearchScreen({super.key});

  @override
  State<GameSearchScreen> createState() => _GameSearchScreenState();
}

class _GameSearchScreenState extends State<GameSearchScreen> {
  final _searchController = TextEditingController();
  List<CatalogGame> _results = [];
  bool _isSearching = false;
  String? _error;
  int? _selectedConsoleId;
  String? _selectedConsoleAbbr;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _results = [];
    });

    try {
      final results = await GameCatalog.search(
        query,
        consoleAbbreviation: _selectedConsoleAbbr,
      );

      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
          if (results.isEmpty) {
            _error =
                'No games found. Try different search terms or remove the console filter.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _error = 'Search failed. Check your internet connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FIND GAME'),
        toolbarHeight: 64,
      ),
      body: Column(
        children: [
          // Search input area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Console filter
                SizedBox(
                  height: 56,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedConsoleId,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Console (optional)',
                      prefixIcon: Icon(Icons.videogame_asset),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    dropdownColor: AppTheme.cardDark,
                    isExpanded: true,
                    menuMaxHeight: 400,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Consoles'),
                      ),
                      ...provider.consoles.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} (${c.abbreviation})'),
                        );
                      }),
                    ],
                    onChanged: (v) {
                      final console = v != null
                          ? provider.consoles
                              .where((c) => c.id == v)
                              .firstOrNull
                          : null;
                      setState(() {
                        _selectedConsoleId = v;
                        _selectedConsoleAbbr = console?.abbreviation;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Search field with keyboard
                Row(
                  children: [
                    Expanded(
                      child: TouchKeyboardField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search game title...',
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      width: 56,
                      child: ElevatedButton(
                        onPressed: _search,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: AppTheme.primaryDark,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.search, size: 28),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _buildResults(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(GameProvider provider) {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.accentGold),
            SizedBox(height: 16),
            Text('Searching game database...',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off,
                  size: 64,
                  color: AppTheme.textSecondary.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 16),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.manage_search,
                  size: 64,
                  color: AppTheme.textSecondary.withOpacity(0.4)),
              const SizedBox(height: 16),
              const Text(
                'Search for a game to add to your collection.\n'
                'Results include games from all regions.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final game = _results[index];
        return _buildResultCard(game, provider);
      },
    );
  }

  Widget _buildResultCard(CatalogGame catalogGame, GameProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAddDialog(catalogGame, provider),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover art thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 96,
                  child: catalogGame.coverUrl != null
                      ? Image.network(
                          catalogGame.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.surfaceDark,
                            child: const Icon(Icons.videogame_asset,
                                color: AppTheme.textSecondary, size: 32),
                          ),
                        )
                      : Container(
                          color: AppTheme.surfaceDark,
                          child: const Icon(Icons.videogame_asset,
                              color: AppTheme.textSecondary, size: 32),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Game info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      catalogGame.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (catalogGame.releaseYear != null)
                      Text(
                        '${catalogGame.releaseYear}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    if (catalogGame.genre != null)
                      Text(
                        catalogGame.genre!,
                        style: const TextStyle(
                          color: AppTheme.accentCyan,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Platform chips
                    if (catalogGame.platforms.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: catalogGame.platforms
                            .take(6)
                            .map((p) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentGold
                                        .withOpacity(0.2),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.accentGold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
              // Add button
              const Icon(Icons.add_circle_outline,
                  color: AppTheme.accentGold, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(
      CatalogGame catalogGame, GameProvider provider) async {
    // Determine which console to pre-select
    int? preselectedConsoleId = _selectedConsoleId;
    if (preselectedConsoleId == null && catalogGame.platforms.isNotEmpty) {
      // Try to match first platform to a console in the database
      for (final abbr in catalogGame.platforms) {
        final match = provider.consoles
            .where((c) => c.abbreviation == abbr)
            .firstOrNull;
        if (match != null) {
          preselectedConsoleId = match.id;
          break;
        }
      }
    }

    // Show dialog to pick region and console (if multiple platforms)
    final result = await showDialog<_AddGameResult>(
      context: context,
      builder: (ctx) => _AddGameDialog(
        catalogGame: catalogGame,
        consoles: provider.consoles,
        preselectedConsoleId: preselectedConsoleId,
      ),
    );

    if (result == null || !mounted) return;

    // Download cover art if available
    String? coverPath;
    if (catalogGame.coverUrl != null) {
      try {
        final response =
            await http.get(Uri.parse(catalogGame.coverUrl!)).timeout(
          const Duration(seconds: 15),
        );
        if (response.statusCode == 200) {
          final appDir = await getApplicationDocumentsDirectory();
          final coverDir = Directory(p.join(appDir.path, 'covers'));
          if (!await coverDir.exists()) {
            await coverDir.create(recursive: true);
          }
          String ext = '.jpg';
          final contentType = response.headers['content-type'];
          if (contentType != null) {
            if (contentType.contains('png')) ext = '.png';
            if (contentType.contains('webp')) ext = '.webp';
          }
          final destPath = p.join(coverDir.path,
              '${DateTime.now().millisecondsSinceEpoch}$ext');
          await File(destPath).writeAsBytes(response.bodyBytes);
          coverPath = destPath;
        }
      } catch (_) {
        // Cover download failed, continue without it
      }
    }

    // Add the game
    final game = Game(
      title: catalogGame.title,
      consoleId: result.consoleId,
      genre: catalogGame.genre ?? 'Action',
      minPlayers: catalogGame.minPlayers ?? 1,
      maxPlayers: catalogGame.maxPlayers ?? 1,
      coverArtPath: coverPath,
      region: result.region,
      releaseYear: catalogGame.releaseYear,
      storageLocation: '',
    );

    await provider.addGame(game);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${catalogGame.title} added to collection!'),
          backgroundColor: AppTheme.accentGold.withOpacity(0.9),
        ),
      );
    }
  }
}

class _AddGameResult {
  final int consoleId;
  final String region;

  const _AddGameResult({required this.consoleId, required this.region});
}

class _AddGameDialog extends StatefulWidget {
  final CatalogGame catalogGame;
  final List<GameConsole> consoles;
  final int? preselectedConsoleId;

  const _AddGameDialog({
    required this.catalogGame,
    required this.consoles,
    this.preselectedConsoleId,
  });

  @override
  State<_AddGameDialog> createState() => _AddGameDialogState();
}

class _AddGameDialogState extends State<_AddGameDialog> {
  late int? _consoleId;
  String _region = 'NTSC-U';

  static const _allRegions = [
    'NTSC-U',
    'NTSC-J',
    'PAL',
    'NTSC-U/C',
    'NTSC-K',
    'PAL-A',
    'PAL-B',
    'Region Free',
  ];

  @override
  void initState() {
    super.initState();
    _consoleId = widget.preselectedConsoleId;
    // Pre-select first inferred region
    if (widget.catalogGame.regions.isNotEmpty) {
      _region = widget.catalogGame.regions.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: Text(
        widget.catalogGame.title,
        style: const TextStyle(fontSize: 18),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Console picker
          DropdownButtonFormField<int>(
            value: _consoleId,
            decoration: const InputDecoration(
              labelText: 'Console',
              prefixIcon: Icon(Icons.videogame_asset),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            dropdownColor: AppTheme.cardDark,
            isExpanded: true,
            menuMaxHeight: 300,
            items: widget.consoles.map((c) {
              return DropdownMenuItem(
                value: c.id,
                child: Text('${c.name} (${c.abbreviation})',
                    style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _consoleId = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          // Region picker
          DropdownButtonFormField<String>(
            value: _region,
            decoration: const InputDecoration(
              labelText: 'Region',
              prefixIcon: Icon(Icons.language),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            dropdownColor: AppTheme.cardDark,
            isExpanded: true,
            items: _allRegions.map((r) {
              String label;
              switch (r) {
                case 'NTSC-U':
                  label = 'NTSC-U (North America)';
                  break;
                case 'NTSC-J':
                  label = 'NTSC-J (Japan)';
                  break;
                case 'PAL':
                  label = 'PAL (Europe/Australia)';
                  break;
                case 'NTSC-U/C':
                  label = 'NTSC-U/C (Americas)';
                  break;
                case 'NTSC-K':
                  label = 'NTSC-K (Korea)';
                  break;
                case 'PAL-A':
                  label = 'PAL-A (Australia/NZ)';
                  break;
                case 'PAL-B':
                  label = 'PAL-B (Europe)';
                  break;
                default:
                  label = r;
              }
              return DropdownMenuItem(
                value: r,
                child: Text(label, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _region = v ?? 'NTSC-U'),
          ),
        ],
      ),
      actions: [
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(fontSize: 16)),
          ),
        ),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _consoleId != null
                ? () => Navigator.pop(
                    context,
                    _AddGameResult(
                        consoleId: _consoleId!, region: _region))
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.primaryDark,
            ),
            child: const Text('ADD', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
