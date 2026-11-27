import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../ai/levels.dart';

/// The possible outcomes of a game.
enum Outcome { win, loss, draw }

/// Statistics grouped by difficulty and game outcome.
class StatsData {
  const StatsData({this.counts = const {}});

  final Map<Level, Map<Outcome, int>> counts;

  int count(Level level, Outcome outcome) => counts[level]?[outcome] ?? 0;

  factory StatsData.fromJson(Map<String, dynamic> json) {
    final counts = <Level, Map<Outcome, int>>{};

    for (final level in Level.values) {
      final levelData = json[level.name];
      if (levelData is! Map) continue;

      final outcomes = <Outcome, int>{};

      for (final outcome in Outcome.values) {
        final value = levelData[outcome.name];
        if (value is int) {
          outcomes[outcome] = value;
        }
      }

      counts[level] = outcomes;
    }

    return StatsData(counts: counts);
  }

  Map<String, dynamic> toJson() => {
        for (final entry in counts.entries)
          entry.key.name: {
            for (final outcome in entry.value.entries)
              outcome.key.name: outcome.value,
          },
      };
}

/// Contract for reading and updating game statistics.
abstract class StatsStore {
  Future<StatsData> load();

  Future<int?> lastFirstPlayer();

  Future<void> setLastFirstPlayer(int player);

  Future<void> record(Level level, Outcome outcome);
}

/// Persistent statistics implementation using SharedPreferences.
class SharedPreferencesStatsStore implements StatsStore {
  SharedPreferencesStatsStore(this._preferences);

  final Future<SharedPreferences> _preferences;

  static const _statsKey = 'gebeta_stats';
  static const _lastFirstPlayerKey = 'gebeta_last_first_player';

  @override
  Future<StatsData> load() async {
    final preferences = await _preferences;
    final raw = preferences.getString(_statsKey);

    if (raw == null) return const StatsData();

    try {
      return StatsData.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const StatsData();
    }
  }

  @override
  Future<int?> lastFirstPlayer() async {
    final preferences = await _preferences;
    return preferences.getInt(_lastFirstPlayerKey);
  }

  @override
  Future<void> setLastFirstPlayer(int player) async {
    if (player != 0 && player != 1) {
      throw ArgumentError.value(player, 'player', 'Must be 0 or 1');
    }

    final preferences = await _preferences;
    await preferences.setInt(_lastFirstPlayerKey, player);
  }

  @override
  Future<void> record(Level level, Outcome outcome) async {
    final preferences = await _preferences;
    final stats = await load();

    final updated = <Level, Map<Outcome, int>>{
      for (final entry in stats.counts.entries)
        entry.key: Map<Outcome, int>.from(entry.value),
    };

    final levelCounts = updated.putIfAbsent(level, () => {});
    levelCounts[outcome] = (levelCounts[outcome] ?? 0) + 1;

    await preferences.setString(
      _statsKey,
      jsonEncode(StatsData(counts: updated).toJson()),
    );
  }
}
