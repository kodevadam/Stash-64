import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/import_export_helper.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kiosk_wrapper.dart';
import 'console_management_screen.dart';

/// Settings screen with console management, import/export, and kiosk controls.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final kiosk = KioskWrapper.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        toolbarHeight: 64,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Collection stats
          _buildSectionHeader(context, 'COLLECTION'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                      context, '${provider.totalGameCount}', 'Games'),
                  _buildStat(context, '${provider.consoles.length}',
                      'Consoles'),
                  _buildStat(
                      context, '${provider.genres.length}', 'Genres'),
                  _buildStat(context,
                      '${provider.storageLocations.length}', 'Locations'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Console management
          _buildSectionHeader(context, 'CONSOLES'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.videogame_asset,
                  color: AppTheme.accentGold),
              title: const Text('Manage Consoles'),
              subtitle: Text('${provider.consoles.length} consoles'),
              trailing: const Icon(Icons.chevron_right),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ConsoleManagementScreen()),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Import/Export
          _buildSectionHeader(context, 'BACKUP & RESTORE'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload,
                      color: AppTheme.accentCyan),
                  title: const Text('Export Collection'),
                  subtitle: const Text(
                      'Save your entire collection as a JSON backup'),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  onTap: () => _exportCollection(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download,
                      color: AppTheme.accentCyan),
                  title: const Text('Import Collection'),
                  subtitle:
                      const Text('Restore from a JSON backup file'),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  onTap: () => _importCollection(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Kiosk mode
          if (kiosk != null) ...[
            _buildSectionHeader(context, 'KIOSK MODE'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.fullscreen,
                        color: AppTheme.accentGold),
                    title: const Text('Fullscreen'),
                    subtitle: const Text('Also toggle with F11 or double-tap'),
                    value: kiosk.isFullscreen,
                    activeColor: AppTheme.accentGold,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    onChanged: (_) => kiosk.toggleFullscreen(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.tv,
                        color: AppTheme.accentGold),
                    title: const Text('Attract Mode'),
                    subtitle: const Text(
                        'Screensaver activates after 5 min idle'),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // About
          _buildSectionHeader(context, 'ABOUT'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stash 64',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'monospace',
                          color: AppTheme.accentGold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'v1.0.0',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A retro game collection browser designed for '
                    'touchscreen kiosks and Raspberry Pi.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary.withOpacity(0.8),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: AppTheme.accentGold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Future<void> _exportCollection(BuildContext context) async {
    _showLoadingDialog(context, 'Exporting...');

    try {
      final filePath = await ImportExportHelper.exportToFile();
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        _showResultDialog(
          context,
          'Export Complete',
          'Collection saved to:\n\n$filePath',
          icon: Icons.check_circle,
          iconColor: AppTheme.accentCyan,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showResultDialog(
          context,
          'Export Failed',
          'Error: $e',
          icon: Icons.error,
          iconColor: AppTheme.errorRed,
        );
      }
    }
  }

  Future<void> _importCollection(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty || result.files.first.path == null) {
      return;
    }

    if (!context.mounted) return;
    _showLoadingDialog(context, 'Importing...');

    try {
      final importResult =
          await ImportExportHelper.importFromFile(result.files.first.path!);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Refresh provider data
        await context.read<GameProvider>().initialize();

        if (context.mounted) {
          _showResultDialog(
            context,
            importResult.success ? 'Import Complete' : 'Import Failed',
            importResult.message,
            icon: importResult.success ? Icons.check_circle : Icons.error,
            iconColor:
                importResult.success ? AppTheme.accentCyan : AppTheme.errorRed,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showResultDialog(
          context,
          'Import Failed',
          'Error: $e',
          icon: Icons.error,
          iconColor: AppTheme.errorRed,
        );
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppTheme.accentGold),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showResultDialog(BuildContext context, String title, String message,
      {required IconData icon, required Color iconColor}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
