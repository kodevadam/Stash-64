import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../data/game_catalog.dart';
import '../providers/settings_provider.dart';
import '../screens/game_search_io.dart' if (dart.library.html) '../screens/game_search_web.dart';
import '../theme/app_theme.dart';
import 'touch_keyboard.dart';

/// Searches for game cover art using multiple free APIs and displays results
/// for the user to pick from.
class CoverArtSearchDialog extends StatefulWidget {
  final String gameTitle;
  final String? consoleName;

  const CoverArtSearchDialog({
    super.key,
    required this.gameTitle,
    this.consoleName,
  });

  /// Shows the dialog and returns the local file path of the selected cover,
  /// or null if cancelled.
  static Future<String?> show(BuildContext context,
      {required String gameTitle, String? consoleName}) {
    return showDialog<String>(
      context: context,
      builder: (_) => CoverArtSearchDialog(
        gameTitle: gameTitle,
        consoleName: consoleName,
      ),
    );
  }

  @override
  State<CoverArtSearchDialog> createState() => _CoverArtSearchDialogState();
}

class _CoverArtSearchDialogState extends State<CoverArtSearchDialog> {
  final _searchController = TextEditingController();
  List<_CoverResult> _results = [];
  bool _isSearching = false;
  bool _isDownloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.gameTitle;
    _search();
  }

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
      final results = await _searchAllSources(query, widget.consoleName);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
          if (results.isEmpty) {
            _error = 'No cover art found. Try different search terms.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _error = 'Search failed. Check your connection.';
        });
      }
    }
  }

  /// Search multiple sources in parallel for best coverage.
  Future<List<_CoverResult>> _searchAllSources(
      String query, String? consoleName) async {
    final results = <_CoverResult>[];

    // Run all searches in parallel
    final futures = <Future<List<_CoverResult>>>[
      _searchRawg(query, consoleName),
      _searchRawg(query, null), // Also search without console filter
      _searchLibreRetro(query, consoleName),
    ];

    final allResults = await Future.wait(futures);

    // Merge results, avoiding duplicates by URL
    final seenUrls = <String>{};
    for (final batch in allResults) {
      for (final result in batch) {
        if (!seenUrls.contains(result.imageUrl)) {
          seenUrls.add(result.imageUrl);
          results.add(result);
        }
      }
    }

    return results;
  }

  /// Search RAWG API for game images.
  Future<List<_CoverResult>> _searchRawg(
      String query, String? consoleName) async {
    final results = <_CoverResult>[];

    final apiKey = context.read<SettingsProvider>().rawgApiKey;
    final searchQuery =
        consoleName != null ? '$query $consoleName' : query;
    final uri = Uri.parse(
        'https://api.rawg.io/api/games?key=${Uri.encodeComponent(apiKey)}&search=${Uri.encodeComponent(searchQuery)}&page_size=15&search_precise=true');

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 12),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final gamesData = data['results'] as List<dynamic>? ?? [];

        for (final game in gamesData) {
          final imageUrl = game['background_image'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            // Get platforms for display
            final platforms = <String>[];
            for (final p in (game['platforms'] as List<dynamic>? ?? [])) {
              final name = p['platform']?['name'] as String?;
              if (name != null) platforms.add(name);
            }

            results.add(_CoverResult(
              title: game['name'] as String? ?? 'Unknown',
              imageUrl: imageUrl,
              year: (game['released'] as String?)?.split('-').firstOrNull,
              source: 'RAWG',
              platforms: platforms,
            ));
          }
        }
      }
    } catch (_) {
      // API unavailable
    }

    return results;
  }

  /// Try to find boxart from LibRetro thumbnails (GitHub-hosted, free).
  /// Uses the same source as EmuDeck for game art.
  Future<List<_CoverResult>> _searchLibreRetro(
      String query, String? consoleName) async {
    final results = <_CoverResult>[];
    if (consoleName == null) return results;

    // Try to get LibRetro URL using the centralized mapping
    final boxartUrl = GameCatalog.getLibRetroBoxartUrl(query, consoleName);
    if (boxartUrl == null) {
      // Also try with console name as abbreviation
      final system = GameCatalog.getLibRetroSystem(consoleName);
      if (system == null) return results;

      final safeName = query.replaceAll(RegExp(r'[<>:"/\\|?*&]'), '_');
      final url = 'https://thumbnails.libretro.com/'
          '${Uri.encodeComponent(system)}/Named_Boxarts/'
          '${Uri.encodeComponent(safeName)}.png';

      try {
        final response = await http.head(Uri.parse(url)).timeout(
          const Duration(seconds: 6),
        );
        if (response.statusCode == 200) {
          results.add(_CoverResult(
            title: '$query (Box Art)',
            imageUrl: url,
            source: 'LibRetro',
            platforms: [consoleName],
          ));
        }
      } catch (_) {}
      return results;
    }

    try {
      final response = await http.head(Uri.parse(boxartUrl)).timeout(
        const Duration(seconds: 6),
      );

      if (response.statusCode == 200) {
        results.add(_CoverResult(
          title: '$query (Box Art)',
          imageUrl: boxartUrl,
          source: 'LibRetro',
          platforms: [consoleName],
        ));
      }
    } catch (_) {}

    return results;
  }

  Future<void> _selectCover(_CoverResult result) async {
    setState(() => _isDownloading = true);

    try {
      final path = await downloadCoverArt(result.imageUrl);

      if (path != null) {
        if (mounted) Navigator.pop(context, path);
      } else {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _error = 'Failed to download image (${response.statusCode})';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error = 'Download failed. Check your connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Search Cover Art',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: TouchKeyboardField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Game title...',
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
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
            Flexible(
              child: _buildResults(),
            ),

            // Cancel button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppTheme.textSecondary.withOpacity(0.3)),
                  ),
                  child: const Text('CANCEL',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching || _isDownloading) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.accentGold),
              const SizedBox(height: 12),
              Text(
                _isDownloading
                    ? 'Downloading cover art...'
                    : 'Searching multiple sources...',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported,
                  size: 56,
                  color: AppTheme.textSecondary.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 15),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(_CoverResult result) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _selectCover(result),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                result.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image,
                      color: AppTheme.textSecondary, size: 32),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.accentGold),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.source.isNotEmpty)
                    Text(
                      result.source,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverResult {
  final String title;
  final String imageUrl;
  final String? year;
  final String source;
  final List<String> platforms;

  const _CoverResult({
    required this.title,
    required this.imageUrl,
    this.year,
    this.source = '',
    this.platforms = const [],
  });
}
