import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database_helper.dart';
import 'data/image_cache_helper.dart';
import 'data/sqlite_repository.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/mobile/mobile_home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/kiosk_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.initializeFfi();

  // Clean stale image cache on startup
  ImageCacheHelper.clearOldCache();

  runApp(const Stash64App());
}

class Stash64App extends StatelessWidget {
  const Stash64App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GameProvider(SqliteRepository())..initialize(),
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
            home: const _ResponsiveHome(),
          );
        },
      ),
    );
  }
}

/// Picks between mobile UI and kiosk/desktop UI based on screen width.
/// Screens under 600dp get the mobile layout; wider screens get
/// the kiosk grid layout with attract mode.
class _ResponsiveHome extends StatelessWidget {
  const _ResponsiveHome();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return const MobileHomeScreen();
    }
    return const KioskWrapper(child: HomeScreen());
  }
}
