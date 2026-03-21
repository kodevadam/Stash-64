import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database_helper.dart';

/// Download cover art to local storage (native).
/// Returns the local file path, or null on failure.
Future<String?> downloadCoverArt(String url) async {
  try {
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 15),
    );
    if (response.statusCode == 200) {
      final appDir = await getApplicationDocumentsDirectory();
      final coverDir = Directory(p.join(appDir.path, 'covers'));
      if (!await coverDir.exists()) {
        await coverDir.create(recursive: true);
      }
      String ext = '.jpg';
      final contentType = response.headers['content-type'];
      if (contentType != null) {
        if (contentType.contains('png')) ext = '.png';
        if (contentType.contains('webp')) ext = '.webp';
      }
      final destPath = p.join(
          coverDir.path, '${DateTime.now().millisecondsSinceEpoch}$ext');
      await File(destPath).writeAsBytes(response.bodyBytes);
      return destPath;
    }
  } catch (_) {}
  return null;
}

/// Download and save screenshots to local storage (native).
Future<void> downloadAndSaveScreenshots(
    int gameId, List<String> urls) async {
  if (urls.isEmpty) return;

  final appDir = await getApplicationDocumentsDirectory();
  final ssDir = Directory(p.join(appDir.path, 'screenshots', '$gameId'));
  if (!await ssDir.exists()) {
    await ssDir.create(recursive: true);
  }

  int count = 0;
  for (final imageUrl in urls) {
    try {
      final imgResponse = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 15),
      );
      if (imgResponse.statusCode == 200) {
        String ext = '.jpg';
        final ct = imgResponse.headers['content-type'];
        if (ct != null) {
          if (ct.contains('png')) ext = '.png';
          if (ct.contains('webp')) ext = '.webp';
        }
        final destPath = p.join(ssDir.path,
            '${DateTime.now().millisecondsSinceEpoch}_$count$ext');
        await File(destPath).writeAsBytes(imgResponse.bodyBytes);
        await DatabaseHelper.instance.insertScreenshot(gameId, destPath);
        count++;
      }
    } catch (_) {}
  }
}
