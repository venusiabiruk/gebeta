import 'package:flutter_test/flutter_test.dart';

import 'package:gebeta/services/sound_service.dart';

class FakeBackend implements AudioBackend {
  final List<String> played = [];
  int musicStarts = 0;
  int musicStops = 0;
  bool throwOnPlay = false; // simulates a missing audio file

  @override
  Future<void> preload(String file) async {
    if (throwOnPlay) throw Exception('missing $file');
  }

  @override
  Future<void> playEffect(String file, double volume) async {
    if (throwOnPlay) throw Exception('missing $file');
    played.add(file);
  }

  @override
  Future<void> playMusic(String file, double volume) async {
    if (throwOnPlay) throw Exception('missing $file');
    musicStarts++;
  }

  @override
  Future<void> stopMusic() async => musicStops++;
}

void main() {
  test('play uses the right file', () async {
    final backend = FakeBackend();
    final sound = SoundService(backend: backend);
    await sound.play(SoundEffect.capture);
    expect(backend.played, ['capture.wav']);
  });

  test('a missing audio file does not throw', () async {
    final backend = FakeBackend()..throwOnPlay = true;
    final sound = SoundService(backend: backend);
    await sound.init();
    await sound.play(SoundEffect.tap);
    await sound.startMusic();
  });

  test('setEnabled(false) makes play do nothing', () async {
    final backend = FakeBackend();
    final sound = SoundService(backend: backend)..setEnabled(false);
    await sound.play(SoundEffect.win);
    expect(backend.played, isEmpty);
  });

  test('music plays only while the Music setting is on', () async {
    final backend = FakeBackend();
    final sound = SoundService(backend: backend);
    await sound.setMusicEnabled(false);
    await sound.startMusic();
    expect(backend.musicStarts, 0);

    await sound.setMusicEnabled(true);
    await sound.startMusic();
    expect(backend.musicStarts, 1);
  });

  test('stopMusic stops the loop', () async {
    final backend = FakeBackend();
    final sound = SoundService(backend: backend);
    await sound.startMusic();
    await sound.stopMusic();
    expect(backend.musicStops, 1);
  });

  // TODO: once you know how LiftEvent / SowEvent / CaptureEvent / TurnEnd
  // are constructed, add:
  //  - onEvent(LiftEvent) plays lift.wav, SowEvent plays sow.wav,
  //    CaptureEvent plays capture.wav, TurnEnd plays nothing
  //  - onEvent with a missing file does not throw
}
