import 'package:flutter/services.dart';

// TODO: fix this import (same events file as in sound_service.dart).
import '../engine/events.dart';

typedef HapticCall = Future<void> Function();

/// Haptics through Flutter's own HapticFeedback (no extra package).
/// Runs only while the Haptics setting is on.
///
/// Sow, lift, win, lose and draw have NO haptics on purpose
/// (sow fires too often and would buzz constantly).
class HapticsService {
  HapticsService({HapticCall? selectionClick, HapticCall? mediumImpact})
      : _selectionClick = selectionClick ?? HapticFeedback.selectionClick,
        _mediumImpact = mediumImpact ?? HapticFeedback.mediumImpact;

  final HapticCall _selectionClick;
  final HapticCall _mediumImpact;
  bool _enabled = true; // the Haptics setting

  void setEnabled(bool value) => _enabled = value;

  /// Tap on a legal hole or a button.
  Future<void> tap() async {
    if (!_enabled) return;
    try {
      await _selectionClick();
    } catch (_) {}
  }

  /// A capture happened.
  Future<void> capture() async {
    if (!_enabled) return;
    try {
      await _mediumImpact();
    } catch (_) {}
  }

  /// Only CaptureEvent gives a vibration.
  void onEvent(GameEvent event) {
    if (event is CaptureEvent) {
      capture();
    }
  }
}
