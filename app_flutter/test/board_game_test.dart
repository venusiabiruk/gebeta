import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/ui/board/board_game.dart';
import 'package:gebeta/ui/board/board_palette.dart';
import 'package:gebeta/ui/board/layout.dart';

/// Shows [game] in a box of [width] x [height] and waits until it has loaded.
Future<void> pumpBoard(
  WidgetTester tester,
  BoardGame game, {
  double width = 800,
  double height = 300,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: GameWidget(game: game),
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 40 && !game.isReady; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const mockupHoles = [2, 0, 4, 3, 1, 5, 4, 3, 0, 1, 2, 0];

void main() {
  testWidgets('creates 12 holes and 2 pits', (tester) async {
    final game = BoardGame();
    await pumpBoard(tester, game);
    expect(game.isReady, true);
    expect(game.holeComponents.length, 12);
    expect(game.pitComponents.length, 2);
    for (var h = 0; h < 12; h++) {
      expect(game.holeComponents[h].hole, h);
    }
  });

  testWidgets('places holes and pits where layout.dart says', (tester) async {
    final game = BoardGame();
    await pumpBoard(tester, game);
    const board = Size(800, 300);
    for (var h = 0; h < 12; h++) {
      final c = holeCenter(h, board);
      final hole = game.holeComponents[h];
      expect(hole.position.x, closeTo(c.dx, 0.01), reason: 'hole $h x');
      expect(hole.position.y, closeTo(c.dy, 0.01), reason: 'hole $h y');
      expect(hole.size.x, closeTo(holeRadius(board) * 2, 0.01));
      expect(hole.size.y, closeTo(holeRadius(board) * 2, 0.01));
    }
    for (var p = 0; p < 2; p++) {
      final c = pitCenter(p, board);
      final pit = game.pitComponents[p];
      expect(pit.position.x, closeTo(c.dx, 0.01), reason: 'pit $p x');
      expect(pit.position.y, closeTo(c.dy, 0.01), reason: 'pit $p y');
      expect(pit.size.x, closeTo(pitSize(board).width, 0.01));
      expect(pit.size.y, closeTo(pitSize(board).height, 0.01));
    }
  });

  testWidgets('follows the size of the space it is given', (tester) async {
    final game = BoardGame();
    await pumpBoard(tester, game);
    await pumpBoard(tester, game, width: 600, height: 250);
    await tester.pump();
    const board = Size(600, 250);
    for (var h = 0; h < 12; h++) {
      final c = holeCenter(h, board);
      expect(game.holeComponents[h].position.x, closeTo(c.dx, 0.01));
      expect(game.holeComponents[h].position.y, closeTo(c.dy, 0.01));
    }
  });

  testWidgets('the count pill is on the outside of each row', (tester) async {
    final game = BoardGame();
    await pumpBoard(tester, game);
    for (var h = 0; h < 12; h++) {
      expect(game.holeComponents[h].pillAbove, h >= 6, reason: 'hole $h');
    }
    game.flip = true;
    await tester.pump();
    for (var h = 0; h < 12; h++) {
      expect(game.holeComponents[h].pillAbove, h < 6, reason: 'flipped $h');
    }
  });

  testWidgets('flip rotates the board by 180 degrees', (tester) async {
    final game = BoardGame();
    await pumpBoard(tester, game);
    game.flip = true;
    await tester.pump();
    const board = Size(800, 300);
    for (var h = 0; h < 12; h++) {
      final c = holeCenter(h, board, flip: true);
      expect(game.holeComponents[h].position.x, closeTo(c.dx, 0.01));
      expect(game.holeComponents[h].position.y, closeTo(c.dy, 0.01));
    }
    for (var p = 0; p < 2; p++) {
      final c = pitCenter(p, board, flip: true);
      expect(game.pitComponents[p].position.x, closeTo(c.dx, 0.01));
    }
  });

  testWidgets('shows the seeds, the rings and the landing hole', (
    tester,
  ) async {
    final game = BoardGame();
    // Set before the game has loaded: it is applied once the components exist.
    game.showPosition(
      holes: mockupHoles,
      pits: const [9, 14],
      tappable: {0, 2, 3, 4, 5},
      landing: 4,
    );
    await pumpBoard(tester, game);
    for (var h = 0; h < 12; h++) {
      final hole = game.holeComponents[h];
      expect(hole.count, mockupHoles[h], reason: 'hole $h count');
      expect(hole.tappable, {0, 2, 3, 4, 5}.contains(h), reason: 'hole $h');
      expect(hole.landing, h == 4, reason: 'hole $h landing');
    }
    expect(game.pitComponents[0].count, 9);
    expect(game.pitComponents[1].count, 14);

    // Changing the position later updates the components straight away.
    game.showPosition(holes: List<int>.filled(12, 4), pits: const [0, 0]);
    expect(game.holeComponents[3].count, 4);
    expect(game.holeComponents[3].tappable, false);
    expect(game.holeComponents[4].landing, false);
    expect(game.pitComponents[0].count, 0);
  });

  testWidgets('switches between the dark and the light palette', (
    tester,
  ) async {
    final game = BoardGame();
    await pumpBoard(tester, game);
    expect(game.holeComponents[0].palette, BoardPalette.darkWood);
    game.palette = BoardPalette.lightWood;
    expect(
      game.holeComponents.every((h) => h.palette == BoardPalette.lightWood),
      true,
    );
    expect(
      game.pitComponents.every((p) => p.palette == BoardPalette.lightWood),
      true,
    );
  });
}
