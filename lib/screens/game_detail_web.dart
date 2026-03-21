import 'package:flutter/material.dart';

/// Load screenshots for a game (web — via API, placeholder for now).
Future<List<Map<String, dynamic>>> loadScreenshots(int gameId) async {
  // TODO: Implement via ApiRepository when screenshot upload is supported
  return [];
}

/// Delete a screenshot by ID (web).
Future<void> deleteScreenshotById(int screenshotId) async {
  // TODO: Implement via ApiRepository
}

/// Add screenshots to a game (web — not yet supported).
Future<void> addScreenshotToGame(BuildContext context, int gameId) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Screenshot upload coming soon for web')),
  );
}
