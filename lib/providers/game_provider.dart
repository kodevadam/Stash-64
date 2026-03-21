import 'package:flutter/foundation.dart';

import '../data/data_repository.dart';
import '../models/filter_state.dart';
import '../models/game.dart';
import '../models/game_console.dart';

/// Central state manager for the game collection.
class GameProvider extends ChangeNotifier {
  final DataRepository _repo;

  GameProvider(this._repo);

  List<Game> _games = [];
  List<GameConsole> _consoles = [];
  List<String> _genres = [];
  List<String> _storageLocations = [];
  List<String> _rooms = [];
  FilterState _filterState = const FilterState();
  bool _isLoading = true;
  int _totalGameCount = 0;

  List<Game> get games => _games;
  List<GameConsole> get consoles => _consoles;
  List<String> get genres => _genres;
  List<String> get storageLocations => _storageLocations;
  List<String> get rooms => _rooms;
  FilterState get filterState => _filterState;
  bool get isLoading => _isLoading;
  int get totalGameCount => _totalGameCount;

  /// Initialize provider: seed default consoles on first run, then load everything.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _repo.initialize();
    await _refreshAll();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshAll() async {
    _consoles = await _repo.getConsoles();
    _genres = await _repo.getGenres();
    _storageLocations = await _repo.getStorageLocations();
    _rooms = await _repo.getRooms();
    _totalGameCount = await _repo.getGameCount();
    _games = await _repo.getGames(_filterState);
  }

  // --- Filtering ---

  Future<void> setFilter(FilterState newFilter) async {
    _filterState = newFilter;
    _games = await _repo.getGames(_filterState);
    notifyListeners();
  }

  Future<void> clearFilters() async {
    _filterState = const FilterState();
    _games = await _repo.getGames(_filterState);
    notifyListeners();
  }

  Future<void> setSearchQuery(String query) async {
    _filterState = _filterState.copyWith(searchQuery: query);
    _games = await _repo.getGames(_filterState);
    notifyListeners();
  }

  // --- Game CRUD ---

  Future<int> addGame(Game game) async {
    final id = await _repo.insertGame(game);
    await _refreshAll();
    _games = await _repo.getGames(_filterState);
    notifyListeners();
    return id;
  }

  Future<void> updateGame(Game game) async {
    await _repo.updateGame(game);
    await _refreshAll();
    _games = await _repo.getGames(_filterState);
    notifyListeners();
  }

  Future<void> deleteGame(int id) async {
    await _repo.deleteGame(id);
    await _refreshAll();
    _games = await _repo.getGames(_filterState);
    notifyListeners();
  }

  Future<void> toggleFavorite(int gameId) async {
    await _repo.toggleFavorite(gameId);
    _games = await _repo.getGames(_filterState);
    notifyListeners();
  }

  // --- Console CRUD ---

  Future<void> addConsole(GameConsole console) async {
    await _repo.insertConsole(console);
    _consoles = await _repo.getConsoles();
    notifyListeners();
  }

  Future<void> updateConsole(GameConsole console) async {
    await _repo.updateConsole(console);
    await _refreshAll();
    _games = await _repo.getGames(_filterState);
    notifyListeners();
  }

  Future<void> deleteConsole(int id) async {
    await _repo.deleteConsole(id);
    await _refreshAll();
    _games = await _repo.getGames(_filterState);
    notifyListeners();
  }
}
