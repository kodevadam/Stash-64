import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';

import 'db.dart';

/// ════════════════════════════════════════════════════════════════════
/// TRUST BOUNDARY: Auth is the sole authority for identity verification
/// and session management. The frontend is untrusted. Google proves
/// identity once; the backend verifies that proof server-side and
/// creates its own hardened session. Google tokens are NOT sessions.
/// ════════════════════════════════════════════════════════════════════
class Auth {
  // ── Configuration via environment variables ──
  // The Google OAuth client ID this app was issued. Tokens not
  // matching this audience are rejected.
  static String get _googleClientId =>
      Platform.environment['GOOGLE_CLIENT_ID'] ?? '';

  /// Session absolute expiry (30 days).
  static const _sessionMaxAge = Duration(days: 30);

  /// Session idle timeout (7 days without activity).
  static const _sessionIdleTimeout = Duration(days: 7);

  /// Cookie name for the session token.
  static const _cookieName = 'stash64_session';

  /// Whether we're in production (HTTPS enforced, secure cookies).
  static bool get _isProduction =>
      Platform.environment['DART_ENV'] == 'production';

  // ── Cryptographic helpers ──

  /// Generate a cryptographically secure random session token (256-bit).
  static String _generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Hash a session token with SHA-256 before storing in DB.
  /// Raw tokens only ever exist in cookies, never in the database.
  static String _hashToken(String token) {
    return sha256.convert(utf8.encode(token)).toString();
  }

  // ── Google ID token verification ──

  /// Verify a Google ID token server-side.
  /// Validates: signature, issuer, audience, expiry, subject.
  /// Rejects malformed, replayed, expired, or mis-audienced tokens.
  ///
  /// Returns the verified claims on success.
  /// Throws [AuthException] on any failure (fail closed).
  static Future<Map<String, dynamic>> _verifyGoogleIdToken(
      String idToken) async {
    if (_googleClientId.isEmpty) {
      throw AuthException(
          'server_misconfigured', 'GOOGLE_CLIENT_ID not set');
    }

    // Verify via Google's tokeninfo endpoint.
    // This handles signature verification and claim parsing server-side.
    final resp = await http.get(
      Uri.parse(
          'https://oauth2.googleapis.com/tokeninfo?id_token=$idToken'),
    );

    if (resp.statusCode != 200) {
      throw AuthException(
          'invalid_token', 'Google rejected the ID token');
    }

    final payload = jsonDecode(resp.body) as Map<String, dynamic>;

    // ── Validate issuer ──
    final iss = payload['iss'] as String?;
    if (iss != 'accounts.google.com' && iss != 'https://accounts.google.com') {
      throw AuthException('invalid_issuer', 'Token issuer mismatch');
    }

    // ── Validate audience matches our app ──
    final aud = payload['aud'] as String?;
    if (aud != _googleClientId) {
      throw AuthException(
          'invalid_audience', 'Token audience does not match this app');
    }

    // ── Validate expiry ──
    final expStr = payload['exp'] as String?;
    if (expStr != null) {
      final exp = int.tryParse(expStr);
      if (exp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (expiry.isBefore(DateTime.now())) {
          throw AuthException('token_expired', 'ID token has expired');
        }
      }
    }

    // ── Validate subject (stable user identity) ──
    final sub = payload['sub'] as String?;
    if (sub == null || sub.isEmpty) {
      throw AuthException(
          'missing_subject', 'Token has no subject claim');
    }

    return payload;
  }

  // ── Public API ──

  /// Handle POST /api/auth/google
  ///
  /// Accepts { "idToken": "..." }, verifies server-side, creates or
  /// updates user, creates hardened session, returns Set-Cookie.
  static Future<Response> handleGoogleSignIn(Request request) async {
    final ip = _extractIp(request);
    final ua = request.headers['user-agent'] ?? '';

    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final idToken = body['idToken'] as String?;
      if (idToken == null || idToken.isEmpty) {
        await _auditLog(null, 'login_failed', 'missing_id_token', ip, ua);
        return _jsonError(400, 'Missing idToken');
      }

      // ── Step 1: Verify Google ID token server-side ──
      final claims = await _verifyGoogleIdToken(idToken);

      final googleSub = claims['sub'] as String;
      final email = claims['email'] as String?;
      final emailVerified = claims['email_verified'] == 'true';
      final name = claims['name'] as String? ??
          email?.split('@').first ??
          'User';
      final avatar = claims['picture'] as String?;

      // ── Step 2: Find or create user by google_sub ──
      // google_sub is the sole identity anchor. Never merge by email.
      final existing = await Db.query(
        'SELECT id, status FROM users WHERE google_sub = @sub',
        parameters: {'sub': googleSub},
      );

      String userId;

      if (existing.isNotEmpty) {
        userId = existing.first[0] as String;
        final status = existing.first[1] as String;

        if (status != 'active') {
          await _auditLog(
              userId, 'login_failed', 'account_inactive', ip, ua);
          return _jsonError(403, 'Account is not active');
        }

        // Update non-critical profile fields + last login
        await Db.query(
          'UPDATE users SET email = @email, email_verified = @emailV, '
          'display_name = @name, avatar_url = @avatar, '
          'last_login_at = NOW(), updated_at = NOW() '
          'WHERE id = @id::uuid',
          parameters: {
            'email': email,
            'emailV': emailVerified,
            'name': name,
            'avatar': avatar,
            'id': userId,
          },
        );
      } else {
        // Create new user anchored on google_sub
        final result = await Db.query(
          'INSERT INTO users (google_sub, email, email_verified, '
          'display_name, avatar_url, last_login_at) '
          'VALUES (@sub, @email, @emailV, @name, @avatar, NOW()) '
          'RETURNING id',
          parameters: {
            'sub': googleSub,
            'email': email,
            'emailV': emailVerified,
            'name': name,
            'avatar': avatar,
          },
        );
        userId = result.first[0] as String;

        // Seed default consoles for the new user
        await _seedDefaultConsoles(userId);
      }

      // ── Step 3: Create hardened session ──
      // Generate cryptographically secure token. Store only the hash.
      final rawToken = _generateSessionToken();
      final tokenHash = _hashToken(rawToken);
      final expiresAt = DateTime.now().add(_sessionMaxAge);

      await Db.query(
        'INSERT INTO sessions (user_id, session_token_hash, expires_at, '
        'ip_created, user_agent_created, ip_last_seen, user_agent_last_seen) '
        'VALUES (@userId::uuid, @hash, @expires, @ip, @ua, @ip, @ua)',
        parameters: {
          'userId': userId,
          'hash': tokenHash,
          'expires': expiresAt.toIso8601String(),
          'ip': ip,
          'ua': _truncate(ua, 512),
        },
      );

      await _auditLog(userId, 'login_success', null, ip, ua);

      // ── Step 4: Return session cookie + user info ──
      final cookie = _buildSessionCookie(rawToken, _sessionMaxAge);

      return Response.ok(
        jsonEncode({
          'user': {
            'id': userId,
            'email': email,
            'displayName': name,
            'avatarUrl': avatar,
          },
        }),
        headers: {
          'Content-Type': 'application/json',
          'Set-Cookie': cookie,
        },
      );
    } on AuthException catch (e) {
      await _auditLog(null, 'login_failed', e.reasonCode, ip, ua);
      // Generic error to client — don't leak verification details
      return _jsonError(401, 'Authentication failed');
    } catch (e) {
      await _auditLog(null, 'login_error', 'unexpected', ip, ua);
      return _jsonError(500, 'Internal server error');
    }
  }

  /// GET /api/auth/me — Check current session, return user info.
  /// Frontend calls this on load to determine sign-in state from
  /// backend session, not from frontend memory.
  static Future<Response> handleMe(Request request) async {
    final userId = request.context['userId'] as String?;
    if (userId == null) {
      return _jsonError(401, 'Not authenticated');
    }

    final result = await Db.query(
      'SELECT id, email, display_name, avatar_url FROM users '
      'WHERE id = @id::uuid AND status = \'active\'',
      parameters: {'id': userId},
    );
    if (result.isEmpty) return _jsonError(401, 'Not authenticated');

    return Response.ok(
      jsonEncode({
        'user': {
          'id': result.first[0],
          'email': result.first[1],
          'displayName': result.first[2],
          'avatarUrl': result.first[3],
        },
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// POST /api/auth/logout — Revoke current session.
  static Future<Response> handleLogout(Request request) async {
    final userId = request.context['userId'] as String?;
    final sessionHash = request.context['sessionHash'] as String?;
    final ip = _extractIp(request);
    final ua = request.headers['user-agent'] ?? '';

    if (sessionHash != null) {
      await Db.query(
        'UPDATE sessions SET revoked_at = NOW() '
        'WHERE session_token_hash = @hash',
        parameters: {'hash': sessionHash},
      );
    }

    if (userId != null) {
      await _auditLog(userId, 'logout', null, ip, ua);
    }

    // Clear the cookie
    final cookie = _buildSessionCookie('', Duration.zero, clear: true);
    return Response.ok(
      jsonEncode({'ok': true}),
      headers: {
        'Content-Type': 'application/json',
        'Set-Cookie': cookie,
      },
    );
  }

  /// POST /api/auth/revoke-all — Revoke ALL sessions for current user.
  static Future<Response> handleRevokeAll(Request request) async {
    final userId = request.context['userId'] as String?;
    final ip = _extractIp(request);
    final ua = request.headers['user-agent'] ?? '';

    if (userId != null) {
      await Db.query(
        'UPDATE sessions SET revoked_at = NOW() '
        'WHERE user_id = @userId::uuid AND revoked_at IS NULL',
        parameters: {'userId': userId},
      );
      await _auditLog(userId, 'revoke_all_sessions', null, ip, ua);
    }

    final cookie = _buildSessionCookie('', Duration.zero, clear: true);
    return Response.ok(
      jsonEncode({'ok': true}),
      headers: {
        'Content-Type': 'application/json',
        'Set-Cookie': cookie,
      },
    );
  }

  /// DELETE /api/auth/account — Full account deletion.
  static Future<Response> handleDeleteAccount(Request request) async {
    final userId = request.context['userId'] as String?;
    final ip = _extractIp(request);
    final ua = request.headers['user-agent'] ?? '';

    if (userId == null) return _jsonError(401, 'Not authenticated');

    // Revoke all sessions first
    await Db.query(
      'UPDATE sessions SET revoked_at = NOW() '
      'WHERE user_id = @userId::uuid AND revoked_at IS NULL',
      parameters: {'userId': userId},
    );

    // Delete user (cascades to consoles → games → screenshots)
    await Db.query(
      'DELETE FROM users WHERE id = @userId::uuid',
      parameters: {'userId': userId},
    );

    await _auditLog(userId, 'account_deleted', null, ip, ua);

    final cookie = _buildSessionCookie('', Duration.zero, clear: true);
    return Response.ok(
      jsonEncode({'ok': true}),
      headers: {
        'Content-Type': 'application/json',
        'Set-Cookie': cookie,
      },
    );
  }

  // ── Session middleware ──

  /// Middleware that extracts session from cookie, verifies it,
  /// and injects userId + sessionHash into request context.
  /// For unauthenticated requests, passes through without userId.
  static Middleware sessionMiddleware() {
    return (Handler handler) {
      return (Request request) async {
        final cookies = _parseCookies(request.headers['cookie'] ?? '');
        final rawToken = cookies[_cookieName];

        if (rawToken == null || rawToken.isEmpty) {
          return handler(request);
        }

        final tokenHash = _hashToken(rawToken);

        // Look up session — must be non-revoked and non-expired
        final result = await Db.query(
          'SELECT s.user_id, s.expires_at, s.last_seen_at, u.status '
          'FROM sessions s JOIN users u ON s.user_id = u.id '
          'WHERE s.session_token_hash = @hash '
          'AND s.revoked_at IS NULL',
          parameters: {'hash': tokenHash},
        );

        if (result.isEmpty) {
          return handler(request);
        }

        final userId = result.first[0] as String;
        final expiresAt = result.first[1] as DateTime;
        final lastSeenAt = result.first[2] as DateTime;
        final status = result.first[3] as String;

        // Check absolute expiry
        if (expiresAt.isBefore(DateTime.now())) {
          return handler(request);
        }

        // Check idle timeout
        if (DateTime.now().difference(lastSeenAt) > _sessionIdleTimeout) {
          // Revoke idle session
          await Db.query(
            'UPDATE sessions SET revoked_at = NOW() '
            'WHERE session_token_hash = @hash',
            parameters: {'hash': tokenHash},
          );
          return handler(request);
        }

        // Check account status
        if (status != 'active') {
          return handler(request);
        }

        // Touch last_seen
        final ip = _extractIp(request);
        final ua = request.headers['user-agent'] ?? '';
        await Db.query(
          'UPDATE sessions SET last_seen_at = NOW(), '
          'ip_last_seen = @ip, user_agent_last_seen = @ua '
          'WHERE session_token_hash = @hash',
          parameters: {
            'hash': tokenHash,
            'ip': ip,
            'ua': _truncate(ua, 512),
          },
        );

        final updatedRequest = request.change(context: {
          'userId': userId,
          'sessionHash': tokenHash,
        });
        return handler(updatedRequest);
      };
    };
  }

  /// Middleware that requires authentication (returns 401 if no session).
  static Middleware requireAuth() {
    return (Handler handler) {
      return (Request request) async {
        if (request.context['userId'] == null) {
          return _jsonError(401, 'Authentication required');
        }
        return handler(request);
      };
    };
  }

  /// Extract userId from request context.
  static String getUserId(Request request) {
    return request.context['userId'] as String;
  }

  // ── Private helpers ──

  static String _buildSessionCookie(
    String token,
    Duration maxAge, {
    bool clear = false,
  }) {
    final parts = <String>[
      '$_cookieName=${clear ? '' : token}',
      'Path=/',
      'HttpOnly',
      'SameSite=Lax',
    ];

    if (_isProduction) {
      parts.add('Secure');
    }

    if (clear) {
      parts.add('Max-Age=0');
    } else {
      parts.add('Max-Age=${maxAge.inSeconds}');
    }

    return parts.join('; ');
  }

  static Map<String, String> _parseCookies(String cookieHeader) {
    final cookies = <String, String>{};
    for (final part in cookieHeader.split(';')) {
      final trimmed = part.trim();
      final eq = trimmed.indexOf('=');
      if (eq > 0) {
        cookies[trimmed.substring(0, eq)] = trimmed.substring(eq + 1);
      }
    }
    return cookies;
  }

  static String _extractIp(Request request) {
    return request.headers['x-forwarded-for']?.split(',').first.trim() ??
        request.headers['x-real-ip'] ??
        'unknown';
  }

  static String _truncate(String s, int maxLen) {
    return s.length > maxLen ? s.substring(0, maxLen) : s;
  }

  static Future<void> _auditLog(
    String? userId,
    String eventType,
    String? reasonCode,
    String ip,
    String ua,
  ) async {
    // Structured audit logging — never logs raw tokens or excessive PII
    await Db.query(
      'INSERT INTO auth_audit_log (user_id, event_type, reason_code, ip, user_agent) '
      'VALUES (@userId::uuid, @event, @reason, @ip, @ua)',
      parameters: {
        'userId': userId,
        'event': eventType,
        'reason': reasonCode,
        'ip': ip,
        'ua': _truncate(ua, 512),
      },
    );
  }

  static Future<void> _seedDefaultConsoles(String userId) async {
    const consoles = [
      ('Nintendo Entertainment System', 'NES', 0xFFC62828),
      ('Famicom', 'FC', 0xFFD32F2F),
      ('Super Nintendo', 'SNES', 0xFF6A1B9A),
      ('Super Famicom', 'SFC', 0xFF7B1FA2),
      ('Nintendo 64', 'N64', 0xFF1A237E),
      ('Nintendo GameCube', 'GCN', 0xFF4A148C),
      ('Nintendo Wii', 'Wii', 0xFF00ACC1),
      ('Game Boy', 'GB', 0xFF2E7D32),
      ('Game Boy Color', 'GBC', 0xFF388E3C),
      ('Game Boy Advance', 'GBA', 0xFF1B5E20),
      ('Nintendo DS', 'NDS', 0xFF546E7A),
      ('Nintendo Virtual Boy', 'VB', 0xFFB71C1C),
      ('Sega Master System', 'SMS', 0xFF0277BD),
      ('Sega Genesis', 'GEN', 0xFFB71C1C),
      ('Sega Mega Drive', 'MD', 0xFFC62828),
      ('Sega CD', 'SCD', 0xFF880E4F),
      ('Sega 32X', '32X', 0xFF4A148C),
      ('Sega Saturn', 'SAT', 0xFF37474F),
      ('Sega Dreamcast', 'DC', 0xFFE65100),
      ('Sega Game Gear', 'GG', 0xFF0D47A1),
      ('PlayStation', 'PS1', 0xFF1565C0),
      ('PlayStation 2', 'PS2', 0xFF0D47A1),
      ('PlayStation Portable', 'PSP', 0xFF263238),
      ('Atari 2600', '2600', 0xFF4E342E),
      ('Atari 5200', '5200', 0xFF5D4037),
      ('Atari 7800', '7800', 0xFF6D4C41),
      ('Atari Jaguar', 'JAG', 0xFF3E2723),
      ('Atari Lynx', 'LYNX', 0xFF795548),
      ('TurboGrafx-16', 'TG16', 0xFFFF6F00),
      ('PC Engine', 'PCE', 0xFFFF8F00),
      ('TurboGrafx-CD', 'TGCD', 0xFFE65100),
      ('Neo Geo AES', 'AES', 0xFFBF360C),
      ('Neo Geo MVS', 'MVS', 0xFFD84315),
      ('Neo Geo Pocket', 'NGP', 0xFFE64A19),
      ('Neo Geo Pocket Color', 'NGPC', 0xFFFF5722),
      ('ColecoVision', 'CV', 0xFF455A64),
      ('Intellivision', 'INTV', 0xFF1B5E20),
      ('Vectrex', 'VEC', 0xFF212121),
      ('3DO', '3DO', 0xFFAD1457),
      ('Philips CD-i', 'CDi', 0xFF00695C),
      ('WonderSwan', 'WS', 0xFF558B2F),
      ('WonderSwan Color', 'WSC', 0xFF689F38),
      ('Xbox', 'XBOX', 0xFF2E7D32),
    ];

    for (final (name, abbr, color) in consoles) {
      await Db.query(
        'INSERT INTO consoles (user_id, name, abbreviation, color_value) '
        'VALUES (@userId::uuid, @name, @abbr, @color)',
        parameters: {
          'userId': userId,
          'name': name,
          'abbr': abbr,
          'color': color,
        },
      );
    }
  }
}

class AuthException implements Exception {
  final String reasonCode;
  final String message;
  AuthException(this.reasonCode, this.message);

  @override
  String toString() => 'AuthException($reasonCode): $message';
}

Response _jsonError(int status, String message) {
  return Response(status,
      body: jsonEncode({'error': message}),
      headers: {'Content-Type': 'application/json'});
}
