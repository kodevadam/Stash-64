import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import '../lib/src/auth.dart';
import '../lib/src/db.dart';
import '../lib/src/routes.dart';
import '../lib/src/security.dart';

void main(List<String> args) async {
  // Configuration from environment variables — no secrets in source control
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final dbHost = Platform.environment['DB_HOST'] ?? 'localhost';
  final dbPort =
      int.tryParse(Platform.environment['DB_PORT'] ?? '') ?? 5432;
  final dbName = Platform.environment['DB_NAME'] ?? 'stash64';
  final dbUser = Platform.environment['DB_USER'] ?? 'stash64';
  final dbPassword = Platform.environment['DB_PASSWORD'] ?? 'stash64';

  // Initialize database and run migrations
  await Db.init(
    host: dbHost,
    port: dbPort,
    database: dbName,
    username: dbUser,
    password: dbPassword,
  );
  print('Database connected and migrated.');

  // Build handler with layered security middleware
  final router = buildRouter();

  // CORS configuration — restrict origins in production
  final allowedOrigins = Platform.environment['ALLOWED_ORIGINS'] ?? '*';
  final corsOverrides = {
    ACCESS_CONTROL_ALLOW_ORIGIN: allowedOrigins,
    ACCESS_CONTROL_ALLOW_CREDENTIALS: 'true',
  };

  final handler = Pipeline()
      // Layer 1: HTTPS enforcement (production only)
      .addMiddleware(Security.httpsEnforcement())
      // Layer 2: Security headers (HSTS, X-Frame-Options, etc.)
      .addMiddleware(Security.securityHeaders())
      // Layer 3: CORS
      .addMiddleware(corsHeaders(headers: corsOverrides))
      // Layer 4: Rate limiting on auth endpoints
      .addMiddleware(Security.rateLimitAuth())
      // Layer 5: CSRF protection for state-changing requests
      .addMiddleware(Security.csrfProtection())
      // Layer 6: Session extraction from cookie (for all requests)
      .addMiddleware(Auth.sessionMiddleware())
      // Layer 7: Request logging
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // Start server
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Stash 64 API server running on port ${server.port}');
  print('Environment: ${Platform.environment['DART_ENV'] ?? 'development'}');
}
