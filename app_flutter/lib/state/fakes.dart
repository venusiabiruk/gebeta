import '../ai/levels.dart';
import '../services/saved_game_store.dart';
import '../services/stats_store.dart';

/// In-memory statistics store for tests.
class FakeStatsStore implements StatsStore {
  final Map<Level, Map<Outcome, int>> _counts = {};
  int? _lastFirstPlayer;

  @override
  Future<StatsData> load() async {
    return StatsData(
      counts: {
        for (final entry in _counts.entries)
          entry.key: Map<Outcome, int>.from(entry.value),
      },
    );
  }

  @override
  Future<int?> lastFirstPlayer() async => _lastFirstPlayer;

  @override
  Future<void> setLastFirstPlayer(int player) async {
    _lastFirstPlayer = player;
  }

  @override
  Future<void> record(Level level, Outcome outcome) async {
    final levelCounts = _counts.putIfAbsent(level, () => {});
    levelCounts[outcome] = (levelCounts[outcome] ?? 0) + 1;
  }
}

/// In-memory saved-game store for tests.
class FakeSavedGameStore implements SavedGameStore {
  GameSnapshot? _snapshot;

  @override
  Future<void> save(GameSnapshot snapshot) async {
    _snapshot = snapshot;
  }

  @override
  Future<GameSnapshot?> load() async => _snapshot;

  @override
  Future<void> clear() async {
    _snapshot = null;
  }
}
