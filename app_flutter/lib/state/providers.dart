import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai/ai_service.dart';
import '../services/saved_game_store.dart';
import '../services/settings_store.dart';
import '../services/sound_service.dart';
import '../services/stats_store.dart';
import 'game_controller.dart';
import 'game_ui_state.dart';

/// Random number source. Tests can replace this with a seeded generator.
final randomProvider = Provider<Random>((ref) => Random());

/// AI service used by the game.
final aiServiceProvider = Provider<AiService>(
  (ref) => FakeAiService(),
);

/// Persistent game statistics.
final statsStoreProvider = Provider<StatsStore>(
  (ref) => SharedPreferencesStatsStore(
    SharedPreferences.getInstance(),
  ),
);

/// Persistent saved game.
final savedGameStoreProvider = Provider<SavedGameStore>(
  (ref) => SharedPreferencesSavedGameStore(
    SharedPreferences.getInstance(),
  ),
);

/// Persistent player settings.
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => SharedPreferencesSettingsStore(
    SharedPreferences.getInstance(),
  ),
);

/// Sound service. Replace the no-op implementation when audio is implemented.
final soundServiceProvider = Provider<SoundService>(
  (ref) => NoopSoundService(),
);

/// Main game controller.
final gameControllerProvider = NotifierProvider<GameController, GameUiState>(
  GameController.new,
);

/// The saved game, if there is one. Home reads it to decide about Resume.
final savedGameProvider = FutureProvider.autoDispose<GameSnapshot?>((ref) {
  return ref.read(savedGameStoreProvider).load();
});
