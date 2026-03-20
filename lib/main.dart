import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database_helper.dart';
import 'providers/game_provider.dart';
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
    return ChangeNotifierProvider(
      create: (_) => GameProvider()..initialize(),
      child: MaterialApp(
        title: 'Stash 64',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const KioskWrapper(
          child: HomeScreen(),
        ),
      ),
    );
  }
}
