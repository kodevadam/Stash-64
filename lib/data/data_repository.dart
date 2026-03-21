import '../models/filter_state.dart';
import '../models/game.dart';
import '../models/game_console.dart';

/// Abstract interface for data persistence.
///
/// Desktop/local uses [SqliteRepository] backed by SQLite.
/// Web uses [ApiRepository] backed by a REST API + PostgreSQL.
abstract class DataRepository {
  // --- Console operations ---
  Future<int> insertConsole(GameConsole console);
  Future<List<GameConsole>> getConsoles();
  Future<int> updateConsole(GameConsole console);
  Future<int> deleteConsole(int id);

  // --- Game operations ---
  Future<int> insertGame(Game game);
  Future<int> updateGame(Game game);
  Future<int> deleteGame(int id);
  Future<Game?> getGame(int id);
  Future<List<Game>> getGames(FilterState filters);
  Future<List<String>> getGenres();
  Future<List<String>> getStorageLocations();
  Future<List<String>> getRooms();
  Future<int> getGameCount();
  Future<void> toggleFavorite(int gameId);

  // --- Screenshot operations ---
  Future<int> insertScreenshot(int gameId, String filePath, {String? caption});
  Future<List<Map<String, dynamic>>> getScreenshots(int gameId);
  Future<int> deleteScreenshot(int id);

  // --- Lifecycle ---
  Future<void> initialize();
}
