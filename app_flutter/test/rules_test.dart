import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/constants.dart' show draw, gameTurnCap;
import 'package:gebeta/engine/game_state.dart';
import 'package:gebeta/engine/rules.dart';

GameState makeState(
  List<int> cells, {
  List<int> pits = const [0, 0],
  int player = 0,
  int turns = 0,
}) {
  return GameState(holes: cells, pits: pits, player: player, turns: turns);
}

void main() {
  // The board from the capture example in the guide.
  const board = [0, 0, 0, 1, 0, 2, 3, 2, 5, 0, 0, 4];
  const emptyBoard = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  group('newGame', () {
    test('starts with 12 holes of 4, empty pits, turn 0', () {
      final state = newGame();
      expect(state.holes, [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4]);
      expect(state.pits, [0, 0]);
      expect(state.player, 0);
      expect(state.turns, 0);
    });

    test('firstPlayer decides who moves', () {
      expect(newGame(firstPlayer: 1).player, 1);
    });
  });

  group('legalMoves', () {
    test('player 0 gets its non-empty holes in order', () {
      expect(legalMoves(makeState(board)), [3, 5]);
    });

    test('player 1 gets its non-empty holes in order', () {
      expect(legalMoves(makeState(board, player: 1)), [6, 7, 8, 11]);
    });

    test('is empty when the mover has no seeds', () {
      expect(legalMoves(makeState(emptyBoard)), isEmpty);
    });

    test('ignores the turn count', () {
      expect(legalMoves(makeState(board, turns: 999)), [3, 5]);
    });
  });

  group('isGameOver', () {
    test('false at the start', () {
      expect(isGameOver(newGame()), false);
    });

    test('true when the mover has no seeds', () {
      expect(isGameOver(makeState(emptyBoard)), true);
    });

    test('true at the turn cap, false one turn before', () {
      expect(isGameOver(makeState(board, turns: gameTurnCap)), true);
      expect(isGameOver(makeState(board, turns: gameTurnCap - 1)), false);
    });
  });

  group('finalPits', () {
    test('the other player keeps the seeds on their side', () {
      const cells = [0, 0, 0, 0, 0, 0, 3, 1, 0, 2, 0, 0];
      final state = makeState(cells, pits: [18, 24]);
      expect(finalPits(state), [18, 30]);
    });

    test('works the same when player 1 is the one with no seeds', () {
      const cells = [2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      final state = makeState(cells, pits: [5, 7], player: 1);
      expect(finalPits(state), [8, 7]);
    });

    test('at the turn cap the pits stay as they are', () {
      final state = makeState(board, pits: [10, 12], turns: gameTurnCap);
      expect(finalPits(state), [10, 12]);
    });
  });

  group('winner', () {
    test('player 0 wins with the bigger pit', () {
      final state = makeState(emptyBoard, pits: [30, 18]);
      expect(winner(state), 0);
    });

    test('player 1 wins with the bigger pit', () {
      final state = makeState(emptyBoard, pits: [18, 30]);
      expect(winner(state), 1);
    });

    test('24 to 24 is a draw', () {
      final state = makeState(emptyBoard, pits: [24, 24]);
      expect(winner(state), draw);
    });
  });

  group('end cases from tests/test_cases.json', () {
    final file = File('../tests/test_cases.json');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final cases = data['end_cases'] as List<dynamic>;

    test('the test file has a version this runner knows', () {
      expect(data['version'], 1, reason: 'unknown test file version');
    });

    for (final item in cases) {
      final c = item as Map<String, dynamic>;
      test(c['name'] as String, () {
        final state = GameState(
          holes: List<int>.from(c['holes'] as List),
          pits: List<int>.from(c['pits'] as List),
          player: c['player'] as int,
          turns: c['turns'] as int,
        );
        final expected = c['expect'] as Map<String, dynamic>;
        expect(isGameOver(state), expected['game_over'], reason: 'game_over');
        if (expected['game_over'] == true) {
          expect(
            finalPits(state),
            List<int>.from(expected['final_pits'] as List),
            reason: 'final_pits',
          );
          expect(winner(state), expected['winner'], reason: 'winner');
        }
      });
    }
  });
}
