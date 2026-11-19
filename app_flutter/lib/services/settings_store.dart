enum AnimationSpeed { slow, normal, fast } // multipliers 1.6, 1.0, 0.6

enum BoardTheme { darkWood, lightWood }

/// Stub: Person 3 writes the shared_preferences version (U3-02).
class SettingsStore {
  Future<bool> soundEnabled() async => throw UnimplementedError();
  Future<void> setSoundEnabled(bool value) async => throw UnimplementedError();
  Future<bool> musicEnabled() async => throw UnimplementedError();
  Future<void> setMusicEnabled(bool value) async => throw UnimplementedError();
  Future<bool> hapticsEnabled() async => throw UnimplementedError();
  Future<void> setHapticsEnabled(bool value) async =>
      throw UnimplementedError();
  Future<AnimationSpeed> animationSpeed() async => throw UnimplementedError();
  Future<void> setAnimationSpeed(AnimationSpeed value) async =>
      throw UnimplementedError();
  Future<BoardTheme> boardTheme() async => throw UnimplementedError();
  Future<void> setBoardTheme(BoardTheme value) async =>
      throw UnimplementedError();
}
