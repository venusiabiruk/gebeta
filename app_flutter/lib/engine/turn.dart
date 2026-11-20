import 'events.dart';
import 'game_state.dart';

// (E1-01): exact signatures from section 3,
// bodies come in E1-03.

/// 0 for holes 0 to 5, otherwise 1.
int owner(int hole) => throw UnimplementedError();

/// The hole facing [hole]: 11 - hole.
int opposite(int hole) => throw UnimplementedError();

/// Sum of the six holes of [player] in [holes].
int sideTotal(List<int> holes, int player) => throw UnimplementedError();

/// Plays [hole] for state.player. Throws [ArgumentError] if it is not a legal
/// move. Never changes [state].
TurnResult applyMove(GameState state, int hole) => throw UnimplementedError();