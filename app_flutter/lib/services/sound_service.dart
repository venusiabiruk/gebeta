/// Contract for applying the player's sound and haptic preferences.
abstract class SoundService {
  void setEnabled(bool enabled);
  void setMusicEnabled(bool enabled);
  void setHapticsEnabled(bool enabled);
}

/// Temporary implementation until audio functionality is added.
class NoopSoundService implements SoundService {
  @override
  void setEnabled(bool enabled) {}

  @override
  void setMusicEnabled(bool enabled) {}

  @override
  void setHapticsEnabled(bool enabled) {}
}
