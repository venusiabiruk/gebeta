import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/engine.dart';

void main() {
  const board = [0, 0, 0, 1, 0, 2, 3, 2, 5, 0, 0, 4];

  test('player 0: holes in order, then the mover pit, then the other pit', () {
    final state = GameState(holes: board, pits: [7, 9], player: 0);
    expect(encode(state), [0, 0, 0, 1, 0, 2, 3, 2, 5, 0, 0, 4, 7, 9]);
  });

  test('player 1: the holes start at hole 6, and the pits swap', () {
    final state = GameState(holes: board, pits: [7, 9], player: 1);
    expect(encode(state), [3, 2, 5, 0, 0, 4, 0, 0, 0, 1, 0, 2, 9, 7]);
  });

  test('encode always returns 14 integers', () {
    final state = GameState(holes: board, pits: [7, 9], player: 1);
    expect(encode(state).length, 14);
  });

  test('decodeMove adds k to the first hole of the mover', () {
    final first = GameState(holes: board, pits: [0, 0], player: 0);
    final second = GameState(holes: board, pits: [0, 0], player: 1);
    for (var k = 0; k < 6; k++) {
      expect(decodeMove(first, k), k);
      expect(decodeMove(second, k), 6 + k);
    }
  });

  test('decodeMove does not check that the hole has seeds', () {
    final state = GameState(holes: board, pits: [0, 0], player: 0);
    expect(decodeMove(state, 0), 0); // hole 0 is empty, and that is fine
  });
}
