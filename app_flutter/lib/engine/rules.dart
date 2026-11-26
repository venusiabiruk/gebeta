import 'constants.dart';
import 'game_state.dart';

// Person 2's rules functions (section 3 of the guide).
// They only look at a position. They never move seeds.

/// A new game: 12 holes with 4 seeds each, both pits empty, turns 0.
/// The caller picks who starts. This function uses no randomness.
GameState newGame({int firstPlayer = 0}) {
  final startHoles = <int>[];
  for (var i = 0; i < holes; i++) {
    startHoles.add(seedsPerHole);
  }
  return GameState(
    holes: startHoles,
    pits: [0, 0],
    player: firstPlayer,
    turns: 0,
  );
}

/// The mover's holes that have at least one seed, from lowest to highest.
/// Player 0 owns holes 0-5, player 1 owns holes 6-11. The turn count is ignored.
List<int> legalMoves(GameState state) {
  final moves = <int>[];
  var first = 0;
  if (state.player == 1) {
    first = 6;
  }
  for (var hole = first; hole < first + 6; hole++) {
    if (state.holes[hole] > 0) {
      moves.add(hole);
    }
  }
  return moves;
}

/// The game is over when the turn limit is reached or the mover has no seeds.
bool isGameOver(GameState state) {
  if (state.turns >= gameTurnCap) {
    return true;
  }
  return legalMoves(state).isEmpty;
}

/// The pits [player 0, player 1] after the leftover seeds are handed out.
/// If the mover has no seeds, the other player keeps the seeds on their own side.
/// Otherwise the game stopped at the turn limit, and the pits stay as they are.
List<int> finalPits(GameState state) {
  final pit0 = state.pits[0];
  final pit1 = state.pits[1];
  if (legalMoves(state).isNotEmpty) {
    return [pit0, pit1];
  }
  final other = 1 - state.player;
  var first = 0;
  if (other == 1) {
    first = 6;
  }
  var leftover = 0;
  for (var hole = first; hole < first + 6; hole++) {
    leftover += state.holes[hole];
  }
  if (other == 0) {
    return [pit0 + leftover, pit1];
  }
  return [pit0, pit1 + leftover];
}

/// 0 or 1 for the player with more seeds in their final pit, or draw (-1).
/// Only meaningful when isGameOver is true.
int winner(GameState state) {
  final pits = finalPits(state);
  if (pits[0] > pits[1]) {
    return 0;
  }
  if (pits[1] > pits[0]) {
    return 1;
  }
  return draw;
}
