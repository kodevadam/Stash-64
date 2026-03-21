import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/game_catalog.dart';
import '../models/game.dart';
import '../models/game_console.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/cover_art_search.dart';
import '../widgets/game_image_builder.dart';
import '../widgets/touch_keyboard.dart';
import 'game_form_io.dart' if (dart.library.html) 'game_form_web.dart';
import 'game_search_io.dart' if (dart.library.html) 'game_search_web.dart';

/// Form screen for adding or editing a game.
class GameFormScreen extends StatefulWidget {
  final Game? game; // null = add mode, non-null = edit mode

  const GameFormScreen({super.key, this.game});

  @override
  State<GameFormScreen> createState() => _GameFormScreenState();
}

class _GameFormScreenState extends State<GameFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _roomController;
  late TextEditingController _storageController;
  late TextEditingController _notesController;
  late TextEditingController _yearController;

  int? _selectedConsoleId;
  String _selectedGenre = '';
  String _selectedRegion = '';
  int _minPlayers = 1;
  int _maxPlayers = 1;
  String? _coverArtPath;
  bool _isFavorite = false;

  bool get _isEditing => widget.game != null;

  static const _commonGenres = [
    'Action',
    'Action-Adventure',
    'Beat \'em Up',
    'Educational',
    'Fighting',
    'Horror',
    'Music/Rhythm',
    'Platformer',
    'Puzzle',
    'RPG',
    'Racing',
    'Run and Gun',
    'Shooter',
    'Simulation',
    'Sports',
    'Stealth',
    'Strategy',
    'Survival',
  ];

  static const _regions = [
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
    final game = widget.game;
    _titleController = TextEditingController(text: game?.title ?? '');
    _roomController = TextEditingController(text: game?.room ?? '');
    _storageController =
        TextEditingController(text: game?.storageLocation ?? '');
    _notesController = TextEditingController(text: game?.notes ?? '');
    _yearController = TextEditingController(
        text: game?.releaseYear?.toString() ?? '');
    _selectedConsoleId = game?.consoleId;
    _selectedGenre = game?.genre ?? '';
    _selectedRegion = game?.region ?? '';
    _minPlayers = game?.minPlayers ?? 1;
    _maxPlayers = game?.maxPlayers ?? 1;
    _coverArtPath = game?.coverArtPath;
    _isFavorite = game?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _roomController.dispose();
    _storageController.dispose();
    _notesController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'EDIT GAME' : 'ADD GAME'),
        toolbarHeight: 64,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () => _save(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text(
                  'SAVE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Cover art picker
            _buildCoverArtPicker(),
            const SizedBox(height: 24),

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

            // Console dropdown
            DropdownButtonFormField<int>(
              value: _selectedConsoleId,
              decoration: const InputDecoration(
                labelText: 'Console',
                prefixIcon: Icon(Icons.videogame_asset),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              dropdownColor: AppTheme.cardDark,
              isExpanded: true,
              menuMaxHeight: 400,
              items: provider.consoles.map((c) {
                return DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.name} (${c.abbreviation})'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedConsoleId = v),
              validator: (v) => v == null ? 'Select a console' : null,
            ),
            const SizedBox(height: 20),

            // Region
            _buildRegionField(),
            const SizedBox(height: 20),

            // Genre — dropdown + custom option
            _buildGenreField(provider),
            const SizedBox(height: 20),

            // Player count
            _buildPlayerCountSection(),
            const SizedBox(height: 20),

            // Room
            TouchKeyboardField(
              controller: _roomController,
              decoration: InputDecoration(
                labelText: 'Room',
                prefixIcon: const Icon(Icons.room),
                hintText: 'e.g., Living Room, Game Room',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                suffixIcon: _buildRoomSuggestions(provider),
              ),
            ),
            const SizedBox(height: 20),

            // Storage location
            TouchKeyboardField(
              controller: _storageController,
              decoration: InputDecoration(
                labelText: 'Shelf / Drawer / Box',
                prefixIcon: const Icon(Icons.inventory_2),
                hintText: 'e.g., Drawer 1, Shelf A, Box 3',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                suffixIcon: _buildStorageSuggestions(provider),
              ),
            ),
            const SizedBox(height: 20),

            // Release year
            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Release Year (optional)',
                prefixIcon: Icon(Icons.calendar_today),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final year = int.tryParse(v);
                if (year == null || year < 1950 || year > 2030) {
                  return 'Enter a valid year';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Notes
            TouchKeyboardField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // Favorite toggle
            SizedBox(
              height: 64,
              child: SwitchListTile(
                title: const Text('Favorite',
                    style: TextStyle(fontSize: 16)),
                secondary: Icon(
                  _isFavorite ? Icons.star : Icons.star_border,
                  color: _isFavorite ? AppTheme.accentGold : null,
                  size: 28,
                ),
                value: _isFavorite,
                onChanged: (v) => setState(() => _isFavorite = v),
                activeColor: AppTheme.accentGold,
              ),
            ),

            const SizedBox(height: 40),

            // Save button (large touch target)
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.primaryDark,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_isEditing ? 'UPDATE GAME' : 'ADD TO COLLECTION'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionField() {
    return DropdownButtonFormField<String>(
      value: _selectedRegion.isNotEmpty ? _selectedRegion : null,
      decoration: const InputDecoration(
        labelText: 'Region',
        prefixIcon: Icon(Icons.language),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      dropdownColor: AppTheme.cardDark,
      isExpanded: true,
      hint: const Text('Select region (optional)'),
      items: [
        const DropdownMenuItem(
          value: '',
          child: Text('Not specified'),
        ),
        ..._regions.map((r) {
          String description;
          switch (r) {
            case 'NTSC-U':
              description = '$r (North America)';
              break;
            case 'NTSC-J':
              description = '$r (Japan)';
              break;
            case 'PAL':
              description = '$r (Europe/Australia)';
              break;
            case 'NTSC-U/C':
              description = '$r (Americas)';
              break;
            case 'NTSC-K':
              description = '$r (Korea)';
              break;
            case 'PAL-A':
              description = '$r (Australia/NZ)';
              break;
            case 'PAL-B':
              description = '$r (Europe)';
              break;
            default:
              description = r;
          }
          return DropdownMenuItem(
            value: r,
            child: Text(description),
          );
        }),
      ],
      onChanged: (v) => setState(() => _selectedRegion = v ?? ''),
    );
  }

  Widget _buildCoverArtPicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showCoverArtOptions,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.textSecondary.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _coverArtPath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      buildPlatformImage(
                        path: _coverArtPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPickerPlaceholder(),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.edit, size: 22),
                            color: Colors.white,
                            onPressed: _showCoverArtOptions,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildPickerPlaceholder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _pickCoverArt,
                  icon: const Icon(Icons.folder_open, size: 22),
                  label: const Text('From File',
                      style: TextStyle(fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(
                        color: AppTheme.textSecondary.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _searchCoverArt,
                  icon: const Icon(Icons.search, size: 22),
                  label: const Text('Search Online',
                      style: TextStyle(fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentCyan,
                    side: BorderSide(
                        color: AppTheme.accentCyan.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPickerPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 56,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to add cover art',
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showCoverArtOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 64,
              child: ListTile(
                leading: const Icon(Icons.folder_open, size: 28),
                title: const Text('Choose from file',
                    style: TextStyle(fontSize: 16)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCoverArt();
                },
              ),
            ),
            SizedBox(
              height: 64,
              child: ListTile(
                leading: const Icon(Icons.search,
                    color: AppTheme.accentCyan, size: 28),
                title: const Text('Search online',
                    style: TextStyle(fontSize: 16)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24),
                onTap: () {
                  Navigator.pop(ctx);
                  _searchCoverArt();
                },
              ),
            ),
            if (_coverArtPath != null)
              SizedBox(
                height: 64,
                child: ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppTheme.errorRed, size: 28),
                  title: const Text('Remove cover art',
                      style: TextStyle(fontSize: 16)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _coverArtPath = null);
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _searchCoverArt() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a game title first')),
      );
      return;
    }

    // Find console name for better search results
    String? consoleName;
    if (_selectedConsoleId != null) {
      final provider = context.read<GameProvider>();
      final console = provider.consoles
          .where((c) => c.id == _selectedConsoleId)
          .firstOrNull;
      consoleName = console?.name;
    }

    final result = await CoverArtSearchDialog.show(
      context,
      gameTitle: title,
      consoleName: consoleName,
    );

    if (result != null) {
      setState(() => _coverArtPath = result);
    }
  }

  Widget _buildGenreField(GameProvider provider) {
    // Combine common genres with any custom ones from the DB
    final allGenres = {..._commonGenres, ...provider.genres}.toList()..sort();

    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _selectedGenre),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return allGenres;
        return allGenres.where((g) =>
            g.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (selection) {
        setState(() => _selectedGenre = selection);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Genre',
            prefixIcon: Icon(Icons.category),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
          onChanged: (v) => _selectedGenre = v,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Genre is required' : null,
        );
      },
    );
  }

  Widget _buildPlayerCountSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Min Players',
                  style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              _buildPlayerStepper(
                value: _minPlayers,
                onChanged: (v) {
                  setState(() {
                    _minPlayers = v;
                    if (_maxPlayers < _minPlayers) {
                      _maxPlayers = _minPlayers;
                    }
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Max Players',
                  style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              _buildPlayerStepper(
                value: _maxPlayers,
                min: _minPlayers,
                onChanged: (v) => setState(() => _maxPlayers = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerStepper({
    required int value,
    int min = 1,
    int max = 8,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: IconButton(
              icon: const Icon(Icons.remove, size: 28),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          SizedBox(
            width: 56,
            height: 56,
            child: IconButton(
              icon: const Icon(Icons.add, size: 28),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSuggestions(GameProvider provider) {
    if (provider.rooms.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.arrow_drop_down, size: 28),
      tooltip: 'Existing rooms',
      onSelected: (value) {
        _roomController.text = value;
      },
      itemBuilder: (context) => provider.rooms
          .map((loc) => PopupMenuItem(
                value: loc,
                height: 56,
                child: Text(loc, style: const TextStyle(fontSize: 16)),
              ))
          .toList(),
    );
  }

  Widget _buildStorageSuggestions(GameProvider provider) {
    if (provider.storageLocations.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.arrow_drop_down, size: 28),
      tooltip: 'Existing locations',
      onSelected: (value) {
        _storageController.text = value;
      },
      itemBuilder: (context) => provider.storageLocations
          .map((loc) => PopupMenuItem(
                value: loc,
                height: 56,
                child: Text(loc, style: const TextStyle(fontSize: 16)),
              ))
          .toList(),
    );
  }

  Future<void> _pickCoverArt() async {
    final path = await pickAndSaveCoverArt();
    if (path != null) {
      setState(() => _coverArtPath = path);
    }
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GameProvider>();
    final title = _titleController.text.trim();

    // Auto-fetch cover art if none set and adding a new game
    var coverPath = _coverArtPath;
    if (coverPath == null && !_isEditing && _selectedConsoleId != null) {
      final console = provider.consoles
          .where((c) => c.id == _selectedConsoleId)
          .firstOrNull;
      if (console != null) {
        // Try LibRetro boxart first
        final lrUrl =
            GameCatalog.getLibRetroBoxartUrl(title, console.abbreviation);
        if (lrUrl != null) {
          coverPath = await downloadCoverArt(lrUrl);
        }
        // Fallback to RAWG search
        if (coverPath == null) {
          try {
            final apiKey = context.read<SettingsProvider>().rawgApiKey;
            final results = await GameCatalog.search(
              title,
              consoleAbbreviation: console.abbreviation,
              rawgApiKey: apiKey,
            );
            if (results.isNotEmpty) {
              final best = results.first;
              if (best.rawgImageUrl != null) {
                coverPath = await downloadCoverArt(best.rawgImageUrl!);
              }
              if (coverPath == null && best.coverUrl != null) {
                coverPath = await downloadCoverArt(best.coverUrl!);
              }
            }
          } catch (_) {}
        }
      }
    }

    final game = Game(
      id: widget.game?.id,
      title: title,
      consoleId: _selectedConsoleId!,
      genre: _selectedGenre.trim(),
      minPlayers: _minPlayers,
      maxPlayers: _maxPlayers,
      coverArtPath: coverPath,
      room: _roomController.text.trim().isEmpty
          ? null
          : _roomController.text.trim(),
      storageLocation: _storageController.text.trim(),
      region: _selectedRegion,
      releaseYear: int.tryParse(_yearController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isFavorite: _isFavorite,
    );

    if (_isEditing) {
      await provider.updateGame(game);
    } else {
      await provider.addGame(game);
    }

    if (context.mounted) Navigator.pop(context);
  }
}
