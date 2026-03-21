import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';
import 'db.dart';

/// Build all API routes.
Router buildRouter() {
  final router = Router();

  // ── Auth (session middleware applied globally, no requireAuth) ──
  router.post('/api/auth/google', Auth.handleGoogleSignIn);
  router.get('/api/auth/me', Auth.handleMe);
  router.post('/api/auth/logout', Auth.handleLogout);
  router.post('/api/auth/revoke-all', Auth.handleRevokeAll);
  router.delete('/api/auth/account', Auth.handleDeleteAccount);

  // ── Consoles (auth required) ──
  router.get('/api/consoles', _authed(_getConsoles));
  router.post('/api/consoles', _authed(_createConsole));
  router.put('/api/consoles/<id>', _authed(_updateConsole));
  router.delete('/api/consoles/<id>', _authed(_deleteConsole));

  // ── Games (auth required) ──
  router.get('/api/games', _authed(_getGames));
  router.get('/api/games/genres', _authed(_getGenres));
  router.get('/api/games/storage-locations', _authed(_getStorageLocations));
  router.get('/api/games/rooms', _authed(_getRooms));
  router.get('/api/games/count', _authed(_getGameCount));
  router.get('/api/games/<id>', _authed(_getGame));
  router.post('/api/games', _authed(_createGame));
  router.put('/api/games/<id>', _authed(_updateGame));
  router.delete('/api/games/<id>', _authed(_deleteGame));
  router.post('/api/games/<id>/toggle-favorite', _authed(_toggleFavorite));

  // ── Screenshots ──
  router.get('/api/games/<gameId>/screenshots', _authed(_getScreenshots));
  router.post('/api/games/<gameId>/screenshots', _authed(_createScreenshot));
  router.delete('/api/screenshots/<id>', _authed(_deleteScreenshot));

  return router;
}

/// Wrap a handler with auth-required middleware.
Handler _authed(Function handler) {
  return Pipeline()
      .addMiddleware(Auth.requireAuth())
      .addHandler((request) => handler(request));
}

Response _json(Object body, {int statusCode = 200}) {
  return Response(statusCode,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'});
}

// ── Consoles ──

Future<Response> _getConsoles(Request request) async {
  final userId = Auth.getUserId(request);
  final result = await Db.query(
    'SELECT id, name, abbreviation, color_value FROM consoles '
    'WHERE user_id = @userId::uuid ORDER BY name ASC',
    parameters: {'userId': userId},
  );
  final consoles = result
      .map((r) => {
            'id': r[0],
            'name': r[1],
            'abbreviation': r[2],
            'color_value': r[3],
          })
      .toList();
  return _json(consoles);
}

Future<Response> _createConsole(Request request) async {
  final userId = Auth.getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final result = await Db.query(
    'INSERT INTO consoles (user_id, name, abbreviation, color_value) '
    'VALUES (@userId::uuid, @name, @abbr, @color) RETURNING id',
    parameters: {
      'userId': userId,
      'name': body['name'],
      'abbr': body['abbreviation'],
      'color': body['color_value'],
    },
  );
  return _json({'id': result.first[0]}, statusCode: 201);
}

Future<Response> _updateConsole(Request request, String id) async {
  final userId = Auth.getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  await Db.query(
    'UPDATE consoles SET name = @name, abbreviation = @abbr, color_value = @color '
    'WHERE id = @id AND user_id = @userId::uuid',
    parameters: {
      'id': int.parse(id),
      'userId': userId,
      'name': body['name'],
      'abbr': body['abbreviation'],
      'color': body['color_value'],
    },
  );
  return _json({'ok': true});
}

Future<Response> _deleteConsole(Request request, String id) async {
  final userId = Auth.getUserId(request);
  await Db.query(
    'DELETE FROM consoles WHERE id = @id AND user_id = @userId::uuid',
    parameters: {'id': int.parse(id), 'userId': userId},
  );
  return _json({'ok': true});
}

// ── Games ──

Future<Response> _getGames(Request request) async {
  final userId = Auth.getUserId(request);
  final params = request.url.queryParameters;

  final where = <String>['g.user_id = @userId::uuid'];
  final queryParams = <String, dynamic>{'userId': userId};

  if (params.containsKey('console_id')) {
    where.add('g.console_id = @consoleId');
    queryParams['consoleId'] = int.parse(params['console_id']!);
  }
  if (params.containsKey('genre')) {
    where.add('g.genre = @genre');
    queryParams['genre'] = params['genre'];
  }
  if (params.containsKey('player_count')) {
    final pc = int.parse(params['player_count']!);
    where.add('g.min_players <= @pc AND g.max_players >= @pc');
    queryParams['pc'] = pc;
  }
  if (params.containsKey('storage_location')) {
    where.add('g.storage_location = @storLoc');
    queryParams['storLoc'] = params['storage_location'];
  }
  if (params['favorites_only'] == 'true') {
    where.add('g.is_favorite = TRUE');
  }
  if (params.containsKey('search') && params['search']!.isNotEmpty) {
    where.add('g.title ILIKE @search');
    queryParams['search'] = '%${params['search']}%';
  }

  final whereClause = where.join(' AND ');

  // Sort
  final sortField = params['sort_field'] ?? 'title';
  final sortAsc = params['sort_ascending'] != 'false';
  final dir = sortAsc ? 'ASC' : 'DESC';
  String orderBy;
  switch (sortField) {
    case 'console':
      orderBy = 'c.name $dir, g.title ASC';
    case 'genre':
      orderBy = 'g.genre $dir, g.title ASC';
    case 'releaseYear':
      orderBy = 'g.release_year $dir, g.title ASC';
    case 'storageLocation':
      orderBy = 'g.storage_location $dir, g.title ASC';
    default:
      orderBy = 'g.title $dir';
  }

  final result = await Db.query(
    'SELECT g.id, g.title, g.console_id, g.genre, g.min_players, g.max_players, '
    'g.cover_art_path, g.room, g.storage_location, g.region, g.release_year, '
    'g.notes, g.is_favorite, g.pricecharting_price, g.pricecharting_url, '
    'c.name as console_name, c.abbreviation as console_abbreviation '
    'FROM games g LEFT JOIN consoles c ON g.console_id = c.id '
    'WHERE $whereClause ORDER BY $orderBy',
    parameters: queryParams,
  );

  final games = result.map((r) => _gameRowToMap(r)).toList();
  return _json(games);
}

Future<Response> _getGame(Request request, String id) async {
  final userId = Auth.getUserId(request);
  final result = await Db.query(
    'SELECT g.id, g.title, g.console_id, g.genre, g.min_players, g.max_players, '
    'g.cover_art_path, g.room, g.storage_location, g.region, g.release_year, '
    'g.notes, g.is_favorite, g.pricecharting_price, g.pricecharting_url, '
    'c.name as console_name, c.abbreviation as console_abbreviation '
    'FROM games g LEFT JOIN consoles c ON g.console_id = c.id '
    'WHERE g.id = @id AND g.user_id = @userId::uuid',
    parameters: {'id': int.parse(id), 'userId': userId},
  );
  if (result.isEmpty) return Response(404);
  return _json(_gameRowToMap(result.first));
}

Future<Response> _createGame(Request request) async {
  final userId = Auth.getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final result = await Db.query(
    'INSERT INTO games (user_id, title, console_id, genre, min_players, max_players, '
    'cover_art_path, room, storage_location, region, release_year, notes, '
    'is_favorite, pricecharting_price, pricecharting_url) '
    'VALUES (@userId::uuid, @title, @consoleId, @genre, @minP, @maxP, '
    '@cover, @room, @storage, @region, @year, @notes, '
    '@fav, @price, @priceUrl) RETURNING id',
    parameters: {
      'userId': userId,
      'title': body['title'],
      'consoleId': body['console_id'],
      'genre': body['genre'],
      'minP': body['min_players'] ?? 1,
      'maxP': body['max_players'] ?? 1,
      'cover': body['cover_art_path'],
      'room': body['room'] ?? '',
      'storage': body['storage_location'] ?? '',
      'region': body['region'] ?? '',
      'year': body['release_year'],
      'notes': body['notes'],
      'fav': (body['is_favorite'] == 1 || body['is_favorite'] == true),
      'price': body['pricecharting_price'],
      'priceUrl': body['pricecharting_url'],
    },
  );
  return _json({'id': result.first[0]}, statusCode: 201);
}

Future<Response> _updateGame(Request request, String id) async {
  final userId = Auth.getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  await Db.query(
    'UPDATE games SET title = @title, console_id = @consoleId, genre = @genre, '
    'min_players = @minP, max_players = @maxP, cover_art_path = @cover, '
    'room = @room, storage_location = @storage, region = @region, '
    'release_year = @year, notes = @notes, is_favorite = @fav, '
    'pricecharting_price = @price, pricecharting_url = @priceUrl '
    'WHERE id = @id AND user_id = @userId::uuid',
    parameters: {
      'id': int.parse(id),
      'userId': userId,
      'title': body['title'],
      'consoleId': body['console_id'],
      'genre': body['genre'],
      'minP': body['min_players'] ?? 1,
      'maxP': body['max_players'] ?? 1,
      'cover': body['cover_art_path'],
      'room': body['room'] ?? '',
      'storage': body['storage_location'] ?? '',
      'region': body['region'] ?? '',
      'year': body['release_year'],
      'notes': body['notes'],
      'fav': (body['is_favorite'] == 1 || body['is_favorite'] == true),
      'price': body['pricecharting_price'],
      'priceUrl': body['pricecharting_url'],
    },
  );
  return _json({'ok': true});
}

Future<Response> _deleteGame(Request request, String id) async {
  final userId = Auth.getUserId(request);
  await Db.query(
    'DELETE FROM games WHERE id = @id AND user_id = @userId::uuid',
    parameters: {'id': int.parse(id), 'userId': userId},
  );
  return _json({'ok': true});
}

Future<Response> _toggleFavorite(Request request, String id) async {
  final userId = Auth.getUserId(request);
  await Db.query(
    'UPDATE games SET is_favorite = NOT is_favorite '
    'WHERE id = @id AND user_id = @userId::uuid',
    parameters: {'id': int.parse(id), 'userId': userId},
  );
  return _json({'ok': true});
}

Future<Response> _getGenres(Request request) async {
  final userId = Auth.getUserId(request);
  final result = await Db.query(
    'SELECT DISTINCT genre FROM games WHERE user_id = @userId::uuid ORDER BY genre ASC',
    parameters: {'userId': userId},
  );
  return _json(result.map((r) => r[0] as String).toList());
}

Future<Response> _getStorageLocations(Request request) async {
  final userId = Auth.getUserId(request);
  final result = await Db.query(
    "SELECT DISTINCT storage_location FROM games "
    "WHERE user_id = @userId::uuid AND storage_location != '' "
    'ORDER BY storage_location ASC',
    parameters: {'userId': userId},
  );
  return _json(result.map((r) => r[0] as String).toList());
}

Future<Response> _getRooms(Request request) async {
  final userId = Auth.getUserId(request);
  final result = await Db.query(
    "SELECT DISTINCT room FROM games "
    "WHERE user_id = @userId::uuid AND room IS NOT NULL AND room != '' "
    'ORDER BY room ASC',
    parameters: {'userId': userId},
  );
  return _json(result.map((r) => r[0] as String).toList());
}

Future<Response> _getGameCount(Request request) async {
  final userId = Auth.getUserId(request);
  final result = await Db.query(
    'SELECT COUNT(*) FROM games WHERE user_id = @userId::uuid',
    parameters: {'userId': userId},
  );
  return _json({'count': result.first[0]});
}

// ── Screenshots ──

Future<Response> _getScreenshots(Request request, String gameId) async {
  final userId = Auth.getUserId(request);
  final result = await Db.query(
    'SELECT s.id, s.game_id, s.file_path, s.caption, s.sort_order '
    'FROM screenshots s JOIN games g ON s.game_id = g.id '
    'WHERE s.game_id = @gameId AND g.user_id = @userId::uuid '
    'ORDER BY s.sort_order ASC',
    parameters: {'gameId': int.parse(gameId), 'userId': userId},
  );
  return _json(result
      .map((r) => {
            'id': r[0],
            'game_id': r[1],
            'file_path': r[2],
            'caption': r[3],
            'sort_order': r[4],
          })
      .toList());
}

Future<Response> _createScreenshot(Request request, String gameId) async {
  final userId = Auth.getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

  // Verify game belongs to user
  final gameCheck = await Db.query(
    'SELECT id FROM games WHERE id = @gameId AND user_id = @userId::uuid',
    parameters: {'gameId': int.parse(gameId), 'userId': userId},
  );
  if (gameCheck.isEmpty) return Response(404);

  final countResult = await Db.query(
    'SELECT COUNT(*) FROM screenshots WHERE game_id = @gameId',
    parameters: {'gameId': int.parse(gameId)},
  );
  final sortOrder = countResult.first[0] as int;

  final result = await Db.query(
    'INSERT INTO screenshots (game_id, file_path, caption, sort_order) '
    'VALUES (@gameId, @path, @caption, @sort) RETURNING id',
    parameters: {
      'gameId': int.parse(gameId),
      'path': body['file_path'],
      'caption': body['caption'],
      'sort': sortOrder,
    },
  );
  return _json({'id': result.first[0]}, statusCode: 201);
}

Future<Response> _deleteScreenshot(Request request, String id) async {
  final userId = Auth.getUserId(request);
  await Db.query(
    'DELETE FROM screenshots WHERE id = @id AND game_id IN '
    '(SELECT id FROM games WHERE user_id = @userId::uuid)',
    parameters: {'id': int.parse(id), 'userId': userId},
  );
  return _json({'ok': true});
}

/// Convert a game result row to a Flutter Game-compatible map.
Map<String, dynamic> _gameRowToMap(dynamic row) {
  return {
    'id': row[0],
    'title': row[1],
    'console_id': row[2],
    'genre': row[3],
    'min_players': row[4],
    'max_players': row[5],
    'cover_art_path': row[6],
    'room': row[7],
    'storage_location': row[8],
    'region': row[9],
    'release_year': row[10],
    'notes': row[11],
    // Convert PostgreSQL boolean to int for Flutter Game.fromMap
    'is_favorite': (row[12] == true) ? 1 : 0,
    'pricecharting_price': row[13],
    'pricecharting_url': row[14],
    'console_name': row[15],
    'console_abbreviation': row[16],
  };
}
