import 'game_state.dart';

enum TurnEndReason { captured, opponentSide, oppositeEmpty, sowingCap }

extension TurnEndReasonWire on TurnEndReason {
  /// The text used in JSON and in the Python engine.
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

  static TurnEndReason fromWire(String s) {
    for (final r in TurnEndReason.values) {
      if (r.wire == s) return r;
    }
    throw ArgumentError('Unknown turn end reason: $s');
  }
}

sealed class GameEvent {
  const GameEvent();

  /// The array form used in event_traces.json, for example ['lift', 2, 4].
  List<Object> toJson();

  static GameEvent fromJson(List<dynamic> json) {
    final kind = json[0] as String;
    switch (kind) {
      case 'lift':
        return LiftEvent(json[1] as int, json[2] as int);
      case 'sow':
        return SowEvent(json[1] as int);
      case 'capture':
        return CaptureEvent(json[1] as int, json[2] as int);
      case 'turn_end':
        return TurnEndEvent(TurnEndReasonWire.fromWire(json[1] as String));
      default:
        throw ArgumentError('Unknown event: $kind');
    }
  }
}

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
}

class SowEvent extends GameEvent {
  const SowEvent(this.hole);
  final int hole;

  @override
  List<Object> toJson() => ['sow', hole];

  @override
  bool operator ==(Object other) => other is SowEvent && other.hole == hole;

  @override
  int get hashCode => Object.hash('sow', hole);
}

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
}

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
}

/// The result of one turn: the new state and the events, in order.
/// applyMove returns the events as an unmodifiable list.
class TurnResult {
  const TurnResult(this.state, this.events);
  final GameState state;
  final List<GameEvent> events;
}
