import 'game_state.dart';

/// Why a turn ended. The wire strings are fixed by the guide (section 2):
/// captured, opponent_side, opposite_empty, sowing_cap.
enum TurnEndReason { captured, opponentSide, oppositeEmpty, sowingCap }

extension TurnEndReasonWire on TurnEndReason {
  /// The string used in JSON and in the Python engine.
  String get wire {
    switch (this) {
      case TurnEndReason.captured:
        return 'captured';
      case TurnEndReason.opponentSide:
        return 'opponent_side';
      case TurnEndReason.oppositeEmpty:
        return 'opposite_empty';
      case TurnEndReason.sowingCap:
        return 'sowing_cap';
    }
  }

  /// The reason for a wire string. Throws [ArgumentError] on unknown text.
  static TurnEndReason fromWire(String s) {
    for (final reason in TurnEndReason.values) {
      if (reason.wire == s) return reason;
    }
    throw ArgumentError.value(s, 's', 'unknown turn end reason');
  }
}

/// One thing that happens during a turn. The board animates these, the sound
/// plays on them and tests compare them (guide, section 2).
sealed class GameEvent {
  const GameEvent();

  /// The array form used in the JSON test files, for example ["lift", 2, 4].
  List<Object> toJson();

  /// Builds an event from its array form. Throws [ArgumentError] when the
  /// array is not a valid event.
  static GameEvent fromJson(List<dynamic> json) {
    if (json.isEmpty || json.first is! String) {
      throw ArgumentError.value(json, 'json', 'not an event');
    }
    final tag = json.first as String;
    switch (tag) {
      case 'lift':
        _expect(json, 3);
        return LiftEvent(_int(json, 1), _int(json, 2));
      case 'sow':
        _expect(json, 2);
        return SowEvent(_int(json, 1));
      case 'capture':
        _expect(json, 3);
        return CaptureEvent(_int(json, 1), _int(json, 2));
      case 'turn_end':
        _expect(json, 2);
        final reason = json[1];
        if (reason is! String) {
          throw ArgumentError.value(json, 'json', 'turn_end needs a string');
        }
        return TurnEndEvent(TurnEndReasonWire.fromWire(reason));
      default:
        throw ArgumentError.value(json, 'json', 'unknown event "$tag"');
    }
  }

  static void _expect(List<dynamic> json, int length) {
    if (json.length != length) {
      throw ArgumentError.value(json, 'json', 'expected $length elements');
    }
  }

  static int _int(List<dynamic> json, int i) {
    final v = json[i];
    if (v is! int) {
      throw ArgumentError.value(json, 'json', 'element $i must be an integer');
    }
    return v;
  }
}

/// All seeds were taken from [hole]. The first event of every turn, and the
/// start of every relay.
class LiftEvent extends GameEvent {
  const LiftEvent(this.hole, this.seeds);
  final int hole;
  final int seeds;

  @override
  List<Object> toJson() => ['lift', hole, seeds];

  @override
  bool operator ==(Object other) =>
      other is LiftEvent && other.hole == hole && other.seeds == seeds;

  @override
  int get hashCode => Object.hash('lift', hole, seeds);

  @override
  String toString() => 'LiftEvent($hole, $seeds)';
}

/// One seed was dropped into [hole].
class SowEvent extends GameEvent {
  const SowEvent(this.hole);
  final int hole;

  @override
  List<Object> toJson() => ['sow', hole];

  @override
  bool operator ==(Object other) => other is SowEvent && other.hole == hole;

  @override
  int get hashCode => Object.hash('sow', hole);

  @override
  String toString() => 'SowEvent($hole)';
}

/// [seeds] seeds were moved from [hole] (the opposite hole) into the mover's
/// pit.
class CaptureEvent extends GameEvent {
  const CaptureEvent(this.hole, this.seeds);
  final int hole;
  final int seeds;

  @override
  List<Object> toJson() => ['capture', hole, seeds];

  @override
  bool operator ==(Object other) =>
      other is CaptureEvent && other.hole == hole && other.seeds == seeds;

  @override
  int get hashCode => Object.hash('capture', hole, seeds);

  @override
  String toString() => 'CaptureEvent($hole, $seeds)';
}

/// The turn is over. Always the last event of a turn.
class TurnEndEvent extends GameEvent {
  const TurnEndEvent(this.reason);
  final TurnEndReason reason;

  @override
  List<Object> toJson() => ['turn_end', reason.wire];

  @override
  bool operator ==(Object other) =>
      other is TurnEndEvent && other.reason == reason;

  @override
  int get hashCode => Object.hash('turn_end', reason);

  @override
  String toString() => 'TurnEndEvent(${reason.wire})';
}

/// The result of one turn: the new state and the events, in order.
/// [events] MUST be unmodifiable (applyMove wraps it with List.unmodifiable).
class TurnResult {
  const TurnResult(this.state, this.events);
  final GameState state;
  final List<GameEvent> events;
}