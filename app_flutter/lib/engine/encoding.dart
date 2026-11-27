import 'constants.dart';
import 'game_state.dart';

/// The position from the mover's point of view, as 14 integers:
/// the 12 holes starting at the mover's first hole, then the mover's pit,
/// then the opponent's pit. This is the input of the AI model.
/// It does not divide by 48. The model code does that.
List<int> encode(GameState state) {
  final start = state.player == 0 ? 0 : 6;
  final result = <int>[];
  for (var i = 0; i < holes; i++) {
    result.add(state.holes[(start + i) % holes]);
  }
  result.add(state.pits[state.player]);
  result.add(state.pits[1 - state.player]);
  return result;
}

/// The hole number for the mover's k-th hole (k is 0 to 5).
/// It does not check that the hole has seeds.
int decodeMove(GameState state, int k) {
  final start = state.player == 0 ? 0 : 6;
  return start + k;
}
