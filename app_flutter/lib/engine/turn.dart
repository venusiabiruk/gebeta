import 'constants.dart' as constants;
import 'events.dart';
import 'game_state.dart';

// the Python twin is engine_python/gebeta/engine.py.

/// 0 for holes 0 to 5, otherwise 1.
int owner(int hole) => hole < 6 ? 0 : 1;

/// The hole facing [hole]: 11 - hole.
int opposite(int hole) => 11 - hole;

/// Sum of the six holes of [player] in [holes].
int sideTotal(List<int> holes, int player) {
  final start = player == 0 ? 0 : 6;
  var total = 0;
  for (var i = start; i < start + 6; i++) {
    total += holes[i];
  }
  return total;
}

/// Plays [hole] for state.player. Throws [ArgumentError] if it is not a legal
/// move (not on the mover's side, or empty). Never changes [state].
///
/// It does not check that holes plus pits make 48 (tests use partial boards)
/// and it does not check whether the game is over: the caller does that.
TurnResult applyMove(GameState state, int hole) {
  final player = state.player;
  // Same test as "hole is in legalMoves(state)", written out here so that
  // turn.dart does not depend on rules.dart (which needs sideTotal from here).
  if (hole < 0 ||
      hole >= constants.holes ||
      owner(hole) != player ||
      state.holes[hole] == 0) {
    throw ArgumentError.value(
      hole,
      'hole',
      'not a legal move for player $player',
    );
  }

  final b = List<int>.of(state.holes);
  final pits = List<int>.of(state.pits);
  final events = <GameEvent>[];
  var pos = hole;
  var lifts = 0;

  while (true) {
    final seeds = b[pos];
    b[pos] = 0;
    lifts++;
    events.add(LiftEvent(pos, seeds));

    var cur = pos;
    for (var i = 0; i < seeds; i++) {
      cur = (cur + 1) % constants.holes;
      b[cur]++;
      events.add(SowEvent(cur));
    }

    // The hole already held seeds before this seed landed (it now holds more
    // than the one seed that an empty hole would hold): relay.
    if (b[cur] != 1) {
      if (lifts >= constants.sowingCap) {
        // The cap is checked only on a relay: the last lift was sown in full.
        events.add(const TurnEndEvent(TurnEndReason.sowingCap));
        break;
      }
      pos = cur;
      continue;
    }

    // The last seed landed in an empty hole.
    if (owner(cur) != player) {
      events.add(const TurnEndEvent(TurnEndReason.opponentSide));
      break;
    }
    final opp = opposite(cur);
    if (b[opp] == 0) {
      events.add(const TurnEndEvent(TurnEndReason.oppositeEmpty));
      break;
    }
    final n = b[opp];
    b[opp] = 0;
    pits[player] += n; // the landing seed stays where it is
    events.add(CaptureEvent(opp, n));
    events.add(const TurnEndEvent(TurnEndReason.captured));
    break;
  }

  return TurnResult(
    GameState(holes: b, pits: pits, player: 1 - player, turns: state.turns + 1),
    List<GameEvent>.unmodifiable(events),
  );
}
