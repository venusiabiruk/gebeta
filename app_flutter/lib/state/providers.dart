import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_service.dart';
import '../services/saved_game_store.dart';
import '../services/settings_store.dart';
import '../services/sound_service.dart';
import '../services/stats_store.dart';
import 'fakes.dart';
import 'game_controller.dart';
import 'game_ui_state.dart';

final gameControllerProvider =
    NotifierProvider<GameController, GameUiState>(GameController.new);

// Until Person 3's real classes land, these default to in-memory fakes, so the
// app and the tests run without overrides. When a real class exists, replace
// the body, for example: Provider<SettingsStore>((ref) => SettingsStore()).
final aiServiceProvider = Provider<AiService>((ref) => FakeAiService());
final savedGameStoreProvider =
    Provider<SavedGameStore>((ref) => FakeSavedGameStore());
final statsStoreProvider = Provider<StatsStore>((ref) => FakeStatsStore());
final settingsStoreProvider =
    Provider<SettingsStore>((ref) => FakeSettingsStore());
final soundServiceProvider =
    Provider<SoundService>((ref) => FakeSoundService());
