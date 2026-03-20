import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_console.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

/// Admin screen for managing consoles (add, edit, delete with color picker).
class ConsoleManagementScreen extends StatelessWidget {
  const ConsoleManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CONSOLES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            iconSize: 28,
            tooltip: 'Add Console',
            onPressed: () => _showConsoleDialog(context),
          ),
        ],
      ),
      body: provider.consoles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videogame_asset_off,
                      size: 64,
                      color: AppTheme.textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('No consoles yet'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showConsoleDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Console'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.consoles.length,
              itemBuilder: (context, index) {
                final console = provider.consoles[index];
                return _buildConsoleCard(context, console, provider);
              },
            ),
    );
  }

  Widget _buildConsoleCard(
      BuildContext context, GameConsole console, GameProvider provider) {
    final color = Color(console.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              console.abbreviation,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ),
        title: Text(console.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(console.abbreviation,
            style: const TextStyle(color: AppTheme.textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showConsoleDialog(context, console: console),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.errorRed),
              onPressed: () => _confirmDelete(context, console, provider),
            ),
          ],
        ),
        onTap: () => _showConsoleDialog(context, console: console),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, GameConsole console, GameProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete Console'),
        content: Text(
            'Remove "${console.name}"? Games assigned to this console will '
            'lose their console association.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteConsole(console.id!);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showConsoleDialog(BuildContext context, {GameConsole? console}) {
    showDialog(
      context: context,
      builder: (ctx) => _ConsoleFormDialog(console: console),
    );
  }
}

class _ConsoleFormDialog extends StatefulWidget {
  final GameConsole? console;

  const _ConsoleFormDialog({this.console});

  @override
  State<_ConsoleFormDialog> createState() => _ConsoleFormDialogState();
}

class _ConsoleFormDialogState extends State<_ConsoleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _abbreviationController;
  late Color _selectedColor;

  bool get _isEditing => widget.console != null;

  static const _presetColors = [
    Color(0xFF1A237E), // Deep blue
    Color(0xFF0D47A1), // Blue
    Color(0xFF006064), // Teal
    Color(0xFF2E7D32), // Green
    Color(0xFF33691E), // Light green
    Color(0xFFE65100), // Orange
    Color(0xFFBF360C), // Deep orange
    Color(0xFFB71C1C), // Red
    Color(0xFFC62828), // Bright red
    Color(0xFF880E4F), // Pink
    Color(0xFF6A1B9A), // Purple
    Color(0xFF4A148C), // Deep purple
    Color(0xFF4E342E), // Brown
    Color(0xFF37474F), // Blue grey
    Color(0xFF212121), // Dark grey
    Color(0xFF827717), // Lime
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.console?.name ?? '');
    _abbreviationController =
        TextEditingController(text: widget.console?.abbreviation ?? '');
    _selectedColor = widget.console != null
        ? Color(widget.console!.colorValue)
        : _presetColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _abbreviationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: Text(_isEditing ? 'Edit Console' : 'Add Console'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'e.g., Nintendo 64',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _abbreviationController,
                decoration: const InputDecoration(
                  labelText: 'Abbreviation',
                  hintText: 'e.g., N64',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Abbreviation is required'
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                'COLOR',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary.withOpacity(0.8),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              _buildColorPicker(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: _save,
          child: Text(_isEditing ? 'UPDATE' : 'ADD'),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presetColors.map((color) {
        final isSelected = _selectedColor.value == color.value;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentGold
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GameProvider>();
    final console = GameConsole(
      id: widget.console?.id,
      name: _nameController.text.trim(),
      abbreviation: _abbreviationController.text.trim().toUpperCase(),
      colorValue: _selectedColor.value,
    );

    if (_isEditing) {
      provider.updateConsole(console);
    } else {
      provider.addConsole(console);
    }

    Navigator.pop(context);
  }
}
