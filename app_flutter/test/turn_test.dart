import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/events.dart';
import 'package:gebeta/engine/game_state.dart';
import 'package:gebeta/engine/turn.dart';

GameState state(
  List<int> holes, {
  List<int> pits = const [0, 0],
  int player = 0,
  int turns = 0,
}) =>
    GameState(holes: holes, pits: pits, player: player, turns: turns);

List<List<Object>> wire(List<GameEvent> events) =>
    events.map((e) => e.toJson()).toList();

void main() {
  group('owner, opposite, sideTotal', () {
    test('owner', () {
      for (var h = 0; h < 6; h++) {
        expect(owner(h), 0);
      }
      for (var h = 6; h < 12; h++) {
        expect(owner(h), 1);
      }
    });

    test('opposite is 11 - hole and is its own inverse', () {
      expect(opposite(0), 11);
      expect(opposite(5), 6);
      for (var h = 0; h < 12; h++) {
        expect(opposite(opposite(h)), h);
        expect(owner(opposite(h)), 1 - owner(h));
      }
    });

    test('sideTotal sums the six holes of one player', () {
      final holes = [1, 2, 3, 4, 5, 6, 10, 20, 30, 40, 50, 60];
      expect(sideTotal(holes, 0), 21);
      expect(sideTotal(holes, 1), 210);
    });
  });

  group('applyMove: worked traces from the guide', () {
    test('spec example 3: a simple capture', () {
      final start = state([0, 0, 0, 1, 0, 2, 3, 2, 5, 0, 0, 4]);
      final r = applyMove(start, 3);
      expect(wire(r.events), [
        ['lift', 3, 1],
        ['sow', 4],
        ['capture', 7, 2],
        ['turn_end', 'captured'],
      ]);
      expect(r.state.holes, [0, 0, 0, 0, 1, 2, 3, 0, 5, 0, 0, 4]);
      expect(r.state.pits, [2, 0]);
      expect(r.state.player, 1);
      expect(r.state.turns, 1);
    });

    test('spec example 1: four relays then a capture', () {
      final r = applyMove(state(List<int>.filled(12, 4)), 2);
      expect(wire(r.events), [
        ['lift', 2, 4],
        ['sow', 3],
        ['sow', 4],
        ['sow', 5],
        ['sow', 6],
        ['lift', 6, 5],
        ['sow', 7],
        ['sow', 8],
        ['sow', 9],
        ['sow', 10],
        ['sow', 11],
        ['lift', 11, 5],
        ['sow', 0],
        ['sow', 1],
        ['sow', 2],
        ['sow', 3],
        ['sow', 4],
        ['lift', 4, 6],
        ['sow', 5],
        ['sow', 6],
        ['sow', 7],
        ['sow', 8],
        ['sow', 9],
        ['sow', 10],
        ['lift', 10, 6],
        ['sow', 11],
        ['sow', 0],
        ['sow', 1],
        ['sow', 2],
        ['sow', 3],
        ['sow', 4],
        ['capture', 7, 6],
        ['turn_end', 'captured'],
      ]);
      expect(r.state.holes, [6, 6, 2, 7, 1, 6, 1, 0, 6, 6, 0, 1]);
      expect(r.state.pits, [6, 0]);
      expect(r.state.player, 1);
    });
  });

  group('applyMove: turn end reasons', () {
    test(
      'opponent_side: an empty landing on the other side never captures',
      () {
        // Hole 5 holds 1 seed and lands in empty hole 6 (opponent's side), even
        // though the hole opposite it (5) is now empty and hole 11 holds seeds.
        final r = applyMove(state([0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 3]), 5);
        expect(wire(r.events), [
          ['lift', 5, 1],
          ['sow', 6],
          ['turn_end', 'opponent_side'],
        ]);
        expect(r.state.pits, [0, 0]);
      },
    );

    test(
      'opposite_empty: an empty landing on my side with nothing opposite',
      () {
        final r = applyMove(state([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5]), 0);
        expect(wire(r.events), [
          ['lift', 0, 1],
          ['sow', 1],
          ['turn_end', 'opposite_empty'],
        ]);
        expect(r.state.pits, [0, 0]);
        expect(r.state.holes[1], 1);
      },
    );

    test(
      'captured: the landing seed stays, only the opposite hole is taken',
      () {
        final r = applyMove(state([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0]), 0);
        expect(wire(r.events), [
          ['lift', 0, 1],
          ['sow', 1],
          ['capture', 10, 7],
          ['turn_end', 'captured'],
        ]);
        expect(r.state.holes[1], 1);
        expect(r.state.holes[10], 0);
        expect(r.state.pits, [7, 0]);
      },
    );

    test(
        'a full lap: the last seed lands in the emptied start hole and '
        'captures (spec example 6)', () {
      // 12 seeds in hole 0 go once around the ring. Holes 1 to 10 were empty,
      // hole 11 held 3. The 12th seed lands in hole 0, which the lift emptied,
      // so the turn ends there and captures hole 11 (3 + the 1 just sown).
      final r = applyMove(state([12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3]), 0);
      expect(r.events.whereType<LiftEvent>().length, 1);
      expect(r.events.whereType<SowEvent>().length, 12);
      expect(r.events[r.events.length - 3], const SowEvent(0));
      expect(r.events[r.events.length - 2], const CaptureEvent(11, 4));
      expect(r.events.last, const TurnEndEvent(TurnEndReason.captured));
      expect(r.state.holes, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0]);
      expect(r.state.pits, [4, 0]);
    });
  });

  group('applyMove: mover and counters', () {
    test('player 1 captures into pit 1 and pit 0 never changes', () {
      // Mirror of spec example 3 for player 1: hole 9 lands in empty hole 10;
      // opposite hole 1 holds 2 seeds.
      final r = applyMove(
        state(
          [5, 2, 3, 0, 0, 4, 0, 0, 0, 1, 0, 2],
          pits: [7, 3],
          player: 1,
          turns: 9,
        ),
        9,
      );
      expect(wire(r.events), [
        ['lift', 9, 1],
        ['sow', 10],
        ['capture', 1, 2],
        ['turn_end', 'captured'],
      ]);
      expect(r.state.pits, [7, 5]);
      expect(r.state.player, 0);
      expect(r.state.turns, 10);
    });

    test('the turn passes even after a capture (no extra turn)', () {
      final r = applyMove(state([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0]), 0);
      expect(r.state.player, 1);
      expect(r.state.turns, 1);
    });

    test('it does not require 48 seeds or a game that is not over', () {
      final r = applyMove(state([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]), 0);
      expect(r.state.holes[1], 1);
    });
  });

  group('applyMove: illegal moves and immutability', () {
    test('throws ArgumentError for an empty hole', () {
      expect(
        () => applyMove(state([0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4]), 0),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for a hole on the other side', () {
      expect(
        () => applyMove(state(List<int>.filled(12, 4)), 6),
        throwsArgumentError,
      );
      expect(
        () => applyMove(state(List<int>.filled(12, 4), player: 1), 0),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for a hole outside 0..11', () {
      expect(
        () => applyMove(state(List<int>.filled(12, 4)), -1),
        throwsArgumentError,
      );
      expect(
        () => applyMove(state(List<int>.filled(12, 4)), 12),
        throwsArgumentError,
      );
    });

    test('never changes the state it is given', () {
      final start = state(List<int>.filled(12, 4));
      final before = start.toJson();
      applyMove(start, 2);
      expect(start.toJson(), before);
      expect(start, state(List<int>.filled(12, 4)));
    });

    test('the events list is unmodifiable', () {
      final r = applyMove(state(List<int>.filled(12, 4)), 2);
      expect(() => r.events.add(const SowEvent(0)), throwsUnsupportedError);
    });
  });

  group('applyMove: sowing cap', () {
    // Found by random search with a Python port of guide section 4. The relay
    // never ends, so the turn is stopped after 1000 lifts. A real trace would
    // hold 6,184 events, so it is covered here instead of in event_traces.json.
    final start = state([2, 6, 9, 6, 3, 5, 0, 1, 4, 7, 2, 3]);

    test('stops after exactly 1000 lifts with sowing_cap and no capture', () {
      final r = applyMove(start, 4);
      expect(r.events.whereType<LiftEvent>().length, 1000);
      expect(r.events.whereType<CaptureEvent>().length, 0);
      expect(r.events.last, const TurnEndEvent(TurnEndReason.sowingCap));
      expect(r.state.pits, [0, 0]);
      expect(r.state.player, 1);
      expect(r.state.turns, 1);
      expect(r.state.holes, [1, 0, 1, 2, 5, 4, 0, 4, 3, 10, 12, 6]);
    });
  });
}
