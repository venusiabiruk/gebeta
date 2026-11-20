import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/events.dart';
import 'package:gebeta/engine/game_state.dart';
import 'package:gebeta/ui/board/board_view.dart';

GameState startState({int player = 0}) =>
    GameState(holes: List<int>.filled(12, 4), pits: [0, 0], player: player);

Widget app(Widget board) => MaterialApp(home: Scaffold(body: board));

Finder hole(int i) => find.byKey(ValueKey('hole-$i'));

void main() {
  testWidgets('draws 12 holes and 2 pits with their seed counts', (
    tester,
  ) async {
    final state = GameState(
      holes: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      pits: [20, 30],
      player: 0,
    );
    await tester.pumpWidget(
      app(BoardView(state: state, inputEnabled: false, onHoleTap: (_) {})),
    );
    for (var i = 0; i < 12; i++) {
      expect(hole(i), findsOneWidget);
      expect(
        find.descendant(of: hole(i), matching: find.text('$i')),
        findsOneWidget,
      );
    }
    final pit0 = find.byKey(const ValueKey('pit-0'));
    final pit1 = find.byKey(const ValueKey('pit-1'));
    expect(
      find.descendant(of: pit0, matching: find.text('20')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: pit1, matching: find.text('30')),
      findsOneWidget,
    );
  });

  testWidgets('tapping a legal hole calls onHoleTap with its number', (
    tester,
  ) async {
    final tapped = <int>[];
    await tester.pumpWidget(
      app(
        BoardView(
          state: startState(),
          inputEnabled: true,
          onHoleTap: tapped.add,
        ),
      ),
    );
    await tester.tap(hole(3));
    expect(tapped, [3]);
  });

  testWidgets('player 1 can tap holes 6 to 11', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(
      app(
        BoardView(
          state: startState(player: 1),
          inputEnabled: true,
          onHoleTap: tapped.add,
        ),
      ),
    );
    await tester.tap(hole(9));
    await tester.tap(hole(2), warnIfMissed: false);
    expect(tapped, [9]);
  });

  testWidgets('taps are ignored when inputEnabled is false', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(
      app(
        BoardView(
          state: startState(),
          inputEnabled: false,
          onHoleTap: tapped.add,
        ),
      ),
    );
    await tester.tap(hole(3), warnIfMissed: false);
    expect(tapped, isEmpty);
  });

  testWidgets('taps on the other side or on an empty hole are ignored', (
    tester,
  ) async {
    final tapped = <int>[];
    final state = GameState(
      holes: [0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4],
      pits: [0, 0],
      player: 0,
    );
    await tester.pumpWidget(
      app(BoardView(state: state, inputEnabled: true, onHoleTap: tapped.add)),
    );
    await tester.tap(hole(8), warnIfMissed: false); // the other side
    await tester.tap(hole(0), warnIfMissed: false); // empty
    expect(tapped, isEmpty);
    await tester.tap(hole(1));
    expect(tapped, [1]);
  });

  testWidgets('events: onEventStarted for each, then onEventsDone once', (
    tester,
  ) async {
    const events = <GameEvent>[
      LiftEvent(3, 1),
      SowEvent(4),
      CaptureEvent(7, 2),
      TurnEndEvent(TurnEndReason.captured),
    ];
    final started = <GameEvent>[];
    var done = 0;
    final tapped = <int>[];
    await tester.pumpWidget(
      app(
        BoardView(
          state: GameState(
            holes: [0, 0, 0, 1, 0, 2, 3, 2, 5, 0, 0, 4],
            pits: [0, 0],
            player: 0,
          ),
          inputEnabled: true,
          onHoleTap: tapped.add,
          events: events,
          onEventStarted: started.add,
          onEventsDone: () => done++,
        ),
      ),
    );
    await tester.pump();
    expect(started, events);
    expect(done, 1);
    // While events are playing, taps are ignored whatever inputEnabled says.
    await tester.tap(hole(5), warnIfMissed: false);
    expect(tapped, isEmpty);
  });

  testWidgets('a state change with no events does not call onEventsDone', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(
      app(
        BoardView(
          state: startState(),
          inputEnabled: false,
          onHoleTap: (_) {},
          onEventsDone: () => done++,
        ),
      ),
    );
    await tester.pumpWidget(
      app(
        BoardView(
          state: startState(player: 1),
          inputEnabled: false,
          onHoleTap: (_) {},
          onEventsDone: () => done++,
        ),
      ),
    );
    expect(done, 0);
  });

  testWidgets('flipForPlayerOne puts player 1 at the bottom', (tester) async {
    Future<void> pump({required bool flip}) => tester.pumpWidget(
      app(
        BoardView(
          state: startState(),
          inputEnabled: false,
          onHoleTap: (_) {},
          flipForPlayerOne: flip,
        ),
      ),
    );

    await pump(flip: false);
    expect(
      tester.getCenter(hole(0)).dy,
      greaterThan(tester.getCenter(hole(11)).dy),
    );
    // Play runs left to right along the bottom row.
    expect(
      tester.getCenter(hole(0)).dx,
      lessThan(tester.getCenter(hole(5)).dx),
    );

    await pump(flip: true);
    expect(
      tester.getCenter(hole(6)).dy,
      greaterThan(tester.getCenter(hole(0)).dy),
    );
    expect(
      tester.getCenter(hole(6)).dx,
      lessThan(tester.getCenter(hole(11)).dx),
    );
  });
}