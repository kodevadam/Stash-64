import '../models/filter_state.dart';
import '../models/game.dart';
import '../models/game_console.dart';
import 'data_repository.dart';
import 'database_helper.dart';
import 'sample_data.dart';

/// Local SQLite-backed implementation of [DataRepository].
/// Used on desktop (Linux, Windows, macOS) and mobile platforms.
class SqliteRepository implements DataRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  Future<void> initialize() async {
    // Ensure database is created and seeded
    await SampleData.seed(_db);
  }

  // --- Console operations ---

  @override
  Future<int> insertConsole(GameConsole console) => _db.insertConsole(console);

  @override
  Future<List<GameConsole>> getConsoles() => _db.getConsoles();

  @override
  Future<int> updateConsole(GameConsole console) => _db.updateConsole(console);

  @override
  Future<int> deleteConsole(int id) => _db.deleteConsole(id);

  // --- Game operations ---

  @override
  Future<int> insertGame(Game game) => _db.insertGame(game);

  @override
  Future<int> updateGame(Game game) => _db.updateGame(game);

  @override
  Future<int> deleteGame(int id) => _db.deleteGame(id);

  @override
  Future<Game?> getGame(int id) => _db.getGame(id);

  @override
  Future<List<Game>> getGames(FilterState filters) => _db.getGames(filters);

  @override
  Future<List<String>> getGenres() => _db.getGenres();

  @override
  Future<List<String>> getStorageLocations() => _db.getStorageLocations();

  @override
  Future<List<String>> getRooms() => _db.getRooms();

  @override
  Future<int> getGameCount() => _db.getGameCount();

  @override
  Future<int> getOwnedConsoleCount() => _db.getOwnedConsoleCount();

  @override
  Future<void> toggleFavorite(int gameId) => _db.toggleFavorite(gameId);

  // --- Screenshot operations ---

  @override
  Future<int> insertScreenshot(int gameId, String filePath,
          {String? caption}) =>
      _db.insertScreenshot(gameId, filePath, caption: caption);

  @override
  Future<List<Map<String, dynamic>>> getScreenshots(int gameId) =>
      _db.getScreenshots(gameId);

  @override
  Future<int> deleteScreenshot(int id) => _db.deleteScreenshot(id);
}
