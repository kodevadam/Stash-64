import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database_helper.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/kiosk_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.initializeFfi();

  runApp(const Stash64App());
}

class Stash64App extends StatelessWidget {
  const Stash64App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..initialize()),
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
            home: const KioskWrapper(
              child: HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}
