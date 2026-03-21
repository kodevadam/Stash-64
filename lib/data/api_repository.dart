import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/filter_state.dart';
import '../models/game.dart';
import '../models/game_console.dart';
import 'data_repository.dart';

/// REST API-backed implementation of [DataRepository].
/// Used on Flutter Web, talks to the Dart backend server over HTTP.
///
/// Authentication is handled via HttpOnly session cookies set by the
/// backend after Google Sign-In. The browser automatically includes
/// these cookies on every request — no manual token management needed.
class ApiRepository implements DataRepository {
  final String baseUrl;

  /// HTTP client that preserves cookies across requests.
  final http.Client _client;

  ApiRepository({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ── Lifecycle ──

  @override
  Future<void> initialize() async {
    // Server handles seeding on first user creation
  }

  // ── Auth ──

  /// Send Google ID token to backend for verification and session creation.
  /// Returns user info on success. Session cookie is set automatically.
  Future<Map<String, dynamic>> signInWithGoogle(String idToken) async {
    final resp = await _client.post(
      Uri.parse('$baseUrl/api/auth/google'),
      headers: _headers,
      body: jsonEncode({'idToken': idToken}),
    );
    _checkResponse(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Check current session state. Returns user info or null if not authenticated.
  Future<Map<String, dynamic>?> checkSession() async {
    final resp = await _client.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _headers,
    );
    if (resp.statusCode == 401) return null;
    _checkResponse(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Logout — revoke current session.
  Future<void> logout() async {
    final resp = await _client.post(
      Uri.parse('$baseUrl/api/auth/logout'),
      headers: _headers,
    );
    _checkResponse(resp);
  }

  /// Delete account and all data.
  Future<void> deleteAccount() async {
    final resp = await _client.delete(
      Uri.parse('$baseUrl/api/auth/account'),
      headers: _headers,
    );
    _checkResponse(resp);
  }

  // ── Console operations ──

  @override
  Future<int> insertConsole(GameConsole console) async {
    final resp = await _client.post(
      Uri.parse('$baseUrl/api/consoles'),
      headers: _headers,
      body: jsonEncode(console.toMap()),
    );
    _checkResponse(resp);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['id'] as int;
  }

  @override
  Future<List<GameConsole>> getConsoles() async {
    final resp = await _client.get(
      Uri.parse('$baseUrl/api/consoles'),
      headers: _headers,
    );
    _checkResponse(resp);
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((m) => GameConsole.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> updateConsole(GameConsole console) async {
    final resp = await _client.put(
      Uri.parse('$baseUrl/api/consoles/${console.id}'),
      headers: _headers,
      body: jsonEncode(console.toMap()),
    );
    _checkResponse(resp);
    return 1;
  }

  @override
  Future<int> deleteConsole(int id) async {
    final resp = await _client.delete(
      Uri.parse('$baseUrl/api/consoles/$id'),
      headers: _headers,
    );
    _checkResponse(resp);
    return 1;
  }

  // ── Game operations ──

  @override
  Future<int> insertGame(Game game) async {
    final resp = await _client.post(
      Uri.parse('$baseUrl/api/games'),
      headers: _headers,
      body: jsonEncode(game.toMap()),
    );
    _checkResponse(resp);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['id'] as int;
  }

  @override
  Future<int> updateGame(Game game) async {
    final resp = await _client.put(
      Uri.parse('$baseUrl/api/games/${game.id}'),
      headers: _headers,
      body: jsonEncode(game.toMap()),
    );
    _checkResponse(resp);
    return 1;
  }

  @override
  Future<int> deleteGame(int id) async {
    final resp = await _client.delete(
      Uri.parse('$baseUrl/api/games/$id'),
      headers: _headers,
    );
    _checkResponse(resp);
    return 1;
  }

  @override
  Future<Game?> getGame(int id) async {
    final resp = await _client.get(
      Uri.parse('$baseUrl/api/games/$id'),
      headers: _headers,
    );
    if (resp.statusCode == 404) return null;
    _checkResponse(resp);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return Game.fromMap(data);
  }

  @override
  Future<List<Game>> getGames(FilterState filters) async {
    final params = <String, String>{};
    if (filters.consoleId != null) {
      params['console_id'] = '${filters.consoleId}';
    }
    if (filters.genre != null) params['genre'] = filters.genre!;
    if (filters.playerCount != null) {
      params['player_count'] = '${filters.playerCount}';
    }
    if (filters.storageLocation != null) {
      params['storage_location'] = filters.storageLocation!;
    }
    if (filters.favoritesOnly == true) params['favorites_only'] = 'true';
    if (filters.searchQuery.isNotEmpty) {
      params['search'] = filters.searchQuery;
    }
    params['sort_field'] = filters.sortField.name;
    params['sort_ascending'] = '${filters.sortAscending}';

    final uri =
        Uri.parse('$baseUrl/api/games').replace(queryParameters: params);
    final resp = await _client.get(uri, headers: _headers);
    _checkResponse(resp);
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((m) => Game.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<String>> getGenres() async {
    final resp = await _client.get(
      Uri.parse('$baseUrl/api/games/genres'),
      headers: _headers,
    );
    _checkResponse(resp);
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.cast<String>();
  }

  @override
  Future<List<String>> getStorageLocations() async {
    final resp = await _client.get(
      Uri.parse('$baseUrl/api/games/storage-locations'),
      headers: _headers,
    );
    _checkResponse(resp);
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.cast<String>();
  }

  @override
  Future<List<String>> getRooms() async {
    final resp = await _client.get(
      Uri.parse('$baseUrl/api/games/rooms'),
      headers: _headers,
    );
    _checkResponse(resp);
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.cast<String>();
  }

  @override
  Future<int> getGameCount() async {
    final resp = await _client.get(
      Uri.parse('$baseUrl/api/games/count'),
      headers: _headers,
    );
    _checkResponse(resp);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['count'] as int;
  }

  @override
  Future<int> getOwnedConsoleCount() async {
    // Derive from game list — count distinct console IDs
    final games = await getGames(const FilterState());
    return games.map((g) => g.consoleId).toSet().length;
  }

  @override
  Future<void> toggleFavorite(int gameId) async {
    final resp = await _client.post(
      Uri.parse('$baseUrl/api/games/$gameId/toggle-favorite'),
      headers: _headers,
    );
    _checkResponse(resp);
  }

  // ── Screenshot operations ──

  @override
  Future<int> insertScreenshot(int gameId, String filePath,
      {String? caption}) async {
    final resp = await _client.post(
      Uri.parse('$baseUrl/api/games/$gameId/screenshots'),
      headers: _headers,
      body: jsonEncode({
        'file_path': filePath,
        'caption': caption,
      }),
    );
    _checkResponse(resp);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['id'] as int;
  }

  @override
  Future<List<Map<String, dynamic>>> getScreenshots(int gameId) async {
    final resp = await _client.get(
      Uri.parse('$baseUrl/api/games/$gameId/screenshots'),
      headers: _headers,
    );
    _checkResponse(resp);
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  @override
  Future<int> deleteScreenshot(int id) async {
    final resp = await _client.delete(
      Uri.parse('$baseUrl/api/screenshots/$id'),
      headers: _headers,
    );
    _checkResponse(resp);
    return 1;
  }

  void _checkResponse(http.Response resp) {
    if (resp.statusCode >= 400) {
      throw ApiException(resp.statusCode, resp.body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
