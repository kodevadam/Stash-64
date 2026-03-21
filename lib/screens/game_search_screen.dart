import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../data/game_catalog.dart';
import '../models/game.dart';
import '../models/game_console.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/touch_keyboard.dart';
import 'game_search_io.dart' if (dart.library.html) 'game_search_web.dart';

/// Add Game screen with flow: 1) Select console, 2) Search/browse games,
/// 3) Pick game from results or type custom.
class GameSearchScreen extends StatefulWidget {
  const GameSearchScreen({super.key});

  @override
  State<GameSearchScreen> createState() => _GameSearchScreenState();
}

class _GameSearchScreenState extends State<GameSearchScreen> {
  final _searchController = TextEditingController();
  final _consoleSearchController = TextEditingController();
  List<CatalogGame> _results = [];
  bool _isSearching = false;
  String? _error;
  final Set<String> _addedTitles = {};
  final Set<String> _loadingTitles = {};

  // Step 1: console selection
  GameConsole? _selectedConsole;
  String _consoleFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    _consoleSearchController.dispose();
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
      final apiKey = context.read<SettingsProvider>().rawgApiKey;
      final results = await GameCatalog.search(
        query,
        consoleAbbreviation: _selectedConsole?.abbreviation,
        rawgApiKey: apiKey,
      );

      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
          if (results.isEmpty) {
            _error = 'No games found. Try different search terms.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('RAWG API returned')
            ? 'Game database returned an error. The free API may be '
                'temporarily unavailable — try again shortly.'
            : 'Search failed. Check your internet connection.';
        setState(() {
          _isSearching = false;
          _error = msg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _selectedConsole == null ? 'ADD GAME' : 'ADD ${_selectedConsole!.abbreviation} GAME'),
        toolbarHeight: 64,
        actions: [
          if (_selectedConsole != null)
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedConsole = null;
                    _results = [];
                    _error = null;
                    _searchController.clear();
                  });
                },
                child: const Text('CHANGE', style: TextStyle(fontSize: 15)),
              ),
            ),
        ],
      ),
      body: _selectedConsole == null
          ? _buildConsoleSelection(provider)
          : _buildGameSearch(provider),
    );
  }

  /// Step 1: Console selection grid
  Widget _buildConsoleSelection(GameProvider provider) {
    final allConsoles = provider.consoles;
    final consoles = _consoleFilter.isEmpty
        ? allConsoles
        : allConsoles.where((c) {
            final q = _consoleFilter.toLowerCase();
            return c.name.toLowerCase().contains(q) ||
                c.abbreviation.toLowerCase().contains(q);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TouchKeyboardField(
            controller: _consoleSearchController,
            decoration: InputDecoration(
              hintText: 'Filter consoles...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 24,
                    color: _consoleSearchController.text.isNotEmpty
                        ? null
                        : AppTheme.textSecondary.withOpacity(0.3),
                  ),
                  onPressed: _consoleSearchController.text.isNotEmpty
                      ? () {
                          _consoleSearchController.clear();
                          setState(() => _consoleFilter = '');
                        }
                      : null,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (v) => setState(() => _consoleFilter = v),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: consoles.length,
            itemBuilder: (context, index) {
              final console = consoles[index];
              return _buildConsoleButton(console);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConsoleButton(GameConsole console) {
    return Material(
      color: AppTheme.cardDark,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedConsole = console),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textSecondary.withOpacity(0.15),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                console.abbreviation,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: AppTheme.accentGold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                console.name,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Step 2: Game search for selected console
  Widget _buildGameSearch(GameProvider provider) {
    return Column(
      children: [
        // Search input + keyboard - flexible so keyboard doesn't overflow
        Flexible(
          flex: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TouchKeyboardField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search ${_selectedConsole!.abbreviation} games...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 24,
                            color: _searchController.text.isNotEmpty
                                ? null
                                : AppTheme.textSecondary.withOpacity(0.3),
                          ),
                          onPressed: _searchController.text.isNotEmpty
                              ? () {
                                  _searchController.clear();
                                  setState(() {});
                                }
                              : null,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 50,
                  width: 50,
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
                    child: const Icon(Icons.search, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Results
        Expanded(
          child: _buildResults(provider),
        ),

        // Custom add button at bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addCustom(provider),
              icon: const Icon(Icons.edit, size: 20),
              label: const Text('Add Custom Game',
                  style: TextStyle(fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side:
                    BorderSide(color: AppTheme.accentGold.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _addCustom(GameProvider provider) {
    // Navigate to form screen with pre-selected console
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _CustomGameForm(
          console: _selectedConsole!,
        ),
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
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
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
                  style:
                      const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
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
              Text(
                'Search for a ${_selectedConsole!.abbreviation} game to add.\n'
                'Results include games from all regions.',
                style: const TextStyle(
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
    final titleKey = catalogGame.title.toLowerCase();
    final alreadyAdded = _addedTitles.contains(titleKey);
    final isLoading = _loadingTitles.contains(titleKey);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (alreadyAdded || isLoading) ? null : () => _showAddDialog(catalogGame, provider),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Cover art thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 96,
                  child: catalogGame.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: catalogGame.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppTheme.surfaceDark,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
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
                          fontSize: 17, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (catalogGame.releaseYear != null)
                      Text(
                        '${catalogGame.releaseYear}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 15),
                      ),
                    if (catalogGame.genre != null)
                      Text(
                        catalogGame.genre!,
                        style: const TextStyle(
                            color: AppTheme.accentCyan, fontSize: 14),
                      ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.accentGold,
                  ),
                )
              else
                Icon(
                  alreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
                  color: alreadyAdded ? AppTheme.accentCyan : AppTheme.accentGold,
                  size: 36,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(
      CatalogGame catalogGame, GameProvider provider) async {
    final result = await showDialog<_AddGameResult>(
      context: context,
      builder: (ctx) => _AddGameDialog(
        catalogGame: catalogGame,
        console: _selectedConsole!,
      ),
    );

    if (result == null || !mounted) return;

    final titleKey = catalogGame.title.toLowerCase();
    setState(() => _loadingTitles.add(titleKey));

    // Download cover art if available
    String? coverPath;
    if (catalogGame.coverUrl != null) {
      coverPath = await downloadCoverArt(catalogGame.coverUrl!);
    }

    // Also try LibRetro boxart if no cover was downloaded
    if (coverPath == null && _selectedConsole != null) {
      final lrUrl = GameCatalog.getLibRetroBoxartUrl(
          catalogGame.title, _selectedConsole!.abbreviation);
      if (lrUrl != null) {
        coverPath = await downloadCoverArt(lrUrl);
      }
    }

    // Auto-fetch player count from RAWG game details
    int minPlayers = catalogGame.minPlayers ?? 1;
    int maxPlayers = catalogGame.maxPlayers ?? 1;
    if (catalogGame.rawgId != null) {
      try {
        final apiKey = context.read<SettingsProvider>().rawgApiKey;
        final playerData = await GameCatalog.fetchPlayerCount(
          catalogGame.rawgId!,
          apiKey: apiKey,
        );
        minPlayers = playerData.minPlayers;
        maxPlayers = playerData.maxPlayers;
      } catch (_) {}
    }

    // Auto-fetch PriceCharting data
    double? pcPrice = catalogGame.pricechartingPrice;
    String? pcUrl = catalogGame.pricechartingUrl;
    if (pcPrice == null) {
      try {
        final pcResult = await GameCatalog.fetchPriceCharting(
          catalogGame.title,
          _selectedConsole?.abbreviation,
        );
        pcPrice = pcResult.price;
        pcUrl = pcResult.url;
      } catch (_) {}
    }

    final game = Game(
      title: catalogGame.title,
      consoleId: _selectedConsole!.id!,
      genre: catalogGame.genre ?? 'Action',
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      coverArtPath: coverPath,
      region: result.region,
      releaseYear: catalogGame.releaseYear,
      storageLocation: '',
      pricechartingPrice: pcPrice,
      pricechartingUrl: pcUrl,
    );

    final gameId = await provider.addGame(game);

    // Mark as added so the icon updates
    setState(() {
      _loadingTitles.remove(titleKey);
      _addedTitles.add(titleKey);
    });

    // Auto-fetch RAWG screenshots in background
    if (catalogGame.rawgId != null) {
      _fetchRawgScreenshots(catalogGame.rawgId!, gameId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${catalogGame.title} added to collection!'),
          backgroundColor: AppTheme.accentGold.withOpacity(0.9),
        ),
      );
    }
  }

  /// Fetch screenshots from RAWG API and save them to the game's screenshot gallery.
  Future<void> _fetchRawgScreenshots(int rawgId, int gameId) async {
    if (gameId <= 0) return;
    try {
      final apiKey = context.read<SettingsProvider>().rawgApiKey;
      final uri = Uri.https('api.rawg.io', '/api/games/$rawgId/screenshots', {
        'key': apiKey,
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      // Collect screenshot URLs
      final urls = <String>[];
      for (final item in results) {
        if (urls.length >= 5) break;
        final imageUrl = item['image'] as String?;
        if (imageUrl != null) urls.add(imageUrl);
      }

      await downloadAndSaveScreenshots(gameId, urls);
    } catch (_) {
      // Non-fatal — screenshots are a bonus
    }
  }
}

class _AddGameResult {
  final String region;
  const _AddGameResult({required this.region});
}

class _AddGameDialog extends StatefulWidget {
  final CatalogGame catalogGame;
  final GameConsole console;

  const _AddGameDialog({
    required this.catalogGame,
    required this.console,
  });

  @override
  State<_AddGameDialog> createState() => _AddGameDialogState();
}

class _AddGameDialogState extends State<_AddGameDialog> {
  String _region = 'NTSC-U';

  static const _allRegions = [
    'NTSC-U', 'NTSC-J', 'PAL', 'NTSC-U/C', 'NTSC-K',
    'PAL-A', 'PAL-B', 'Region Free',
  ];

  @override
  void initState() {
    super.initState();
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
        style: const TextStyle(fontSize: 20),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show console
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.videogame_asset,
                    color: AppTheme.accentGold, size: 22),
                const SizedBox(width: 10),
                Text(
                  '${widget.console.name} (${widget.console.abbreviation})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Region picker
          DropdownButtonFormField<String>(
            value: _region,
            decoration: const InputDecoration(
              labelText: 'Region',
              prefixIcon: Icon(Icons.language),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                child: Text(label, style: const TextStyle(fontSize: 15)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _region = v ?? 'NTSC-U'),
          ),
        ],
      ),
      actions: [
        SizedBox(
          height: 52,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(fontSize: 16)),
          ),
        ),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(
                context, _AddGameResult(region: _region)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: const Text('ADD', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

/// Simple custom game form that pre-selects the console.
class _CustomGameForm extends StatefulWidget {
  final GameConsole console;
  const _CustomGameForm({required this.console});

  @override
  State<_CustomGameForm> createState() => _CustomGameFormState();
}

class _CustomGameFormState extends State<_CustomGameForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _storageController = TextEditingController();
  final _roomController = TextEditingController();
  String _genre = 'Action';
  String _region = 'NTSC-U';
  int _minPlayers = 1;
  int _maxPlayers = 1;

  static const _genres = [
    'Action', 'Action-Adventure', 'Beat \'em Up', 'Educational', 'Fighting',
    'Horror', 'Music/Rhythm', 'Platformer', 'Puzzle', 'RPG', 'Racing',
    'Run and Gun', 'Shooter', 'Simulation', 'Sports', 'Stealth',
    'Strategy', 'Survival',
  ];

  static const _regions = [
    'NTSC-U', 'NTSC-J', 'PAL', 'NTSC-U/C', 'NTSC-K',
    'PAL-A', 'PAL-B', 'Region Free',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _storageController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ADD ${widget.console.abbreviation} GAME'),
        toolbarHeight: 64,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Console display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.accentGold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videogame_asset,
                      color: AppTheme.accentGold, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.console.name} (${widget.console.abbreviation})',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title
            TouchKeyboardField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Game Title',
                prefixIcon: Icon(Icons.title),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),

            // Region
            DropdownButtonFormField<String>(
              value: _region,
              decoration: const InputDecoration(
                labelText: 'Region',
                prefixIcon: Icon(Icons.language),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              dropdownColor: AppTheme.cardDark,
              isExpanded: true,
              items: _regions.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r, style: const TextStyle(fontSize: 15)),
                  )).toList(),
              onChanged: (v) => setState(() => _region = v ?? 'NTSC-U'),
            ),
            const SizedBox(height: 20),

            // Genre
            DropdownButtonFormField<String>(
              value: _genre,
              decoration: const InputDecoration(
                labelText: 'Genre',
                prefixIcon: Icon(Icons.category),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              dropdownColor: AppTheme.cardDark,
              isExpanded: true,
              menuMaxHeight: 400,
              items: _genres.map((g) => DropdownMenuItem(
                    value: g,
                    child: Text(g, style: const TextStyle(fontSize: 15)),
                  )).toList(),
              onChanged: (v) => setState(() => _genre = v ?? 'Action'),
            ),
            const SizedBox(height: 20),

            // Room
            TouchKeyboardField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Room (optional)',
                prefixIcon: Icon(Icons.room),
                hintText: 'e.g., Living Room',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
            const SizedBox(height: 20),

            // Storage
            TouchKeyboardField(
              controller: _storageController,
              decoration: const InputDecoration(
                labelText: 'Shelf / Drawer / Box (optional)',
                prefixIcon: Icon(Icons.inventory_2),
                hintText: 'e.g., Shelf A',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
            const SizedBox(height: 32),

            // Save
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.primaryDark,
                  textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('ADD TO COLLECTION'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GameProvider>();
    final game = Game(
      title: _titleController.text.trim(),
      consoleId: widget.console.id!,
      genre: _genre,
      minPlayers: _minPlayers,
      maxPlayers: _maxPlayers,
      region: _region,
      room: _roomController.text.trim().isEmpty
          ? null
          : _roomController.text.trim(),
      storageLocation: _storageController.text.trim(),
    );

    await provider.addGame(game);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${game.title} added!'),
          backgroundColor: AppTheme.accentGold.withOpacity(0.9),
        ),
      );
    }
  }
}
