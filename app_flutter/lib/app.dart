import 'package:flutter/material.dart';

import 'ui/screens/game_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/how_to_play_screen.dart';
import 'ui/screens/opponent_select_screen.dart';
import 'ui/screens/palette.dart';
import 'ui/screens/result_screen.dart';
import 'ui/screens/routes.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/splash_screen.dart';

/// The app theme: Nunito for text, Baloo 2 for titles and buttons.
/// The font files live in assets/fonts and are registered in pubspec.yaml.
ThemeData gebetaTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Nunito',
    colorScheme: ColorScheme.fromSeed(
      seedColor: GebetaColors.gold,
      brightness: Brightness.dark,
    ).copyWith(primary: GebetaColors.gold, onPrimary: GebetaColors.ink),
    scaffoldBackgroundColor: GebetaColors.woodDark,
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge
          ?.copyWith(fontFamily: 'Baloo2', fontWeight: FontWeight.w800),
      headlineMedium: base.textTheme.headlineMedium
          ?.copyWith(fontFamily: 'Baloo2', fontWeight: FontWeight.w800),
      titleLarge: base.textTheme.titleLarge
          ?.copyWith(fontFamily: 'Baloo2', fontWeight: FontWeight.w700),
      labelLarge: base.textTheme.labelLarge
          ?.copyWith(fontFamily: 'Baloo2', fontWeight: FontWeight.w700),
    ),
  );
}

class GebetaApp extends StatelessWidget {
  const GebetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gebeta',
      debugShowCheckedModeBanner: false,
      theme: gebetaTheme(),
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (_) => const SplashScreen(),
        Routes.home: (_) => const HomeScreen(),
        Routes.opponent: (_) => const OpponentSelectScreen(),
        Routes.game: (_) => const GameScreen(),
        Routes.result: (_) => const ResultScreen(),
        Routes.howToPlay: (_) => const HowToPlayScreen(),
        Routes.settings: (_) => const SettingsScreen(),
      },
    );
  }
}
