import '../../engine/events.dart';
import '../../engine/game_state.dart';

/// The board as the animation sees it: seed counts that change one event at a
/// time. Plain Dart, with no Flame or Flutter import, so it is unit tested
/// without a screen.
///
/// [apply] is the same replay the guide defines for the event stream (section
/// 2, rule 7): Lift takes a hole's seeds into the hand, Sow drops one seed from
/// the hand, Capture moves a hole's seeds into the mover's pit, TurnEnd changes
/// no counts.
///
/// This class is mutable on purpose: the board steps through a turn. Read
/// [holes] and [pits], but change them only through [apply].
class BoardModel {
  BoardModel({
    required List<int> holes,
    required List<int> pits,
    required this.mover,
  })  : holes = List<int>.of(holes),
        pits = List<int>.of(pits);

  /// The position at rest, with [mover] (state.player) as the player whose turn
  /// is about to be played.
  factory BoardModel.fromState(GameState state) =>
      BoardModel(holes: state.holes, pits: state.pits, mover: state.player);

  /// Seeds in holes 0 to 11.
  final List<int> holes;

  /// Seeds in the pit of player 0 and of player 1.
  final List<int> pits;

  /// The player whose turn is being replayed. Captures go to this pit.
  final int mover;

  /// Seeds lifted and not yet sown.
  int hand = 0;

  /// The hole of the latest Lift, or null before any.
  int? lastLifted;

  /// The hole of the latest Sow (where the last seed landed), or null before any.
  int? lastSown;

  /// Applies one event. Throws [StateError] when the event cannot happen on
  /// this board (for example a Sow with an empty hand): that means the events
  /// and the board disagree, and the caller should snap to the true position.
  void apply(GameEvent event) {
    switch (event) {
      case LiftEvent():
        if (hand != 0) {
          throw StateError('$event with $hand seeds still in the hand');
        }
        if (holes[event.hole] != event.seeds) {
          throw StateError(
            '$event but hole ${event.hole} holds '
            '${holes[event.hole]}',
          );
        }
        hand = event.seeds;
        holes[event.hole] = 0;
        lastLifted = event.hole;
      case SowEvent():
        if (hand <= 0) throw StateError('$event with an empty hand');
        hand--;
        holes[event.hole]++;
        lastSown = event.hole;
      case CaptureEvent():
        if (holes[event.hole] != event.seeds) {
          throw StateError(
            '$event but hole ${event.hole} holds '
            '${holes[event.hole]}',
          );
        }
        pits[mover] += event.seeds;
        holes[event.hole] = 0;
      case TurnEndEvent():
        if (hand != 0) {
          throw StateError('$event with $hand seeds still in the hand');
        }
    }
  }

  /// True when the seed counts equal the given holes and pits.
  bool matches(List<int> otherHoles, List<int> otherPits) =>
      _sameCounts(holes, otherHoles) && _sameCounts(pits, otherPits);

  static bool _sameCounts(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
