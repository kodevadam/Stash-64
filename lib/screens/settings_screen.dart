import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sc64_service.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'console_management_screen.dart';
import 'game_form_io.dart' if (dart.library.html) 'game_form_web.dart';
import 'settings_io.dart' if (dart.library.html) 'settings_web.dart';

/// Settings screen with console management, import/export, and kiosk controls.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final settings = context.watch<SettingsProvider>();
    final kioskState = getKioskState(context);

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
                  _buildStat(context, '${provider.ownedConsoleCount}',
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
              subtitle: Text('${provider.ownedConsoleCount} owned, ${provider.consoles.length} available'),
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

          // Import/Export (native only)
          if (!kIsWeb) ...[
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
                    onTap: () => exportCollection(context),
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
                    onTap: () => importCollection(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Kiosk mode (native only)
          if (kioskState != null) ...[
            _buildSectionHeader(context, 'KIOSK MODE'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.fullscreen,
                        color: AppTheme.accentGold),
                    title: const Text('Fullscreen'),
                    subtitle: const Text('Also toggle with F11 or double-tap'),
                    value: kioskState['isFullscreen'] as bool,
                    activeColor: AppTheme.accentGold,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    onChanged: (_) {
                      final toggle = kioskState['toggleFullscreen'] as VoidCallback;
                      toggle();
                    },
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

          // UI Scale
          _buildSectionHeader(context, 'DISPLAY'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.text_fields,
                          color: AppTheme.accentGold, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('UI Scale',
                            style: TextStyle(fontSize: 16)),
                      ),
                      Text(
                        '${(settings.uiScale * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 14),
                      trackHeight: 6,
                      activeTrackColor: AppTheme.accentGold,
                      inactiveTrackColor:
                          AppTheme.textSecondary.withOpacity(0.2),
                      thumbColor: AppTheme.accentGold,
                    ),
                    child: Slider(
                      value: settings.uiScale,
                      min: SettingsProvider.minScale,
                      max: SettingsProvider.maxScale,
                      divisions: 16,
                      onChanged: (v) => settings.setUiScale(v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${(SettingsProvider.minScale * 100).round()}%',
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12)),
                      SizedBox(
                        height: 36,
                        child: TextButton(
                          onPressed: () => settings
                              .setUiScale(SettingsProvider.defaultScale),
                          child: const Text('Reset',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      Text(
                          '${(SettingsProvider.maxScale * 100).round()}%',
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Game Search API
          _buildSectionHeader(context, 'GAME SEARCH'),
          _RawgApiKeyCard(settings: settings),
          const SizedBox(height: 24),

          // SummerCart64 flashcart integration (native only)
          if (!kIsWeb) ...[
            _buildSectionHeader(context, 'SUMMERCART64'),
            _Sc64Card(settings: settings),
            const SizedBox(height: 24),
          ],

          // Game-detail backdrop media
          if (!kIsWeb) ...[
            _buildSectionHeader(context, 'GAME PAGE BACKDROP'),
            _BackdropCard(settings: settings),
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
}

class _RawgApiKeyCard extends StatefulWidget {
  final SettingsProvider settings;
  const _RawgApiKeyCard({required this.settings});

  @override
  State<_RawgApiKeyCard> createState() => _RawgApiKeyCardState();
}

class _RawgApiKeyCardState extends State<_RawgApiKeyCard> {
  late TextEditingController _controller;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.settings.userRawgApiKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasBuiltIn = widget.settings.hasBuiltInRawgKey;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.key, color: AppTheme.accentGold, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('RAWG API Key',
                      style: TextStyle(fontSize: 16)),
                ),
                if (hasBuiltIn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Key provided',
                      style: TextStyle(
                        color: AppTheme.accentCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasBuiltIn
                  ? 'A built-in API key is already configured. You can '
                    'optionally enter your own key to override it.'
                  : 'Optional. Get a free key at rawg.io/apidocs for '
                    'reliable game search. Works without one but may be '
                    'rate-limited.',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: _obscured,
              decoration: InputDecoration(
                hintText: 'Paste API key here',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscured ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textSecondary,
                        size: 22,
                      ),
                      onPressed: () =>
                          setState(() => _obscured = !_obscured),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check,
                          color: AppTheme.accentGold, size: 22),
                      onPressed: () {
                        widget.settings.setRawgApiKey(_controller.text);
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('API key saved'),
                            backgroundColor: AppTheme.accentGold,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              onSubmitted: (v) {
                widget.settings.setRawgApiKey(v);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API key saved'),
                    backgroundColor: AppTheme.accentGold,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings card for the SummerCart64 integration. Off by default; when
/// enabled, exposes controls to pick the sc64deployer binary, ROM
/// library dir, and probes the current device status.
class _Sc64Card extends StatefulWidget {
  final SettingsProvider settings;
  const _Sc64Card({required this.settings});

  @override
  State<_Sc64Card> createState() => _Sc64CardState();
}

class _Sc64CardState extends State<_Sc64Card> {
  Sc64Status _status = Sc64Status.unknown;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    if (widget.settings.sc64Enabled) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    if (_checking) return;
    setState(() => _checking = true);
    final svc = Sc64Service(binaryPath: widget.settings.sc64BinaryPath);
    final status = await svc.checkStatus();
    if (mounted) {
      setState(() {
        _status = status;
        _checking = false;
      });
    }
  }

  Future<void> _pickBinary() async {
    final path = await pickSc64BinaryPath();
    if (path != null) {
      await widget.settings.setSc64BinaryPath(path);
      _refreshStatus();
    }
  }

  Future<void> _autoDetectBinary() async {
    final detected = await Sc64Service.autoDetectBinary();
    if (detected != null) {
      await widget.settings.setSc64BinaryPath(detected);
      _refreshStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found sc64deployer at $detected')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('sc64deployer not found on PATH')),
      );
    }
  }

  Future<void> _pickRomDir() async {
    final dir = await pickRomLibraryDir();
    if (dir != null) await widget.settings.setRomLibraryDir(dir);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.cable, color: AppTheme.accentGold),
            title: const Text('Enable SummerCart64 uploads'),
            subtitle: const Text(
                'Adds an upload button on N64 game pages. Desktop only.'),
            value: s.sc64Enabled,
            activeColor: AppTheme.accentGold,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onChanged: (v) async {
              await s.setSc64Enabled(v);
              if (v) _refreshStatus();
            },
          ),
          if (s.sc64Enabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.terminal, color: AppTheme.accentCyan),
              title: const Text('sc64deployer binary'),
              subtitle: Text(
                s.sc64BinaryPath.isEmpty
                    ? 'Using PATH (falls back to `sc64deployer`)'
                    : s.sc64BinaryPath,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    icon: const Icon(Icons.radar),
                    tooltip: 'Auto-detect on PATH',
                    onPressed: _autoDetectBinary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    tooltip: 'Pick binary',
                    onPressed: _pickBinary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.folder, color: AppTheme.accentCyan),
              title: const Text('ROM library directory'),
              subtitle: Text(
                s.romLibraryDir.isEmpty
                    ? 'Default: app documents / roms/'
                    : s.romLibraryDir,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: 'Pick directory',
                onPressed: _pickRomDir,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: _Sc64StatusIcon(state: _status.state),
              title: Text(_Sc64StatusIcon.labelFor(_status.state)),
              subtitle: Text(
                _status.message.isEmpty
                    ? 'Tap refresh to probe'
                    : _status.message,
              ),
              trailing: IconButton(
                icon: _checking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentGold,
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: _checking ? null : _refreshStatus,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Sc64StatusIcon extends StatelessWidget {
  final Sc64DeviceState state;
  const _Sc64StatusIcon({required this.state});

  @override
  Widget build(BuildContext context) {
    final data = _iconFor(state);
    return Icon(data.$1, color: data.$2);
  }

  static String labelFor(Sc64DeviceState state) {
    switch (state) {
      case Sc64DeviceState.ready:            return 'Connected and ready';
      case Sc64DeviceState.lockedByConsole:  return 'Locked by N64';
      case Sc64DeviceState.notConnected:     return 'Not connected';
      case Sc64DeviceState.binaryMissing:    return 'sc64deployer not found';
      case Sc64DeviceState.notSupported:     return 'Desktop only';
      case Sc64DeviceState.error:            return 'Error';
      case Sc64DeviceState.unknown:          return 'Status unknown';
    }
  }

  static (IconData, Color) _iconFor(Sc64DeviceState state) {
    switch (state) {
      case Sc64DeviceState.ready:
        return (Icons.check_circle, AppTheme.accentCyan);
      case Sc64DeviceState.lockedByConsole:
        return (Icons.lock, AppTheme.accentGold);
      case Sc64DeviceState.notConnected:
      case Sc64DeviceState.binaryMissing:
      case Sc64DeviceState.notSupported:
      case Sc64DeviceState.unknown:
        return (Icons.help_outline, AppTheme.textSecondary);
      case Sc64DeviceState.error:
        return (Icons.error, AppTheme.errorRed);
    }
  }
}

/// Settings card for the per-game backdrop feature.
class _BackdropCard extends StatelessWidget {
  final SettingsProvider settings;
  const _BackdropCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary:
                const Icon(Icons.wallpaper, color: AppTheme.accentGold),
            title: const Text('Render per-game backdrops'),
            subtitle: const Text(
                'Shows user-added images / gifs / videos behind each game page.'),
            value: settings.backdropEnabled,
            activeColor: AppTheme.accentGold,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onChanged: (v) => settings.setBackdropEnabled(v),
          ),
          if (settings.backdropEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.shuffle, color: AppTheme.accentCyan),
              title: const Text('Playback mode'),
              subtitle: Text(
                settings.backdropPlayback == BackdropPlayback.shuffle
                    ? 'Shuffle — pick one random backdrop per visit'
                    : 'Cycle — crossfade through them in order',
              ),
              trailing: DropdownButton<BackdropPlayback>(
                value: settings.backdropPlayback,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: BackdropPlayback.shuffle,
                    child: Text('Shuffle'),
                  ),
                  DropdownMenuItem(
                    value: BackdropPlayback.cycle,
                    child: Text('Cycle'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) settings.setBackdropPlayback(v);
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.blur_on, color: AppTheme.accentCyan),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('Blur')),
                  Text(
                    settings.backdropBlurSigma.toStringAsFixed(0),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: AppTheme.accentGold,
                    ),
                  ),
                ],
              ),
            ),
            Slider(
              value: settings.backdropBlurSigma,
              min: 0,
              max: 40,
              divisions: 40,
              activeColor: AppTheme.accentGold,
              onChanged: (v) => settings.setBackdropBlurSigma(v),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.opacity, color: AppTheme.accentCyan),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('Darken overlay')),
                  Text(
                    '${(settings.backdropScrimOpacity * 100).round()}%',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: AppTheme.accentGold,
                    ),
                  ),
                ],
              ),
            ),
            Slider(
              value: settings.backdropScrimOpacity,
              min: 0,
              max: 1,
              divisions: 20,
              activeColor: AppTheme.accentGold,
              onChanged: (v) => settings.setBackdropScrimOpacity(v),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
