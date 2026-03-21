import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/game.dart';
import '../models/game_console.dart';
import '../models/filter_state.dart';

class DatabaseHelper {
  static const _databaseName = 'stash64.db';
  static const _databaseVersion = 2;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize sqflite_ffi for Linux/desktop platforms.
  static void initializeFfi() {
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE consoles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        abbreviation TEXT NOT NULL,
        color_value INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        console_id INTEGER NOT NULL,
        genre TEXT NOT NULL,
        min_players INTEGER NOT NULL DEFAULT 1,
        max_players INTEGER NOT NULL DEFAULT 1,
        cover_art_path TEXT,
        room TEXT DEFAULT '',
        storage_location TEXT NOT NULL DEFAULT '',
        region TEXT NOT NULL DEFAULT '',
        release_year INTEGER,
        notes TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (console_id) REFERENCES consoles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE screenshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        caption TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_games_console ON games (console_id)');
    await db.execute(
        'CREATE INDEX idx_games_genre ON games (genre)');
    await db.execute(
        'CREATE INDEX idx_games_storage ON games (storage_location)');
    await db.execute(
        'CREATE INDEX idx_games_region ON games (region)');
    await db.execute(
        'CREATE INDEX idx_games_room ON games (room)');
    await db.execute(
        'CREATE INDEX idx_screenshots_game ON screenshots (game_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE games ADD COLUMN region TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE games ADD COLUMN room TEXT DEFAULT ''");
      await db.execute('CREATE INDEX IF NOT EXISTS idx_games_region ON games (region)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_games_room ON games (room)');
    }
  }

  // --- Console CRUD ---

  Future<int> insertConsole(GameConsole console) async {
    final db = await database;
    return db.insert('consoles', console.toMap());
  }

  Future<List<GameConsole>> getConsoles() async {
    final db = await database;
    final maps = await db.query('consoles', orderBy: 'name ASC');
    return maps.map((m) => GameConsole.fromMap(m)).toList();
  }

  Future<int> updateConsole(GameConsole console) async {
    final db = await database;
    return db.update(
      'consoles',
      console.toMap(),
      where: 'id = ?',
      whereArgs: [console.id],
    );
  }

  Future<int> deleteConsole(int id) async {
    final db = await database;
    return db.delete('consoles', where: 'id = ?', whereArgs: [id]);
  }

  // --- Game CRUD ---

  Future<int> insertGame(Game game) async {
    final db = await database;
    return db.insert('games', game.toMap());
  }

  Future<int> updateGame(Game game) async {
    final db = await database;
    return db.update(
      'games',
      game.toMap(),
      where: 'id = ?',
      whereArgs: [game.id],
    );
  }

  Future<int> deleteGame(int id) async {
    final db = await database;
    return db.delete('games', where: 'id = ?', whereArgs: [id]);
  }

  Future<Game?> getGame(int id) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT g.*, c.name as console_name, c.abbreviation as console_abbreviation
      FROM games g
      LEFT JOIN consoles c ON g.console_id = c.id
      WHERE g.id = ?
    ''', [id]);
    if (maps.isEmpty) return null;
    return Game.fromMap(maps.first);
  }

  /// Query games with optional filters. Returns joined results with console info.
  Future<List<Game>> getGames(FilterState filters) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (filters.consoleId != null) {
      where.add('g.console_id = ?');
      args.add(filters.consoleId);
    }
    if (filters.genre != null) {
      where.add('g.genre = ?');
      args.add(filters.genre);
    }
    if (filters.playerCount != null) {
      where.add('g.min_players <= ? AND g.max_players >= ?');
      args.add(filters.playerCount);
      args.add(filters.playerCount);
    }
    if (filters.storageLocation != null) {
      where.add('g.storage_location = ?');
      args.add(filters.storageLocation);
    }
    if (filters.favoritesOnly == true) {
      where.add('g.is_favorite = 1');
    }
    if (filters.searchQuery.isNotEmpty) {
      where.add('g.title LIKE ?');
      args.add('%${filters.searchQuery}%');
    }

    final whereClause =
        where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

    String orderBy;
    final dir = filters.sortAscending ? 'ASC' : 'DESC';
    switch (filters.sortField) {
      case SortField.title:
        orderBy = 'g.title $dir';
        break;
      case SortField.console:
        orderBy = 'c.name $dir, g.title ASC';
        break;
      case SortField.genre:
        orderBy = 'g.genre $dir, g.title ASC';
        break;
      case SortField.releaseYear:
        orderBy = 'g.release_year $dir, g.title ASC';
        break;
      case SortField.storageLocation:
        orderBy = 'g.storage_location $dir, g.title ASC';
        break;
    }

    final maps = await db.rawQuery('''
      SELECT g.*, c.name as console_name, c.abbreviation as console_abbreviation
      FROM games g
      LEFT JOIN consoles c ON g.console_id = c.id
      $whereClause
      ORDER BY $orderBy
    ''', args);

    return maps.map((m) => Game.fromMap(m)).toList();
  }

  /// Get distinct genres from the games table.
  Future<List<String>> getGenres() async {
    final db = await database;
    final maps = await db.rawQuery(
        'SELECT DISTINCT genre FROM games ORDER BY genre ASC');
    return maps.map((m) => m['genre'] as String).toList();
  }

  /// Get distinct storage locations from the games table.
  Future<List<String>> getStorageLocations() async {
    final db = await database;
    final maps = await db.rawQuery(
        'SELECT DISTINCT storage_location FROM games WHERE storage_location != \'\' ORDER BY storage_location ASC');
    return maps.map((m) => m['storage_location'] as String).toList();
  }

  /// Get distinct rooms from the games table.
  Future<List<String>> getRooms() async {
    final db = await database;
    final maps = await db.rawQuery(
        "SELECT DISTINCT room FROM games WHERE room IS NOT NULL AND room != '' ORDER BY room ASC");
    return maps.map((m) => m['room'] as String).toList();
  }

  /// Get total game count.
  Future<int> getGameCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM games');
    return result.first['count'] as int;
  }

  /// Toggle favorite status for a game.
  Future<void> toggleFavorite(int gameId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE games SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END
      WHERE id = ?
    ''', [gameId]);
  }

  // --- Screenshot CRUD ---

  Future<int> insertScreenshot(int gameId, String filePath, {String? caption}) async {
    final db = await database;
    final count = await db.rawQuery(
        'SELECT COUNT(*) as c FROM screenshots WHERE game_id = ?', [gameId]);
    final sortOrder = (count.first['c'] as int);
    return db.insert('screenshots', {
      'game_id': gameId,
      'file_path': filePath,
      'caption': caption,
      'sort_order': sortOrder,
    });
  }

  Future<List<Map<String, dynamic>>> getScreenshots(int gameId) async {
    final db = await database;
    return db.query('screenshots',
        where: 'game_id = ?',
        whereArgs: [gameId],
        orderBy: 'sort_order ASC');
  }

  Future<int> deleteScreenshot(int id) async {
    final db = await database;
    return db.delete('screenshots', where: 'id = ?', whereArgs: [id]);
  }
}
