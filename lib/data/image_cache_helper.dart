import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Caches network images to local disk for offline access and faster loading.
class ImageCacheHelper {
  static Directory? _cacheDir;

  /// Get or create the cache directory.
  static Future<Directory> get cacheDirectory async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(p.join(appDir.path, 'image_cache'));
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  /// Generate a cache key from a URL using hashCode.
  static String _cacheKey(String url) {
    // Use a combination of hashCode values for a simple but effective key
    final hash = url.hashCode.toUnsigned(32).toRadixString(16).padLeft(8, '0');
    final hash2 =
        url.split('').reversed.join().hashCode.toUnsigned(32).toRadixString(16).padLeft(8, '0');
    return '$hash$hash2';
  }

  /// Get a cached file for a URL, or download and cache it.
  /// Returns the local file path.
  static Future<String?> getCachedImage(String url) async {
    try {
      final dir = await cacheDirectory;
      final key = _cacheKey(url);

      // Check for existing cached file
      for (final ext in ['.jpg', '.png', '.webp']) {
        final file = File(p.join(dir.path, '$key$ext'));
        if (await file.exists()) {
          return file.path;
        }
      }

      // Download and cache
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != 200) return null;

      String ext = '.jpg';
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('png')) {
        ext = '.png';
      } else if (contentType.contains('webp')) {
        ext = '.webp';
      }

      final file = File(p.join(dir.path, '$key$ext'));
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Clear old cached images (older than maxAge).
  static Future<void> clearOldCache({
    Duration maxAge = const Duration(days: 30),
  }) async {
    try {
      final dir = await cacheDirectory;
      final now = DateTime.now();
      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (now.difference(stat.modified) > maxAge) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
  }
}
