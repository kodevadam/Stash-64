import 'package:postgres/postgres.dart';

/// PostgreSQL connection pool manager.
class Db {
  static Pool? _pool;

  /// Initialize the connection pool.
  static Future<void> init({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
  }) async {
    final endpoint = Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    );

    _pool = Pool.withEndpoints(
      [endpoint],
      settings: PoolSettings(maxConnectionCount: 10),
    );

    // Run migrations
    await _migrate();
  }

  static Pool get pool {
    if (_pool == null) throw StateError('Database not initialized');
    return _pool!;
  }

  /// Execute a query using a connection from the pool.
  static Future<Result> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    return pool.execute(Sql.named(sql), parameters: parameters ?? {});
  }

  static Future<void> _migrate() async {
    // Create schema version table
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS _schema_version (
        version INTEGER PRIMARY KEY
      )
    ''');

    final versionResult =
        await pool.execute('SELECT version FROM _schema_version LIMIT 1');
    final currentVersion =
        versionResult.isEmpty ? 0 : versionResult.first[0] as int;

    if (currentVersion < 1) {
      await _migrateV1();
    }

    // Upsert schema version
    if (currentVersion == 0) {
      await pool.execute(
          'INSERT INTO _schema_version (version) VALUES (1)');
    } else if (currentVersion < 1) {
      await pool.execute(
          'UPDATE _schema_version SET version = 1');
    }
  }

  static Future<void> _migrateV1() async {
    // ── Users ──
    // google_sub is the permanent, immutable identity anchor.
    // Email is stored as optional profile/contact data only.
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        google_sub TEXT UNIQUE NOT NULL,
        email TEXT,
        email_verified BOOLEAN DEFAULT FALSE,
        display_name TEXT,
        avatar_url TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        last_login_at TIMESTAMPTZ
      )
    ''');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_users_google_sub ON users(google_sub)');

    // ── Sessions ──
    // Only hashed tokens are stored. Raw tokens exist only in cookies.
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        session_token_hash TEXT UNIQUE NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        expires_at TIMESTAMPTZ NOT NULL,
        last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        revoked_at TIMESTAMPTZ,
        ip_created TEXT,
        user_agent_created TEXT,
        ip_last_seen TEXT,
        user_agent_last_seen TEXT
      )
    ''');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id)');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_sessions_hash ON sessions(session_token_hash)');

    // ── Auth audit log ──
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS auth_audit_log (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        event_type TEXT NOT NULL,
        reason_code TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        ip TEXT,
        user_agent TEXT
      )
    ''');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_audit_user ON auth_audit_log(user_id)');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_audit_event ON auth_audit_log(event_type)');

    // ── Consoles (per-user) ──
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS consoles (
        id SERIAL PRIMARY KEY,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        abbreviation TEXT NOT NULL,
        color_value INTEGER NOT NULL
      )
    ''');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_consoles_user ON consoles(user_id)');

    // ── Games (per-user) ──
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS games (
        id SERIAL PRIMARY KEY,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        console_id INTEGER NOT NULL REFERENCES consoles(id),
        genre TEXT NOT NULL,
        min_players INTEGER NOT NULL DEFAULT 1,
        max_players INTEGER NOT NULL DEFAULT 1,
        cover_art_path TEXT,
        room TEXT DEFAULT '',
        storage_location TEXT NOT NULL DEFAULT '',
        region TEXT NOT NULL DEFAULT '',
        release_year INTEGER,
        notes TEXT,
        is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
        pricecharting_price DOUBLE PRECISION,
        pricecharting_url TEXT
      )
    ''');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_games_user ON games(user_id)');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_games_console ON games(console_id)');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_games_genre ON games(genre)');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_games_storage ON games(storage_location)');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_games_region ON games(region)');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_games_room ON games(room)');

    // ── Screenshots (per-game) ──
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS screenshots (
        id SERIAL PRIMARY KEY,
        game_id INTEGER NOT NULL REFERENCES games(id) ON DELETE CASCADE,
        file_path TEXT NOT NULL,
        caption TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_screenshots_game ON screenshots(game_id)');
  }
}
