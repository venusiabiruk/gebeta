import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/events.dart';
import 'package:gebeta/engine/game_state.dart';
import 'package:gebeta/engine/turn.dart';
import 'package:gebeta/ui/board/board_model.dart';

BoardModel model(
  List<int> holes, {
  List<int> pits = const [0, 0],
  int mover = 0,
}) =>
    BoardModel(holes: holes, pits: pits, mover: mover);

void main() {
  group('BoardModel: one event at a time', () {
    test('it copies the lists it is given', () {
      final holes = List<int>.filled(12, 4);
      final pits = [0, 0];
      final m = model(holes, pits: pits);
      holes[0] = 99;
      pits[0] = 99;
      expect(m.holes[0], 4);
      expect(m.pits[0], 0);
    });

    test('fromState takes holes, pits and the mover from the state', () {
      final m = BoardModel.fromState(
        GameState(holes: List<int>.filled(12, 4), pits: [3, 5], player: 1),
      );
      expect(m.mover, 1);
      expect(m.pits, [3, 5]);
      expect(m.hand, 0);
      expect(m.lastLifted, null);
      expect(m.lastSown, null);
    });

    test('Lift moves the hole into the hand', () {
      final m = model([0, 0, 0, 1, 0, 2, 3, 2, 5, 0, 0, 4]);
      m.apply(const LiftEvent(5, 2));
      expect(m.holes[5], 0);
      expect(m.hand, 2);
      expect(m.lastLifted, 5);
    });

    test('Sow drops one seed from the hand', () {
      final m = model([0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0]);
      m.apply(const LiftEvent(5, 2));
      m.apply(const SowEvent(6));
      expect(m.holes[6], 1);
      expect(m.hand, 1);
      expect(m.lastSown, 6);
      m.apply(const SowEvent(7));
      expect(m.holes[7], 1);
      expect(m.hand, 0);
      expect(m.lastSown, 7);
    });

    test('Capture moves the hole into the mover\'s pit', () {
      final m0 = model([0, 0, 0, 0, 1, 0, 0, 2, 0, 0, 0, 0]);
      m0.apply(const CaptureEvent(7, 2));
      expect(m0.holes[7], 0);
      expect(m0.pits, [2, 0]);
    });

    test('player 1 captures into pit 1', () {
      final m = model(
        [3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
        pits: [4, 1],
        mover: 1,
      );
      m.apply(const CaptureEvent(0, 3));
      expect(m.pits, [4, 4]);
      expect(m.holes[0], 0);
    });

    test('TurnEnd changes no counts', () {
      final m = model(List<int>.filled(12, 4), pits: [1, 2]);
      m.apply(const TurnEndEvent(TurnEndReason.opponentSide));
      expect(m.holes, List<int>.filled(12, 4));
      expect(m.pits, [1, 2]);
    });
  });

  group('BoardModel: events that cannot happen', () {
    test('Sow with an empty hand', () {
      expect(
        () => model(List<int>.filled(12, 4)).apply(const SowEvent(1)),
        throwsStateError,
      );
    });

    test('Lift that disagrees with the hole', () {
      expect(
        () => model(List<int>.filled(12, 4)).apply(const LiftEvent(2, 5)),
        throwsStateError,
      );
    });

    test('Lift while seeds are still in the hand', () {
      final m = model(List<int>.filled(12, 4));
      m.apply(const LiftEvent(2, 4));
      expect(() => m.apply(const LiftEvent(5, 4)), throwsStateError);
    });

    test('Capture that disagrees with the hole', () {
      expect(
        () => model(List<int>.filled(12, 4)).apply(const CaptureEvent(7, 9)),
        throwsStateError,
      );
    });

    test('TurnEnd with seeds still in the hand', () {
      final m = model(List<int>.filled(12, 4));
      m.apply(const LiftEvent(2, 4));
      expect(
        () => m.apply(const TurnEndEvent(TurnEndReason.captured)),
        throwsStateError,
      );
    });
  });

  group('BoardModel.matches', () {
    test('true for equal counts, false for any difference', () {
      final holes = [0, 0, 0, 1, 0, 2, 3, 2, 5, 0, 0, 4];
      final m = model(holes, pits: [2, 7]);
      expect(m.matches(holes, [2, 7]), true);
      final other = List<int>.of(holes)..[11] = 5;
      expect(m.matches(other, [2, 7]), false);
      expect(m.matches(holes, [2, 8]), false);
      expect(m.matches(holes, [7, 2]), false);
    });
  });

  group('BoardModel replays the reference traces', () {
    final traceFile = File('../tests/event_traces.json');
    final caseFile = File('../tests/test_cases.json');
    final traceText =
        traceFile.existsSync() ? traceFile.readAsStringSync() : '';
    final caseText = caseFile.existsSync() ? caseFile.readAsStringSync() : '';

    if (traceText.trim().isEmpty || caseText.trim().isEmpty) {
      test(
        'every trace ends on the reference board',
        () {},
        skip: 'tests/event_traces.json or test_cases.json is missing or empty',
      );
      return;
    }

    final traces = jsonDecode(traceText) as Map<String, dynamic>;
    final cases = jsonDecode(caseText) as Map<String, dynamic>;
    if (traces['version'] != 1 || cases['version'] != 1) {
      test('versions are known', () {
        fail('event_traces.json / test_cases.json version is not 1');
      });
      return;
    }

    // The final board of each trace comes from test_cases.json (made by the
    // independent reference simulator), found by the case name.
    final expectedByName = {
      for (final c in cases['move_cases'] as List<dynamic>)
        c['name'] as String: c['expect'] as Map<String, dynamic>,
    };

    for (final t in traces['cases'] as List<dynamic>) {
      final name = t['name'] as String;
      test('trace $name ends on the reference board', () {
        final start = GameState(
          holes: List<int>.from(t['holes'] as List),
          pits: List<int>.from(t['pits'] as List),
          player: t['player'] as int,
        );
        final m = BoardModel.fromState(start);
        for (final e in t['events'] as List<dynamic>) {
          m.apply(GameEvent.fromJson(e as List<dynamic>));
        }
        final want = expectedByName[name];
        expect(want, isNotNull, reason: '$name is not in test_cases.json');
        expect(m.hand, 0, reason: '$name: seeds left in the hand');
        expect(
          m.holes,
          List<int>.from(want!['holes'] as List),
          reason: '$name: holes',
        );
        expect(
          m.pits,
          List<int>.from(want['pits'] as List),
          reason: '$name: pits',
        );
      });
    }
  });

  group('BoardModel replays what the engine produces', () {
    test('5,000 random turns: model and applyMove end on the same board', () {
      final random = Random(2);
      var checked = 0;
      while (checked < 5000) {
        var s = GameState(
          holes: List<int>.filled(12, 4),
          pits: [0, 0],
          player: random.nextInt(2),
        );
        while (s.turns < 300 && checked < 5000) {
          final start = s.player == 0 ? 0 : 6;
          final moves = [
            for (var h = start; h < start + 6; h++)
              if (s.holes[h] > 0) h,
          ];
          if (moves.isEmpty) break;
          final result = applyMove(s, moves[random.nextInt(moves.length)]);
          final m = BoardModel.fromState(s);
          for (final e in result.events) {
            m.apply(e);
          }
          expect(
            m.matches(result.state.holes, result.state.pits),
            true,
            reason: 'from $s',
          );
          expect(m.hand, 0);
          s = result.state;
          checked++;
        }
      }
    });
  });
}
