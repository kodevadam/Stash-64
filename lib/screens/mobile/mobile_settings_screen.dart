import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../console_management_screen.dart';
import '../settings_screen.dart';

/// Mobile-friendly settings screen — uses the same content as the kiosk
/// settings but with a smaller AppBar.
class MobileSettingsScreen extends StatelessWidget {
  const MobileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        toolbarHeight: 48,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Collection stats - compact
          _buildSectionHeader('COLLECTION'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('${provider.totalGameCount}', 'Games'),
                  _stat('${provider.consoles.length}', 'Consoles'),
                  _stat('${provider.genres.length}', 'Genres'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Console management
          _buildSectionHeader('CONSOLES'),
          Card(
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.videogame_asset,
                  color: AppTheme.accentGold, size: 22),
              title: const Text('Manage Consoles',
                  style: TextStyle(fontSize: 14)),
              subtitle: Text('${provider.consoles.length} consoles',
                  style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ConsoleManagementScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // API Key
          _buildSectionHeader('GAME SEARCH'),
          // Reuse the existing _RawgApiKeyCard from settings_screen
          // by navigating to full settings for API key management
          Card(
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.key,
                  color: AppTheme.accentGold, size: 22),
              title: const Text('RAWG API Key',
                  style: TextStyle(fontSize: 14)),
              subtitle: Text(
                settings.rawgApiKey.isNotEmpty
                    ? 'Key configured'
                    : 'Not set',
                style: TextStyle(
                  fontSize: 12,
                  color: settings.rawgApiKey.isNotEmpty
                      ? AppTheme.accentCyan
                      : AppTheme.textSecondary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Display scale
          _buildSectionHeader('DISPLAY'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.text_fields,
                          color: AppTheme.accentGold, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child:
                            Text('UI Scale', style: TextStyle(fontSize: 14)),
                      ),
                      Text(
                        '${(settings.uiScale * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.uiScale,
                    min: SettingsProvider.minScale,
                    max: SettingsProvider.maxScale,
                    divisions: 16,
                    activeColor: AppTheme.accentGold,
                    onChanged: (v) => settings.setUiScale(v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // About
          _buildSectionHeader('ABOUT'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videogame_asset,
                          color: AppTheme.accentGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Stash 64',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGold,
                        ),
                      ),
                      const Spacer(),
                      const Text('v1.0.0',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Retro game collection manager',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary.withOpacity(0.8),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: AppTheme.accentGold,
          ),
        ),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
