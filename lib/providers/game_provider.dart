import 'package:flutter/foundation.dart';

import '../data/database_helper.dart';
import '../data/sample_data.dart';
import '../models/filter_state.dart';
import '../models/game.dart';
import '../models/game_console.dart';

/// Central state manager for the game collection.
class GameProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Game> _games = [];
  List<GameConsole> _consoles = [];
  List<String> _genres = [];
  List<String> _storageLocations = [];
  FilterState _filterState = const FilterState();
  bool _isLoading = true;
  int _totalGameCount = 0;

  List<Game> get games => _games;
  List<GameConsole> get consoles => _consoles;
  List<String> get genres => _genres;
  List<String> get storageLocations => _storageLocations;
  FilterState get filterState => _filterState;
  bool get isLoading => _isLoading;
  int get totalGameCount => _totalGameCount;

  /// Initialize provider: seed sample data on first run, then load everything.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await SampleData.seed(_db);
    await _refreshAll();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshAll() async {
    _consoles = await _db.getConsoles();
    _genres = await _db.getGenres();
    _storageLocations = await _db.getStorageLocations();
    _totalGameCount = await _db.getGameCount();
    _games = await _db.getGames(_filterState);
  }

  // --- Filtering ---

  Future<void> setFilter(FilterState newFilter) async {
    _filterState = newFilter;
    _games = await _db.getGames(_filterState);
    notifyListeners();
  }

  Future<void> clearFilters() async {
    _filterState = const FilterState();
    _games = await _db.getGames(_filterState);
    notifyListeners();
  }

  Future<void> setSearchQuery(String query) async {
    _filterState = _filterState.copyWith(searchQuery: query);
    _games = await _db.getGames(_filterState);
    notifyListeners();
  }

  // --- Game CRUD ---

  Future<void> addGame(Game game) async {
    await _db.insertGame(game);
    await _refreshAll();
    _games = await _db.getGames(_filterState);
    notifyListeners();
  }

  Future<void> updateGame(Game game) async {
    await _db.updateGame(game);
    await _refreshAll();
    _games = await _db.getGames(_filterState);
    notifyListeners();
  }

  Future<void> deleteGame(int id) async {
    await _db.deleteGame(id);
    await _refreshAll();
    _games = await _db.getGames(_filterState);
    notifyListeners();
  }

  Future<void> toggleFavorite(int gameId) async {
    await _db.toggleFavorite(gameId);
    _games = await _db.getGames(_filterState);
    notifyListeners();
  }

  // --- Console CRUD ---

  Future<void> addConsole(GameConsole console) async {
    await _db.insertConsole(console);
    _consoles = await _db.getConsoles();
    notifyListeners();
  }

  Future<void> updateConsole(GameConsole console) async {
    await _db.updateConsole(console);
    await _refreshAll();
    _games = await _db.getGames(_filterState);
    notifyListeners();
  }

  Future<void> deleteConsole(int id) async {
    await _db.deleteConsole(id);
    await _refreshAll();
    _games = await _db.getGames(_filterState);
    notifyListeners();
  }
}
