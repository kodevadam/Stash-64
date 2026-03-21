import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/game_image_builder.dart';
import 'game_detail_native.dart' if (dart.library.html) 'game_detail_web.dart';
import 'game_form_screen.dart';

/// Full-screen game detail page showing cover art, info, and screenshots.
class GameDetailScreen extends StatefulWidget {
  final int gameId;

  const GameDetailScreen({super.key, required this.gameId});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  Game? _game;
  List<Map<String, dynamic>> _screenshots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    final provider = context.read<GameProvider>();
    // Reload from provider's repository
    final allGames = provider.games;
    final game = allGames.where((g) => g.id == widget.gameId).firstOrNull;
    final screenshots = await loadScreenshots(widget.gameId);
    if (mounted) {
      setState(() {
        _game = game;
        _screenshots = screenshots;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentGold),
        ),
      );
    }

    if (_game == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Game not found')),
      );
    }

    final game = _game!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero cover art app bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                game.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(blurRadius: 8, color: Colors.black87),
                  ],
                ),
              ),
              background: _buildCoverArtHero(game),
            ),
            actions: [
              SizedBox(
                width: 56,
                height: 56,
                child: IconButton(
                  icon: Icon(
                    game.isFavorite ? Icons.star : Icons.star_border,
                    color: game.isFavorite ? AppTheme.accentGold : null,
                  ),
                  iconSize: 30,
                  onPressed: () async {
                    await context
                        .read<GameProvider>()
                        .toggleFavorite(game.id!);
                    _loadGame();
                  },
                ),
              ),
              SizedBox(
                width: 56,
                height: 56,
                child: IconButton(
                  icon: const Icon(Icons.edit),
                  iconSize: 30,
                  onPressed: () => _navigateToEdit(context, game),
                ),
              ),
              SizedBox(
                width: 56,
                height: 56,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 30,
                  onPressed: () => _confirmDelete(context, game),
                ),
              ),
            ],
          ),

          // Game info section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info chips row
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildInfoChip(
                        Icons.videogame_asset,
                        game.consoleAbbreviation ?? 'Unknown',
                      ),
                      _buildInfoChip(Icons.category, game.genre),
                      _buildInfoChip(Icons.people, game.playerRange),
                      if (game.releaseYear != null)
                        _buildInfoChip(
                          Icons.calendar_today,
                          '${game.releaseYear}',
                        ),
                      if (game.region.isNotEmpty)
                        _buildInfoChip(Icons.language, game.region),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Location — prominent display with room + storage
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentCyan.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          color: AppTheme.accentCyan,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOCATION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color:
                                      AppTheme.accentCyan.withOpacity(0.8),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (game.room != null &&
                                  game.room!.isNotEmpty)
                                Text(
                                  game.room!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              Text(
                                game.storageLocation.isNotEmpty
                                    ? game.storageLocation
                                    : 'Not specified',
                                style: TextStyle(
                                  fontSize: game.room != null &&
                                          game.room!.isNotEmpty
                                      ? 15
                                      : 18,
                                  fontWeight: FontWeight.w600,
                                  color: game.room != null &&
                                          game.room!.isNotEmpty
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PriceCharting value
                  if (game.pricechartingPrice != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.accentGold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            color: AppTheme.accentGold,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PRICECHARTING',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color:
                                        AppTheme.accentGold.withOpacity(0.8),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '\$${game.pricechartingPrice!.toStringAsFixed(2)} (loose)',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Console full name
                  if (game.consoleName != null) ...[
                    const SizedBox(height: 20),
                    _buildDetailRow('Console', game.consoleName!),
                  ],

                  // Notes
                  if (game.notes != null && game.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'NOTES',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary.withOpacity(0.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      game.notes!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Screenshots section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text(
                    'SCREENSHOTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary.withOpacity(0.8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate),
                    color: AppTheme.accentGold,
                    iconSize: 28,
                    tooltip: 'Add Screenshot',
                    onPressed: () => _addScreenshot(context),
                  ),
                ],
              ),
            ),
          ),

          if (_screenshots.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.textSecondary.withOpacity(0.2),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 32,
                          color: AppTheme.textSecondary.withOpacity(0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No screenshots yet',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _screenshots.length,
                  itemBuilder: (context, index) {
                    final screenshot = _screenshots[index];
                    return _buildScreenshotCard(context, screenshot, index);
                  },
                ),
              ),
            ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildCoverArtHero(Game game) {
    if (game.coverArtPath != null && game.coverArtPath!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          buildPlatformImage(
            path: game.coverArtPath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildCoverPlaceholder(game),
          ),
          // Gradient overlay for title readability
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
        ],
      );
    }
    return _buildCoverPlaceholder(game);
  }

  Widget _buildCoverPlaceholder(Game game) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceDark, AppTheme.primaryDark],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videogame_asset,
              size: 72,
              color: AppTheme.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              game.consoleAbbreviation ?? '',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.textSecondary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.accentGold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary.withOpacity(0.8),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshotCard(
      BuildContext context, Map<String, dynamic> screenshot, int index) {
    final filePath = screenshot['file_path'] as String;
    final caption = screenshot['caption'] as String?;
    final screenshotId = screenshot['id'] as int;

    return GestureDetector(
      onTap: () => _viewScreenshotFullscreen(context, index),
      onLongPress: () => _showScreenshotActions(context, screenshotId),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.cardDark,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: buildPlatformImage(
                path: filePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: AppTheme.textSecondary),
                ),
              ),
            ),
            if (caption != null && caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  caption,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _viewScreenshotFullscreen(BuildContext context, int startIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ScreenshotViewer(
          screenshots: _screenshots,
          initialIndex: startIndex,
        ),
      ),
    );
  }

  void _showScreenshotActions(BuildContext context, int screenshotId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorRed),
              title: const Text('Delete Screenshot'),
              onTap: () async {
                Navigator.pop(context);
                await deleteScreenshotById(screenshotId);
                _loadGame();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addScreenshot(BuildContext context) async {
    await addScreenshotToGame(context, widget.gameId);
    _loadGame();
  }

  void _navigateToEdit(BuildContext context, Game game) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameFormScreen(game: game),
      ),
    );
    _loadGame();
  }

  void _confirmDelete(BuildContext context, Game game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete Game'),
        content: Text('Remove "${game.title}" from your collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              context.read<GameProvider>().deleteGame(game.id!);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

/// Fullscreen screenshot viewer with swipe navigation.
class _ScreenshotViewer extends StatefulWidget {
  final List<Map<String, dynamic>> screenshots;
  final int initialIndex;

  const _ScreenshotViewer({
    required this.screenshots,
    required this.initialIndex,
  });

  @override
  State<_ScreenshotViewer> createState() => _ScreenshotViewerState();
}

class _ScreenshotViewerState extends State<_ScreenshotViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${_currentIndex + 1} / ${widget.screenshots.length}',
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.screenshots.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          final filePath = widget.screenshots[index]['file_path'] as String;
          return InteractiveViewer(
            child: Center(
              child: buildPlatformImage(
                path: filePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
