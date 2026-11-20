import 'package:flutter/material.dart';

import 'board_debug_screen.dart';

/// Entry point for the board debug screen (not the app's main.dart):
///   flutter run -t lib/ui/board/board_debug_main.dart -d chrome
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BoardDebugScreen(),
    ),
  );
}