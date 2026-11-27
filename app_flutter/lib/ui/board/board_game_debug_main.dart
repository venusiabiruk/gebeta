import 'package:flutter/material.dart';

import 'board_game_debug_screen.dart';

/// Entry point for the Flame board debug screen (not the app's main.dart):
///   flutter run -t lib/ui/board/board_game_debug_main.dart -d linux
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BoardGameDebugScreen(),
    ),
  );
}
