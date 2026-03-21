import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/import_export_helper.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kiosk_wrapper.dart';

/// Get kiosk state for settings display (native only).
Map<String, dynamic>? getKioskState(BuildContext context) {
  final kiosk = KioskWrapper.of(context);
  if (kiosk == null) return null;
  return {
    'isFullscreen': kiosk.isFullscreen,
    'toggleFullscreen': () => kiosk.toggleFullscreen(),
  };
}

/// Export collection to file (native).
Future<void> exportCollection(BuildContext context) async {
  _showLoadingDialog(context, 'Exporting...');

  try {
    final filePath = await ImportExportHelper.exportToFile();
    if (context.mounted) {
      Navigator.pop(context);
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

/// Import collection from file (native).
Future<void> importCollection(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (result == null ||
      result.files.isEmpty ||
      result.files.first.path == null) {
    return;
  }

  if (!context.mounted) return;
  _showLoadingDialog(context, 'Importing...');

  try {
    final importResult =
        await ImportExportHelper.importFromFile(result.files.first.path!);

    if (context.mounted) {
      Navigator.pop(context);
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
