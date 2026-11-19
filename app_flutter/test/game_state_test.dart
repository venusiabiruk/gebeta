import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/game_state.dart';

void main() {
  GameState start() => GameState(
        holes: List<int>.filled(12, 4),
        pits: [0, 0],
        player: 0,
      );

  test('turns defaults to 0', () {
    expect(start().turns, 0);
  });

  test('holes and pits are unmodifiable', () {
    final s = start();
    expect(() => s.holes[0] = 9, throwsUnsupportedError);
    expect(() => s.pits[0] = 9, throwsUnsupportedError);
  });

  test('the constructor copies the lists it is given', () {
    final holes = List<int>.filled(12, 4);
    final s = GameState(holes: holes, pits: [0, 0], player: 0);
    holes[0] = 9;
    expect(s.holes[0], 4);
  });

  test('copyWith changes only the given fields', () {
    final s = start().copyWith(player: 1, turns: 3);
    expect(s.player, 1);
    expect(s.turns, 3);
    expect(s.holes, List<int>.filled(12, 4));
    expect(s.pits, [0, 0]);
  });

  test('equal states are equal and have equal hash codes', () {
    expect(start(), start());
    expect(start().hashCode, start().hashCode);
    expect(start() == start().copyWith(turns: 1), false);
    expect(start() == start().copyWith(pits: [1, 0]), false);
  });

  test('toJson and fromJson round trip', () {
    final json = start().toJson();
    expect(json, {
      'holes': [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4],
      'pits': [0, 0],
      'player': 0,
      'turns': 0,
    });
    expect(GameState.fromJson(json), start());
  });
}