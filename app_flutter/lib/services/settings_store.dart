import 'package:shared_preferences/shared_preferences.dart';

/// Animation speed selected by the player.
enum AnimationSpeed { slow, normal, fast }

/// Board appearance selected by the player.
enum BoardTheme { darkWood, lightWood }

/// Contract for reading and updating player settings.
abstract class SettingsStore {
  Future<bool> soundEnabled();
  Future<bool> musicEnabled();
  Future<bool> hapticsEnabled();
  Future<AnimationSpeed> animationSpeed();
  Future<BoardTheme> boardTheme();

  Future<void> setSoundEnabled(bool value);
  Future<void> setMusicEnabled(bool value);
  Future<void> setHapticsEnabled(bool value);
  Future<void> setAnimationSpeed(AnimationSpeed value);
  Future<void> setBoardTheme(BoardTheme value);
}

/// Persistent settings implementation using SharedPreferences.
class SharedPreferencesSettingsStore implements SettingsStore {
  SharedPreferencesSettingsStore(this._preferences);

  final Future<SharedPreferences> _preferences;

  static const _soundKey = 'gebeta_sound_enabled';
  static const _musicKey = 'gebeta_music_enabled';
  static const _hapticsKey = 'gebeta_haptics_enabled';
  static const _speedKey = 'gebeta_animation_speed';
  static const _boardKey = 'gebeta_board_theme';

  @override
  Future<bool> soundEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_soundKey) ?? true;
  }

  @override
  Future<bool> musicEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_musicKey) ?? false;
  }

  @override
  Future<bool> hapticsEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_hapticsKey) ?? true;
  }

  @override
  Future<AnimationSpeed> animationSpeed() async {
    final prefs = await _preferences;
    final value = prefs.getString(_speedKey);

    return AnimationSpeed.values.firstWhere(
      (speed) => speed.name == value,
      orElse: () => AnimationSpeed.normal,
    );
  }

  @override
  Future<BoardTheme> boardTheme() async {
    final prefs = await _preferences;
    final value = prefs.getString(_boardKey);

    return BoardTheme.values.firstWhere(
      (theme) => theme.name == value,
      orElse: () => BoardTheme.darkWood,
    );
  }

  @override
  Future<void> setSoundEnabled(bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(_soundKey, value);
  }

  @override
  Future<void> setMusicEnabled(bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(_musicKey, value);
  }

  @override
  Future<void> setHapticsEnabled(bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(_hapticsKey, value);
  }

  @override
  Future<void> setAnimationSpeed(AnimationSpeed value) async {
    final prefs = await _preferences;
    await prefs.setString(_speedKey, value.name);
  }

  @override
  Future<void> setBoardTheme(BoardTheme value) async {
    final prefs = await _preferences;
    await prefs.setString(_boardKey, value.name);
  }
}
