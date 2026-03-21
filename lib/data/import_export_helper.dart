import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/game.dart';
import '../models/game_console.dart';
import 'database_helper.dart';

/// Handles JSON import/export of the entire game collection.
class ImportExportHelper {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  /// Export the full collection (consoles, games, screenshots) as JSON.
  static Future<Map<String, dynamic>> exportToJson() async {
    final consoles = await _db.getConsoles();
    final db = await _db.database;

    // Get all games (unfiltered)
    final gameMaps = await db.rawQuery('''
      SELECT g.*, c.name as console_name, c.abbreviation as console_abbreviation
      FROM games g
      LEFT JOIN consoles c ON g.console_id = c.id
      ORDER BY g.title ASC
    ''');

    // Build export structure with console abbreviations for portability
    final gamesExport = <Map<String, dynamic>>[];
    for (final gMap in gameMaps) {
      final game = Game.fromMap(gMap);
      final screenshots = await _db.getScreenshots(game.id!);

      // Encode cover art as base64 if it exists
      String? coverArtBase64;
      String? coverArtExt;
      if (game.coverArtPath != null && game.coverArtPath!.isNotEmpty) {
        final file = File(game.coverArtPath!);
        if (await file.exists()) {
          coverArtBase64 = base64Encode(await file.readAsBytes());
          coverArtExt = p.extension(game.coverArtPath!);
        }
      }

      // Encode screenshots as base64
      final screenshotsExport = <Map<String, dynamic>>[];
      for (final ss in screenshots) {
        final ssFile = File(ss['file_path'] as String);
        if (await ssFile.exists()) {
          screenshotsExport.add({
            'caption': ss['caption'],
            'sort_order': ss['sort_order'],
            'data': base64Encode(await ssFile.readAsBytes()),
            'extension': p.extension(ss['file_path'] as String),
          });
        }
      }

      gamesExport.add({
        'title': game.title,
        'console_abbreviation': game.consoleAbbreviation,
        'genre': game.genre,
        'min_players': game.minPlayers,
        'max_players': game.maxPlayers,
        'room': game.room,
        'storage_location': game.storageLocation,
        'region': game.region,
        'release_year': game.releaseYear,
        'notes': game.notes,
        'is_favorite': game.isFavorite,
        if (coverArtBase64 != null) 'cover_art_base64': coverArtBase64,
        if (coverArtExt != null) 'cover_art_extension': coverArtExt,
        if (screenshotsExport.isNotEmpty) 'screenshots': screenshotsExport,
      });
    }

    return {
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'consoles': consoles
          .map((c) => {
                'name': c.name,
                'abbreviation': c.abbreviation,
                'color_value': c.colorValue,
              })
          .toList(),
      'games': gamesExport,
    };
  }

  /// Export collection to a JSON file. Returns the file path.
  static Future<String> exportToFile() async {
    final data = await exportToJson();
    final json = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final filePath = p.join(dir.path, 'stash64_backup_$timestamp.json');
    await File(filePath).writeAsString(json);

    return filePath;
  }

  /// Import collection from a JSON file. Returns a summary of what was imported.
  static Future<ImportResult> importFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return ImportResult(success: false, message: 'File not found');
    }

    try {
      final json = await file.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;
      return await importFromJson(data);
    } catch (e) {
      return ImportResult(
          success: false, message: 'Invalid JSON file: $e');
    }
  }

  /// Import collection from parsed JSON data.
  static Future<ImportResult> importFromJson(
      Map<String, dynamic> data) async {
    final version = data['version'] as int? ?? 1;
    if (version > 2) {
      return ImportResult(
          success: false,
          message: 'Unsupported backup version: $version');
    }

    int consolesImported = 0;
    int gamesImported = 0;
    int screenshotsImported = 0;

    final appDir = await getApplicationDocumentsDirectory();

    // Import consoles — match by abbreviation to avoid duplicates
    final existingConsoles = await _db.getConsoles();
    final consoleMap = <String, int>{}; // abbreviation -> id
    for (final c in existingConsoles) {
      consoleMap[c.abbreviation] = c.id!;
    }

    final consolesData = data['consoles'] as List<dynamic>? ?? [];
    for (final cData in consolesData) {
      final abbr = cData['abbreviation'] as String;
      if (!consoleMap.containsKey(abbr)) {
        final id = await _db.insertConsole(GameConsole(
          name: cData['name'] as String,
          abbreviation: abbr,
          colorValue: cData['color_value'] as int,
        ));
        consoleMap[abbr] = id;
        consolesImported++;
      }
    }

    // Import games
    final gamesData = data['games'] as List<dynamic>? ?? [];
    for (final gData in gamesData) {
      final consoleAbbr = gData['console_abbreviation'] as String?;
      final consoleId = consoleAbbr != null
          ? consoleMap[consoleAbbr]
          : consoleMap.values.firstOrNull;

      if (consoleId == null) continue;

      // Restore cover art from base64
      String? coverArtPath;
      if (gData['cover_art_base64'] != null) {
        final coverDir = Directory(p.join(appDir.path, 'covers'));
        if (!await coverDir.exists()) {
          await coverDir.create(recursive: true);
        }
        final ext = gData['cover_art_extension'] as String? ?? '.png';
        final coverPath = p.join(coverDir.path,
            '${DateTime.now().millisecondsSinceEpoch}_import$ext');
        await File(coverPath)
            .writeAsBytes(base64Decode(gData['cover_art_base64'] as String));
        coverArtPath = coverPath;
      }

      final gameId = await _db.insertGame(Game(
        title: gData['title'] as String,
        consoleId: consoleId,
        genre: gData['genre'] as String? ?? 'Unknown',
        minPlayers: gData['min_players'] as int? ?? 1,
        maxPlayers: gData['max_players'] as int? ?? 1,
        coverArtPath: coverArtPath,
        room: gData['room'] as String?,
        storageLocation: gData['storage_location'] as String? ?? '',
        region: gData['region'] as String? ?? '',
        releaseYear: gData['release_year'] as int?,
        notes: gData['notes'] as String?,
        isFavorite: gData['is_favorite'] as bool? ?? false,
      ));
      gamesImported++;

      // Restore screenshots from base64
      final screenshotsData =
          gData['screenshots'] as List<dynamic>? ?? [];
      for (final ssData in screenshotsData) {
        final ssDir = Directory(
            p.join(appDir.path, 'screenshots', '$gameId'));
        if (!await ssDir.exists()) {
          await ssDir.create(recursive: true);
        }
        final ext = ssData['extension'] as String? ?? '.png';
        final ssPath = p.join(ssDir.path,
            '${DateTime.now().millisecondsSinceEpoch}_import$ext');
        await File(ssPath)
            .writeAsBytes(base64Decode(ssData['data'] as String));
        await _db.insertScreenshot(gameId, ssPath,
            caption: ssData['caption'] as String?);
        screenshotsImported++;
      }
    }

    return ImportResult(
      success: true,
      message: 'Imported $consolesImported consoles, '
          '$gamesImported games, $screenshotsImported screenshots',
      consolesImported: consolesImported,
      gamesImported: gamesImported,
      screenshotsImported: screenshotsImported,
    );
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int consolesImported;
  final int gamesImported;
  final int screenshotsImported;

  const ImportResult({
    required this.success,
    required this.message,
    this.consolesImported = 0,
    this.gamesImported = 0,
    this.screenshotsImported = 0,
  });
}
