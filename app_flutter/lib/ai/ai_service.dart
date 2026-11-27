import 'dart:math';

import 'package:gebeta/ai/levels.dart';
import 'package:gebeta/engine/game_state.dart';

/// How the app asks for a move (guide section 6).
abstract class AiService {
  /// Loads the weights asset if there is one.
  Future<void> init();

  /// Returns a hole number that is a legal move for state.player.
  /// Throws StateError if there are none.
  /// Never returns sooner than 600 ms after the call.
  Future<int> chooseMove(GameState state, Level level, {Random? random});
}

/// A pretend AI so Person 2 can build and test before the real one exists.
/// It plays the lowest legal hole after the 600 ms pause.
class FakeAiService implements AiService {
  @override
  Future<void> init() async {}

  @override
  Future<int> chooseMove(GameState state, Level level, {Random? random}) async {
    final moves = _legalHoles(state);
    if (moves.isEmpty) {
      throw StateError('No legal moves');
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return moves.first;
  }

  // Same rule as legalMoves in rules.dart (the mover's holes that hold seeds,
  // in increasing order). Kept here so this file does not depend on Person 2's
  // rules.dart, which is still empty.
  List<int> _legalHoles(GameState state) {
    final start = state.player == 0 ? 0 : 6;
    return [
      for (var h = start; h < start + 6; h++)
        if (state.holes[h] > 0) h,
    ];
  }
}