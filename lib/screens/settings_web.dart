import 'package:flutter/material.dart';

/// Kiosk state is not available on web.
Map<String, dynamic>? getKioskState(BuildContext context) => null;

/// Export collection (web — not supported).
Future<void> exportCollection(BuildContext context) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Export is available in the desktop app')),
  );
}

/// Import collection (web — not supported).
Future<void> importCollection(BuildContext context) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Import is available in the desktop app')),
  );
}
