import '../../engine/events.dart';
import 'board_model.dart';

// The clock of one turn (U1-05). Plain Dart, with no Flame or Flutter import, so
// the rules of the animation are unit tested without a screen:
//  * how long each event takes (guide, Person 1 Step 4),
//  * which event is playing and how far along it is,
//  * when the board is updated, and what a skip does.

/// Seconds a Lift takes.
const double liftSeconds = 0.2;

/// Seconds a Capture takes.
const double captureSeconds = 0.45;

/// Seconds one Sow takes when a turn has [sowCount] Sow events: 3 seconds
/// shared out, but never less than 30 ms or more than 220 ms per seed, so a
/// long relay does not take forever and a short one is not instant.
double sowSeconds(int sowCount) {
  if (sowCount <= 0) return 0.22;
  return (3.0 / sowCount).clamp(0.03, 0.22).toDouble();
}

/// Plays the [events] of one turn on [model], in real time.
///
/// Call [update] with the time since the last frame. Every event takes time;
/// the model is changed when the event ends (a Lift empties its hole when the
/// lift is over, a Sow drops its seed when the seed arrives, a Capture moves its
/// seeds when they arrive). While an event runs, [current] and [progress] say
/// what the screen should show in between.
///
/// [durationScale] slows the turn down (above 1) or speeds it up (below 1): the
/// animation speed setting.
class TurnPlayer {
  TurnPlayer({
    required this.model,
    required List<GameEvent> events,
    this.durationScale = 1.0,
    this.onEventStarted,
  })  : events = List<GameEvent>.unmodifiable(events),
        _sowSeconds =
            sowSeconds(events.whereType<SowEvent>().length) * durationScale;

  /// The board being changed, one finished event at a time.
  final BoardModel model;

  final List<GameEvent> events;

  /// 1 is normal speed, 1.6 is slow, 0.6 is fast.
  final double durationScale;

  /// Called once when an event begins, before it plays (the sound listens to
  /// it). Events that a [skip] jumps over are not announced.
  final void Function(GameEvent event)? onEventStarted;

  final double _sowSeconds;
  int _index = 0;
  double _elapsed = 0;
  bool _announced = false;

  /// The event playing now, or null when the turn is over.
  GameEvent? get current => _index < events.length ? events[_index] : null;

  /// How many events are finished.
  int get finishedCount => _index;

  /// True once every event is finished.
  bool get isDone => _index >= events.length;

  /// How far along [current] is, from 0 to 1 (0 when the turn is over).
  double get progress {
    final event = current;
    if (event == null) return 0;
    final seconds = secondsFor(event);
    return seconds <= 0 ? 0 : (_elapsed / seconds).clamp(0.0, 1.0);
  }

  /// Seconds [event] takes in this turn, at this speed. A TurnEnd takes no time.
  double secondsFor(GameEvent event) => switch (event) {
        LiftEvent() => liftSeconds * durationScale,
        SowEvent() => _sowSeconds,
        CaptureEvent() => captureSeconds * durationScale,
        TurnEndEvent() => 0,
      };

  /// Seconds the whole turn takes at this speed.
  double get totalSeconds =>
      events.fold<double>(0, (sum, event) => sum + secondsFor(event));

  /// Moves the turn forward by [dt] seconds. A long [dt] can finish several
  /// events at once. Throws [StateError] if an event cannot happen on the
  /// board (see BoardModel.apply).
  void update(double dt) {
    var remaining = dt;
    while (!isDone) {
      final event = events[_index];
      if (!_announced) {
        _announced = true;
        onEventStarted?.call(event);
      }
      final left = secondsFor(event) - _elapsed;
      if (remaining < left) {
        _elapsed += remaining;
        return;
      }
      remaining -= left;
      model.apply(event);
      _index++;
      _elapsed = 0;
      _announced = false;
    }
  }

  /// Finishes the turn now: applies every remaining event at once, with no
  /// time passing and no [onEventStarted] for the ones it jumps over.
  void skip() {
    while (!isDone) {
      model.apply(events[_index]);
      _index++;
    }
    _elapsed = 0;
    _announced = false;
  }
}
