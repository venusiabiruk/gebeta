import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_store.dart';
import 'providers.dart';

/// The five settings the player can change.
class SettingsValues {
  const SettingsValues({
    this.sound = true,
    this.music = false,
    this.haptics = true,
    this.speed = AnimationSpeed.normal,
    this.board = BoardTheme.darkWood,
  });

  final bool sound;
  final bool music;
  final bool haptics;
  final AnimationSpeed speed;
  final BoardTheme board;

  SettingsValues copyWith({
    bool? sound,
    bool? music,
    bool? haptics,
    AnimationSpeed? speed,
    BoardTheme? board,
  }) {
    return SettingsValues(
      sound: sound ?? this.sound,
      music: music ?? this.music,
      haptics: haptics ?? this.haptics,
      speed: speed ?? this.speed,
      board: board ?? this.board,
    );
  }
}

/// Keeps the settings, loads them from the SettingsStore, and saves changes.
class SettingsNotifier extends Notifier<SettingsValues> {
  Future<void>? _loading;

  @override
  SettingsValues build() {
    unawaited(load());
    return const SettingsValues();
  }

  /// Read the saved values. It only reads once, so calling it again is safe.
  /// The splash screen waits for it, so the settings are ready before Home.
  Future<void> load() {
    _loading ??= _readFromStore();
    return _loading!;
  }

  Future<void> _readFromStore() async {
    final store = ref.read(settingsStoreProvider);
    try {
      final sound = await store.soundEnabled();
      final music = await store.musicEnabled();
      final haptics = await store.hapticsEnabled();
      final speed = await store.animationSpeed();
      final board = await store.boardTheme();
      state = SettingsValues(
        sound: sound,
        music: music,
        haptics: haptics,
        speed: speed,
        board: board,
      );
    } catch (e) {
      debugPrint('Could not read the settings, using the defaults: $e');
    }
    _tellSoundService();
  }

  Future<void> setSound(bool value) async {
    state = state.copyWith(sound: value);
    _tellSoundService();
    await _save((store) => store.setSoundEnabled(value));
  }

  Future<void> setMusic(bool value) async {
    state = state.copyWith(music: value);
    _tellSoundService();
    await _save((store) => store.setMusicEnabled(value));
  }

  Future<void> setHaptics(bool value) async {
    state = state.copyWith(haptics: value);
    _tellSoundService();
    await _save((store) => store.setHapticsEnabled(value));
  }

  Future<void> setSpeed(AnimationSpeed value) async {
    state = state.copyWith(speed: value);
    await _save((store) => store.setAnimationSpeed(value));
  }

  Future<void> setBoard(BoardTheme value) async {
    state = state.copyWith(board: value);
    await _save((store) => store.setBoardTheme(value));
  }

  /// Tell the sound service what is switched on. It may still be a stub,
  /// so a failure only prints a message.
  void _tellSoundService() {
    try {
      final service = ref.read(soundServiceProvider);
      service.setEnabled(state.sound);
      service.setMusicEnabled(state.music);
      service.setHapticsEnabled(state.haptics);
    } catch (e) {
      debugPrint('The sound service could not be updated: $e');
    }
  }

  Future<void> _save(Future<void> Function(SettingsStore store) write) async {
    try {
      await write(ref.read(settingsStoreProvider));
    } catch (e) {
      debugPrint('Could not save the setting: $e');
    }
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsValues>(SettingsNotifier.new);
