import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/api_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/mobile/mobile_home_screen.dart';
import 'screens/web/sign_in_screen.dart';
import 'theme/app_theme.dart';

/// Web entry point — uses ApiRepository (REST API + PostgreSQL)
/// and Google Sign-In for authentication.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // API base URL — configure via environment or default to same origin
  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  final apiRepo = ApiRepository(baseUrl: apiBaseUrl);

  runApp(Stash64WebApp(apiRepo: apiRepo));
}

class Stash64WebApp extends StatelessWidget {
  final ApiRepository apiRepo;

  const Stash64WebApp({super.key, required this.apiRepo});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiRepo)..checkSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => GameProvider(apiRepo)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..initialize(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Stash 64',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(settings.uiScale),
                ),
                child: IconTheme(
                  data: IconThemeData(
                    size: 24 * settings.uiScale,
                  ),
                  child: child!,
                ),
              );
            },
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

/// Shows sign-in screen if not authenticated, otherwise the app.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentGold),
        ),
      );
    }

    if (!auth.isAuthenticated) {
      return const SignInScreen();
    }

    // Authenticated — responsive layout for web
    return const _ResponsiveWebHome();
  }
}

/// Responsive layout for web: desktop grid on wide screens,
/// mobile list on narrow screens. No kiosk features (attract mode,
/// cursor hiding) since those are desktop-app-specific.
class _ResponsiveWebHome extends StatelessWidget {
  const _ResponsiveWebHome();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return const MobileHomeScreen();
    }
    // Desktop grid layout (same as kiosk but without KioskWrapper)
    return const HomeScreen();
  }
}
