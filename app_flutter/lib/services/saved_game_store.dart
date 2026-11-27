import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../ai/levels.dart';
import '../engine/game_state.dart';
import '../state/game_ui_state.dart';

/// Everything needed to restore a game.
class GameSnapshot {
  const GameSnapshot({
    required this.state,
    required this.config,
    required this.humanPlayer,
    required this.nextFirstPlayer,
  });

  final GameState state;
  final GameConfig config;
  final int? humanPlayer;
  final int nextFirstPlayer;

  Map<String, dynamic> toJson() => {
        'state': state.toJson(),
        'mode': config.mode.name,
        'level': config.level?.name,
        'firstMove': config.firstMove.name,
        'humanPlayer': humanPlayer,
        'nextFirstPlayer': nextFirstPlayer,
      };

  factory GameSnapshot.fromJson(Map<String, dynamic> json) {
    return GameSnapshot(
      state: GameState.fromJson(
        json['state'] as Map<String, dynamic>,
      ),
      config: GameConfig(
        mode: GameMode.values.byName(json['mode'] as String),
        level: json['level'] == null
            ? null
            : Level.values.byName(json['level'] as String),
        firstMove: FirstMove.values.byName(
          json['firstMove'] as String,
        ),
      ),
      humanPlayer: json['humanPlayer'] as int?,
      nextFirstPlayer: json['nextFirstPlayer'] as int,
    );
  }
}

/// Contract for saving and restoring a game.
abstract class SavedGameStore {
  Future<void> save(GameSnapshot snapshot);

  Future<GameSnapshot?> load();

  Future<void> clear();
}

/// Persistent saved-game implementation using SharedPreferences.
class SharedPreferencesSavedGameStore implements SavedGameStore {
  SharedPreferencesSavedGameStore(this._preferences);

  final Future<SharedPreferences> _preferences;

  static const _savedGameKey = 'gebeta_saved_game';

  @override
  Future<void> save(GameSnapshot snapshot) async {
    final preferences = await _preferences;
    await preferences.setString(
      _savedGameKey,
      jsonEncode(snapshot.toJson()),
    );
  }

  @override
  Future<GameSnapshot?> load() async {
    final preferences = await _preferences;
    final raw = preferences.getString(_savedGameKey);

    if (raw == null) return null;

    try {
      return GameSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    final preferences = await _preferences;
    await preferences.remove(_savedGameKey);
  }
}
