import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';

/// Searches for game cover art using free, open APIs and displays results
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
      final results = await _searchCovers(query, widget.consoleName);
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
          _error = 'Search failed: $e';
        });
      }
    }
  }

  /// Search for covers using the RAWG Video Games Database API (free tier).
  /// Falls back to a simple open search if needed.
  Future<List<_CoverResult>> _searchCovers(
      String query, String? consoleName) async {
    final results = <_CoverResult>[];

    // Use RAWG API (free, no key required for basic searches)
    final searchQuery = consoleName != null
        ? '$query $consoleName'
        : query;
    final uri = Uri.parse(
        'https://api.rawg.io/api/games?key=&search=${Uri.encodeComponent(searchQuery)}&page_size=12');

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final gamesData = data['results'] as List<dynamic>? ?? [];

        for (final game in gamesData) {
          final imageUrl = game['background_image'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            results.add(_CoverResult(
              title: game['name'] as String? ?? 'Unknown',
              imageUrl: imageUrl,
              year: (game['released'] as String?)?.split('-').firstOrNull,
            ));
          }
        }
      }
    } catch (_) {
      // API may not be available; that's okay
    }

    // Fallback: try OpenLibrary for game guides/books cover art
    if (results.isEmpty) {
      final olUri = Uri.parse(
          'https://openlibrary.org/search.json?q=${Uri.encodeComponent(query)}&limit=6');

      try {
        final response = await http.get(olUri).timeout(
          const Duration(seconds: 8),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final docs = data['docs'] as List<dynamic>? ?? [];

          for (final doc in docs) {
            final coverId = doc['cover_i'] as int?;
            if (coverId != null) {
              results.add(_CoverResult(
                title: doc['title'] as String? ?? 'Unknown',
                imageUrl:
                    'https://covers.openlibrary.org/b/id/$coverId-L.jpg',
                year: doc['first_publish_year']?.toString(),
              ));
            }
          }
        }
      } catch (_) {
        // Fallback also failed
      }
    }

    return results;
  }

  Future<void> _selectCover(_CoverResult result) async {
    setState(() => _isSearching = true);

    try {
      // Download the image
      final response = await http.get(Uri.parse(result.imageUrl)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        // Save to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final coverDir = Directory(p.join(appDir.path, 'covers'));
        if (!await coverDir.exists()) {
          await coverDir.create(recursive: true);
        }

        // Determine extension from content type or URL
        String ext = '.jpg';
        final contentType = response.headers['content-type'];
        if (contentType != null) {
          if (contentType.contains('png')) ext = '.png';
          if (contentType.contains('webp')) ext = '.webp';
        }

        final destPath = p.join(coverDir.path,
            '${DateTime.now().millisecondsSinceEpoch}$ext');
        await File(destPath).writeAsBytes(response.bodyBytes);

        if (mounted) Navigator.pop(context, destPath);
      } else {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _error = 'Failed to download image';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _error = 'Download failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search Cover Art',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppTheme.touchTargetSize,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Game title...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onSubmitted: (_) => _search(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _search,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: AppTheme.primaryDark,
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
              padding: const EdgeInsets.all(12),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.accentGold),
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
                  size: 48,
                  color: AppTheme.textSecondary.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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
                      color: AppTheme.textSecondary),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.accentGold),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                result.title,
                style: const TextStyle(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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

  const _CoverResult({
    required this.title,
    required this.imageUrl,
    this.year,
  });
}
