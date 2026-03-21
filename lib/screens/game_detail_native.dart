import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database_helper.dart';

/// Load screenshots for a game (native — direct DB access).
Future<List<Map<String, dynamic>>> loadScreenshots(int gameId) async {
  return DatabaseHelper.instance.getScreenshots(gameId);
}

/// Delete a screenshot by ID (native).
Future<void> deleteScreenshotById(int screenshotId) async {
  await DatabaseHelper.instance.deleteScreenshot(screenshotId);
}

/// Add screenshots to a game via file picker (native).
Future<void> addScreenshotToGame(BuildContext context, int gameId) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: true,
  );

  if (result == null || result.files.isEmpty) return;

  final appDir = await getApplicationDocumentsDirectory();
  final screenshotDir =
      Directory(p.join(appDir.path, 'screenshots', '$gameId'));
  if (!await screenshotDir.exists()) {
    await screenshotDir.create(recursive: true);
  }

  for (final file in result.files) {
    if (file.path == null) continue;
    final ext = p.extension(file.path!);
    final newName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(screenshotDir.path, newName);
    await File(file.path!).copy(destPath);
    await DatabaseHelper.instance.insertScreenshot(gameId, destPath);
  }
}
