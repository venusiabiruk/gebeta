import '../ai/levels.dart';
import '../services/saved_game_store.dart';
import '../services/settings_store.dart';
import '../services/stats_store.dart';

/// In-memory settings store for tests.
class FakeSettingsStore implements SettingsStore {
  bool _sound = true;
  bool _music = false;
  bool _haptics = true;
  AnimationSpeed _speed = AnimationSpeed.normal;
  BoardTheme _board = BoardTheme.darkWood;

  @override
  Future<bool> soundEnabled() async => _sound;

  @override
  Future<bool> musicEnabled() async => _music;

  @override
  Future<bool> hapticsEnabled() async => _haptics;

  @override
  Future<AnimationSpeed> animationSpeed() async => _speed;

  @override
  Future<BoardTheme> boardTheme() async => _board;

  @override
  Future<void> setSoundEnabled(bool value) async {
    _sound = value;
  }

  @override
  Future<void> setMusicEnabled(bool value) async {
    _music = value;
  }

  @override
  Future<void> setHapticsEnabled(bool value) async {
    _haptics = value;
  }

  @override
  Future<void> setAnimationSpeed(AnimationSpeed value) async {
    _speed = value;
  }

  @override
  Future<void> setBoardTheme(BoardTheme value) async {
    _board = value;
  }
}

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

  @override
  Future<void> reset() async {
    _counts.clear();
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
