import 'dart:math';

import '../engine/engine.dart';

enum Level { novice, amateur, master }

/// Picks the computer's move. Person 3 writes the real implementation (U3-04).
abstract class AiService {
  Future<void> init();
  Future<int> chooseMove(GameState state, Level level, {Random? random});
}

/// Plays the lowest legal hole after the 600 ms pause. For tests and early work.
class FakeAiService implements AiService {
  @override
  Future<void> init() async {}

  @override
  Future<int> chooseMove(GameState state, Level level, {Random? random}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final start = state.player == 0 ? 0 : 6;
    for (var k = 0; k < 6; k++) {
      if (state.holes[start + k] > 0) return start + k;
    }
    throw StateError('No legal move');
  }
}
