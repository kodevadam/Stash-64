import 'dart:io';

import 'package:shelf/shelf.dart';

/// Security middleware: headers, CSRF protection, rate limiting.
class Security {
  /// In-memory rate limiter for auth endpoints.
  /// Maps IP → list of request timestamps (last 15 minutes).
  static final Map<String, List<DateTime>> _authAttempts = {};

  /// Max auth attempts per IP per 15-minute window.
  static const _maxAuthAttempts = 20;
  static const _authWindow = Duration(minutes: 15);

  /// Add standard security headers to all responses.
  static Middleware securityHeaders() {
    return (Handler handler) {
      return (Request request) async {
        final response = await handler(request);
        return response.change(headers: {
          'X-Content-Type-Options': 'nosniff',
          'X-Frame-Options': 'DENY',
          'X-XSS-Protection': '1; mode=block',
          'Referrer-Policy': 'strict-origin-when-cross-origin',
          if (_isProduction)
            'Strict-Transport-Security':
                'max-age=63072000; includeSubDomains; preload',
        });
      };
    };
  }

  /// CSRF defense for state-changing requests.
  /// Validates Origin header matches allowed origins.
  static Middleware csrfProtection() {
    return (Handler handler) {
      return (Request request) async {
        // Only check state-changing methods
        final method = request.method.toUpperCase();
        if (method == 'GET' || method == 'HEAD' || method == 'OPTIONS') {
          return handler(request);
        }

        final origin = request.headers['origin'];
        final referer = request.headers['referer'];

        // In development, allow localhost
        if (!_isProduction) {
          return handler(request);
        }

        // In production, validate origin against allowed list
        final allowedOrigins = _getAllowedOrigins();
        if (origin != null && allowedOrigins.contains(origin)) {
          return handler(request);
        }

        // Fall back to referer check
        if (referer != null) {
          final refererUri = Uri.tryParse(referer);
          if (refererUri != null) {
            final refererOrigin =
                '${refererUri.scheme}://${refererUri.host}';
            if (allowedOrigins.contains(refererOrigin)) {
              return handler(request);
            }
          }
        }

        // No valid origin — reject
        return Response(403,
            body: '{"error":"CSRF validation failed"}',
            headers: {'Content-Type': 'application/json'});
      };
    };
  }

  /// Rate limiting for auth endpoints.
  static Middleware rateLimitAuth() {
    return (Handler handler) {
      return (Request request) async {
        final path = request.url.path;
        if (!path.startsWith('api/auth/')) {
          return handler(request);
        }

        final ip = _extractIp(request);
        final now = DateTime.now();

        // Clean old entries
        _authAttempts[ip]?.removeWhere(
            (t) => now.difference(t) > _authWindow);

        final attempts = _authAttempts[ip] ?? [];
        if (attempts.length >= _maxAuthAttempts) {
          return Response(429,
              body: '{"error":"Too many authentication attempts"}',
              headers: {
                'Content-Type': 'application/json',
                'Retry-After': '900',
              });
        }

        attempts.add(now);
        _authAttempts[ip] = attempts;

        return handler(request);
      };
    };
  }

  /// Enforce HTTPS in production by checking X-Forwarded-Proto.
  static Middleware httpsEnforcement() {
    return (Handler handler) {
      return (Request request) async {
        if (!_isProduction) return handler(request);

        final proto = request.headers['x-forwarded-proto'];
        if (proto != null && proto != 'https') {
          return Response(301, headers: {
            'Location':
                'https://${request.headers["host"]}${request.requestedUri.path}',
          });
        }
        return handler(request);
      };
    };
  }

  static bool get _isProduction =>
      Platform.environment['DART_ENV'] == 'production';

  static List<String> _getAllowedOrigins() {
    final origins = Platform.environment['ALLOWED_ORIGINS'] ?? '';
    return origins.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  static String _extractIp(Request request) {
    return request.headers['x-forwarded-for']?.split(',').first.trim() ??
        request.headers['x-real-ip'] ??
        'unknown';
  }
}
