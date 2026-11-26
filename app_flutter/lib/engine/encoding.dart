import 'package:gebeta/engine/game_state.dart';

// Where the mover's holes start: 0 for player 0, 6 for player 1.
int _start(GameState state) => state.player == 0 ? 0 : 6;

/// 14 integers from the mover's point of view (guide section 3):
/// the mover's 6 holes, the opponent's 6 holes, the mover's pit, the
/// opponent's pit. Dividing by 48 happens in the model code, not here.
List<int> encode(GameState state) {
  final start = _start(state);
  final p = state.player;
  return [
    for (var i = 0; i < 12; i++) state.holes[(start + i) % 12],
    state.pits[p],
    state.pits[1 - p],
  ];
}

/// The hole number for the mover's k-th hole (k is 0 to 5).
int decodeMove(GameState state, int k) => _start(state) + k;