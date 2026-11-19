import 'game_state.dart';

// Person 2's rules functions. Day-1 stubs: signatures only, bodies come in E2-02.

/// A new game: 12 holes of 4 seeds, both pits 0, turns 0, [firstPlayer] to move.
GameState newGame({int firstPlayer = 0}) => throw UnimplementedError();

/// The mover's holes that hold at least one seed, in increasing order.
List<int> legalMoves(GameState state) => throw UnimplementedError();

/// True when the mover has no legal move or state.turns >= gameTurnCap.
bool isGameOver(GameState state) => throw UnimplementedError();

/// The pits (player 0, player 1) after leftover seeds are handed out.
List<int> finalPits(GameState state) => throw UnimplementedError();

/// 0 or 1 for the player with the larger final pit, or draw (-1).
int winner(GameState state) => throw UnimplementedError();
