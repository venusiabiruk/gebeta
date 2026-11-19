import '../ai/ai_service.dart';
import '../engine/engine.dart';
import '../services/saved_game_store.dart';
import '../services/settings_store.dart';
import '../services/sound_service.dart';
import '../services/stats_store.dart';

class FakeSavedGameStore implements SavedGameStore {
  GameSnapshot? _saved;

  @override
  Future<void> save(GameSnapshot snapshot) async => _saved = snapshot;

  @override
  Future<GameSnapshot?> load() async => _saved;

  @override
  Future<void> clear() async => _saved = null;
}

class FakeStatsStore implements StatsStore {
  final Map<Level, Map<Outcome, int>> _counts = {};
  int? _lastFirst;

  @override
  Future<Stats> load() async => Stats({
        for (final e in _counts.entries) e.key: Map<Outcome, int>.of(e.value),
      });

  @override
  Future<void> record(Level level, Outcome outcome) async {
    final byOutcome = _counts.putIfAbsent(level, () => <Outcome, int>{});
    byOutcome[outcome] = (byOutcome[outcome] ?? 0) + 1;
  }

  @override
  Future<int?> lastFirstPlayer() async => _lastFirst;

  @override
  Future<void> setLastFirstPlayer(int player) async => _lastFirst = player;

  @override
  Future<void> reset() async => _counts.clear();
}

class FakeSettingsStore implements SettingsStore {
  bool _sound = true;
  bool _music = false;
  bool _haptics = true;
  AnimationSpeed _speed = AnimationSpeed.normal;
  BoardTheme _theme = BoardTheme.darkWood;

  @override
  Future<bool> soundEnabled() async => _sound;
  @override
  Future<void> setSoundEnabled(bool value) async => _sound = value;
  @override
  Future<bool> musicEnabled() async => _music;
  @override
  Future<void> setMusicEnabled(bool value) async => _music = value;
  @override
  Future<bool> hapticsEnabled() async => _haptics;
  @override
  Future<void> setHapticsEnabled(bool value) async => _haptics = value;
  @override
  Future<AnimationSpeed> animationSpeed() async => _speed;
  @override
  Future<void> setAnimationSpeed(AnimationSpeed value) async => _speed = value;
  @override
  Future<BoardTheme> boardTheme() async => _theme;
  @override
  Future<void> setBoardTheme(BoardTheme value) async => _theme = value;
}

class FakeSoundService implements SoundService {
  @override
  Future<void> init() async {}
  @override
  void play(SoundEffect effect) {}
  @override
  void onEvent(GameEvent event) {}
  @override
  void setEnabled(bool on) {}
  @override
  void setMusicEnabled(bool on) {}
  @override
  void setHapticsEnabled(bool on) {}
}
