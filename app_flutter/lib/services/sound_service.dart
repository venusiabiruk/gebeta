import '../engine/engine.dart';

enum SoundEffect { tap, lift, sow, capture, win, lose, draw }

/// Stub: Person 3 writes the flame_audio version (U3-03).
class SoundService {
  Future<void> init() async => throw UnimplementedError();
  void play(SoundEffect effect) => throw UnimplementedError();
  void onEvent(GameEvent event) => throw UnimplementedError();
  void setEnabled(bool on) => throw UnimplementedError();
  void setMusicEnabled(bool on) => throw UnimplementedError();
  void setHapticsEnabled(bool on) => throw UnimplementedError();
}
