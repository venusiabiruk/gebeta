import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/ai/ai_service.dart';
import 'package:gebeta/ai/levels.dart';
import 'package:gebeta/engine/game_state.dart';

void main() {
  final start = GameState(
    holes: List.filled(12, 4),
    pits: [0, 0],
    player: 0,
  );

  test('FakeAiService plays the lowest legal hole', () async {
    final ai = FakeAiService();
    await ai.init();
    expect(await ai.chooseMove(start, Level.novice), 0);
  });

  test('FakeAiService waits at least 600 ms', () async {
    final ai = FakeAiService();
    final watch = Stopwatch()..start();
    await ai.chooseMove(start, Level.master);
    expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(590));
  });

  test('FakeAiService throws StateError when there is no legal move', () async {
    final ai = FakeAiService();
    final empty = GameState(
      holes: [0, 0, 0, 0, 0, 0, 4, 4, 4, 4, 4, 4],
      pits: [0, 0],
      player: 0,
    );
    expect(() => ai.chooseMove(empty, Level.amateur), throwsStateError);
  });
}