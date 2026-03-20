import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../models/game_console.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/cover_art_search.dart';

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
  late TextEditingController _storageController;
  late TextEditingController _notesController;
  late TextEditingController _yearController;

  int? _selectedConsoleId;
  String _selectedGenre = '';
  int _minPlayers = 1;
  int _maxPlayers = 1;
  String? _coverArtPath;
  bool _isFavorite = false;

  bool get _isEditing => widget.game != null;

  static const _commonGenres = [
    'Action',
    'Action-Adventure',
    'Beat \'em Up',
    'Fighting',
    'Platformer',
    'Puzzle',
    'RPG',
    'Racing',
    'Shooter',
    'Simulation',
    'Sports',
    'Strategy',
  ];

  @override
  void initState() {
    super.initState();
    final game = widget.game;
    _titleController = TextEditingController(text: game?.title ?? '');
    _storageController =
        TextEditingController(text: game?.storageLocation ?? '');
    _notesController = TextEditingController(text: game?.notes ?? '');
    _yearController = TextEditingController(
        text: game?.releaseYear?.toString() ?? '');
    _selectedConsoleId = game?.consoleId;
    _selectedGenre = game?.genre ?? '';
    _minPlayers = game?.minPlayers ?? 1;
    _maxPlayers = game?.maxPlayers ?? 1;
    _coverArtPath = game?.coverArtPath;
    _isFavorite = game?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
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
        actions: [
          TextButton(
            onPressed: () => _save(context),
            child: const Text(
              'SAVE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
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
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Game Title',
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Console dropdown
            DropdownButtonFormField<int>(
              value: _selectedConsoleId,
              decoration: const InputDecoration(
                labelText: 'Console',
                prefixIcon: Icon(Icons.videogame_asset),
              ),
              dropdownColor: AppTheme.cardDark,
              items: provider.consoles.map((c) {
                return DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.name} (${c.abbreviation})'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedConsoleId = v),
              validator: (v) => v == null ? 'Select a console' : null,
            ),
            const SizedBox(height: 16),

            // Genre — dropdown + custom option
            _buildGenreField(provider),
            const SizedBox(height: 16),

            // Player count
            _buildPlayerCountSection(),
            const SizedBox(height: 16),

            // Storage location
            TextFormField(
              controller: _storageController,
              decoration: InputDecoration(
                labelText: 'Storage Location',
                prefixIcon: const Icon(Icons.inventory_2),
                hintText: 'e.g., Drawer 1, Shelf A',
                suffixIcon: _buildStorageSuggestions(provider),
              ),
            ),
            const SizedBox(height: 16),

            // Release year
            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Release Year (optional)',
                prefixIcon: Icon(Icons.calendar_today),
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
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Favorite toggle
            SwitchListTile(
              title: const Text('Favorite'),
              secondary: Icon(
                _isFavorite ? Icons.star : Icons.star_border,
                color: _isFavorite ? AppTheme.accentGold : null,
              ),
              value: _isFavorite,
              onChanged: (v) => setState(() => _isFavorite = v),
              activeColor: AppTheme.accentGold,
            ),

            const SizedBox(height: 40),

            // Save button (large touch target)
            SizedBox(
              height: AppTheme.touchTargetSize,
              child: ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.primaryDark,
                  textStyle: const TextStyle(
                    fontSize: 16,
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
          ],
        ),
      ),
    );
  }

  Widget _buildCoverArtPicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showCoverArtOptions,
          child: Container(
            height: 200,
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
                      Image.file(
                        File(_coverArtPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPickerPlaceholder(),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.edit, size: 18),
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickCoverArt,
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('From File'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(
                      color: AppTheme.textSecondary.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _searchCoverArt,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Search Online'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentCyan,
                  side: BorderSide(
                      color: AppTheme.accentCyan.withOpacity(0.5)),
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
            size: 48,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to add cover art',
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.7),
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
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Choose from file'),
              onTap: () {
                Navigator.pop(ctx);
                _pickCoverArt();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.search, color: AppTheme.accentCyan),
              title: const Text('Search online'),
              onTap: () {
                Navigator.pop(ctx);
                _searchCoverArt();
              },
            ),
            if (_coverArtPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.errorRed),
                title: const Text('Remove cover art'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _coverArtPath = null);
                },
              ),
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
              const Text('Min Players', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
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
              const Text('Max Players', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
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
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            iconSize: 24,
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value < max ? () => onChanged(value + 1) : null,
            iconSize: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSuggestions(GameProvider provider) {
    if (provider.storageLocations.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.arrow_drop_down),
      tooltip: 'Existing locations',
      onSelected: (value) {
        _storageController.text = value;
      },
      itemBuilder: (context) => provider.storageLocations
          .map((loc) => PopupMenuItem(value: loc, child: Text(loc)))
          .toList(),
    );
  }

  Future<void> _pickCoverArt() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;

    final sourcePath = result.files.first.path;
    if (sourcePath == null) return;

    // Copy to app directory
    final appDir = await getApplicationDocumentsDirectory();
    final coverDir = Directory(p.join(appDir.path, 'covers'));
    if (!await coverDir.exists()) {
      await coverDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath);
    final destPath = p.join(
        coverDir.path, '${DateTime.now().millisecondsSinceEpoch}$ext');
    await File(sourcePath).copy(destPath);

    setState(() => _coverArtPath = destPath);
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GameProvider>();
    final game = Game(
      id: widget.game?.id,
      title: _titleController.text.trim(),
      consoleId: _selectedConsoleId!,
      genre: _selectedGenre.trim(),
      minPlayers: _minPlayers,
      maxPlayers: _maxPlayers,
      coverArtPath: _coverArtPath,
      storageLocation: _storageController.text.trim(),
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
