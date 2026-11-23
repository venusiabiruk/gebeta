import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

// TODO: fix this import to the file that defines the game events
// (LiftEvent, SowEvent, CaptureEvent, TurnEnd) from section 8 of the guide.
import '../engine/events.dart';

/// Every sound effect. File names live in app_flutter/assets/audio/.
/// If SoundEffect already exists in the guide's code, merge this into it.
enum SoundEffect {
  tap('tap.wav', 0.6),
  lift('lift.wav', 0.6),
  sow('sow.wav', 0.35), // plays up to 6 times a second: keep it quiet
  capture('capture.wav', 1.0), // the loudest effect
  win('win.wav', 0.8),
  lose('lose.wav', 0.7), // gentle, not harsh
  draw('draw.wav', 0.7);

  const SoundEffect(this.fileName, this.volume);
  final String fileName;
  final double volume;
}

const String kMusicFile = 'music_loop.mp3';
const double kMusicVolume = 0.25; // quieter than the effects

/// Small wrapper so tests can replace the real audio engine.
abstract class AudioBackend {
  Future<void> preload(String file);
  Future<void> playEffect(String file, double volume);
  Future<void> playMusic(String file, double volume);
  Future<void> stopMusic();
}

/// Real implementation using flame_audio.
/// Files are looked up in assets/audio/ (the flame_audio default).
class FlameAudioBackend implements AudioBackend {
  @override
  Future<void> preload(String file) async {
    await FlameAudio.audioCache.load(file);
  }

  @override
  Future<void> playEffect(String file, double volume) async {
    await FlameAudio.play(file, volume: volume);
  }

  @override
  Future<void> playMusic(String file, double volume) async {
    await FlameAudio.bgm.play(file, volume: volume);
  }

  @override
  Future<void> stopMusic() async {
    await FlameAudio.bgm.stop();
  }
}

class SoundService {
  SoundService({AudioBackend? backend})
      : _backend = backend ?? FlameAudioBackend();

  final AudioBackend _backend;
  bool _enabled = true; // the Sound setting (effects)
  bool _musicEnabled = true; // the Music setting
  bool _musicPlaying = false;

  /// Call once at app start. Loads every file into memory so the first
  /// sound has no delay. A missing file is skipped, never an error.
  Future<void> init() async {
    final files = [...SoundEffect.values.map((e) => e.fileName), kMusicFile];
    for (final file in files) {
      try {
        await _backend.preload(file);
      } catch (_) {
        // File missing or cannot be decoded: ignore.
      }
    }
  }

  /// Sound setting on/off (effects only).
  void setEnabled(bool value) => _enabled = value;

  /// Music setting on/off. Turning it off stops the loop immediately.
  /// Turning it on does NOT start the music by itself: call [startMusic]
  /// from a screen where music should play (never the result screen).
  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    if (!value) await stopMusic();
  }

  /// Never throws. Does nothing when sound is off or the file is missing.
  Future<void> play(SoundEffect effect) async {
    if (!_enabled) return;
    try {
      await _backend.playEffect(effect.fileName, effect.volume);
    } catch (_) {
      // Missing file or audio error: stay silent.
    }
  }

  /// Maps game events to sounds. Lift, Sow and Capture have a sound;
  /// TurnEnd (and anything else) does nothing.
  void onEvent(GameEvent event) {
    if (event is LiftEvent) {
      unawaited(play(SoundEffect.lift));
    } else if (event is SowEvent) {
      unawaited(play(SoundEffect.sow));
    } else if (event is CaptureEvent) {
      unawaited(play(SoundEffect.capture));
    }
  }

  /// Plays the loop only while the Music setting is on.
  Future<void> startMusic() async {
    if (!_musicEnabled || _musicPlaying) return;
    try {
      await _backend.playMusic(kMusicFile, kMusicVolume);
      _musicPlaying = true;
    } catch (_) {
      // Missing music file: stay silent.
    }
  }

  /// Call this when the result screen opens.
  Future<void> stopMusic() async {
    _musicPlaying = false;
    try {
      await _backend.stopMusic();
    } catch (_) {}
  }
}
