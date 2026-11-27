import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/events.dart';
import 'package:gebeta/engine/game_state.dart';
import 'package:gebeta/engine/turn.dart';
import 'package:gebeta/ui/board/board_model.dart';
import 'package:gebeta/ui/board/turn_player.dart';

// Spec example 3: player 0 plays hole 3, lands in empty hole 4 and captures the
// 2 seeds of the opposite hole 7.
final example3 = GameState(
  holes: [0, 0, 0, 1, 0, 2, 3, 2, 5, 0, 0, 4],
  pits: [0, 0],
  player: 0,
);
const example3Events = <GameEvent>[
  LiftEvent(3, 1),
  SowEvent(4),
  CaptureEvent(7, 2),
  TurnEndEvent(TurnEndReason.captured),
];

TurnPlayer playerFor(
  GameState state,
  List<GameEvent> events, {
  double scale = 1.0,
  void Function(GameEvent)? onStarted,
}) =>
    TurnPlayer(
      model: BoardModel.fromState(state),
      events: events,
      durationScale: scale,
      onEventStarted: onStarted,
    );

void main() {
  group('timings', () {
    test('a lift takes 200 ms and a capture 450 ms', () {
      expect(liftSeconds, 0.2);
      expect(captureSeconds, 0.45);
    });

    test('a sow takes 3000 / sowCount ms, between 30 and 220 ms', () {
      expect(sowSeconds(1), 0.22); // 3000 ms, capped at 220
      expect(sowSeconds(13), closeTo(0.22, 0.01)); // about 231, capped
      expect(sowSeconds(20), closeTo(0.15, 1e-9));
      expect(sowSeconds(30), closeTo(0.10, 1e-9));
      expect(sowSeconds(100), 0.03); // 30 ms, the floor
      expect(sowSeconds(5000), 0.03);
    });

    test('a turn end takes no time', () {
      final p = playerFor(example3, example3Events);
      expect(p.secondsFor(const TurnEndEvent(TurnEndReason.captured)), 0);
    });

    test('the speed setting scales every duration', () {
      final normal = playerFor(example3, example3Events);
      final slow = playerFor(example3, example3Events, scale: 1.6);
      final fast = playerFor(example3, example3Events, scale: 0.6);
      expect(normal.totalSeconds, closeTo(0.2 + 0.22 + 0.45, 1e-9));
      expect(slow.totalSeconds, closeTo(normal.totalSeconds * 1.6, 1e-9));
      expect(fast.totalSeconds, closeTo(normal.totalSeconds * 0.6, 1e-9));
    });

    test('a long turn gets the floor of 30 ms per seed', () {
      final events = <GameEvent>[
        const LiftEvent(0, 120),
        for (var i = 0; i < 120; i++) SowEvent((i + 1) % 12),
      ];
      final p = playerFor(
        GameState(
          holes: [120, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          pits: [0, 0],
          player: 0,
        ),
        events,
      );
      expect(p.secondsFor(const SowEvent(1)), 0.03);
    });
  });

  group('playing a turn', () {
    test('it starts on the first event, before any time has passed', () {
      final p = playerFor(example3, example3Events);
      expect(p.current, const LiftEvent(3, 1));
      expect(p.progress, 0);
      expect(p.isDone, false);
      expect(p.finishedCount, 0);
    });

    test('progress follows the time inside the current event', () {
      final p = playerFor(example3, example3Events);
      p.update(0.1);
      expect(p.current, const LiftEvent(3, 1));
      expect(p.progress, closeTo(0.5, 1e-9));
    });

    test('the board changes when an event ends, not before', () {
      final p = playerFor(example3, example3Events);
      p.update(0.19);
      expect(p.model.holes[3], 1, reason: 'the lift is not over yet');
      expect(p.model.hand, 0);
      p.update(0.02); // the lift ends at 0.2
      expect(p.model.holes[3], 0);
      expect(p.model.hand, 1);
      expect(p.current, const SowEvent(4));
      p.update(0.1);
      expect(p.model.holes[4], 0, reason: 'the seed is still flying');
      p.update(0.13); // the sow ends at 0.2 + 0.22
      expect(p.model.holes[4], 1);
      expect(p.model.hand, 0);
      expect(p.current, const CaptureEvent(7, 2));
      p.update(0.45);
      expect(p.model.pits, [2, 0]);
      expect(p.isDone, true);
      expect(p.current, null);
      expect(p.progress, 0);
    });

    test('a turn end is finished at once and the turn is then done', () {
      final p = playerFor(example3, example3Events);
      p.update(0.2 + 0.22 + 0.45);
      expect(p.isDone, true);
      expect(p.finishedCount, 4);
    });

    test('a long frame finishes several events at once', () {
      final p = playerFor(example3, example3Events);
      p.update(100);
      expect(p.isDone, true);
      expect(
        p.model.matches([0, 0, 0, 0, 1, 2, 3, 0, 5, 0, 0, 4], [2, 0]),
        true,
      );
    });

    test('update does nothing once the turn is done', () {
      final p = playerFor(example3, example3Events);
      p.update(100);
      p.update(1);
      expect(p.isDone, true);
      expect(p.model.pits, [2, 0]);
    });

    test('small frames give the same result as one big frame', () {
      final a = playerFor(example3, example3Events);
      final b = playerFor(example3, example3Events);
      for (var i = 0; i < 200; i++) {
        a.update(1 / 60);
      }
      b.update(200 / 60);
      expect(a.isDone, true);
      expect(a.model.holes, b.model.holes);
      expect(a.model.pits, b.model.pits);
    });

    test('an empty list of events is done at once', () {
      final p = playerFor(example3, const []);
      expect(p.isDone, true);
      p.update(1);
      p.skip();
      expect(p.isDone, true);
    });
  });

  group('onEventStarted', () {
    test('is called once per event, in order, as each one begins', () {
      final started = <GameEvent>[];
      final p = playerFor(example3, example3Events, onStarted: started.add);
      p.update(0);
      expect(started, [example3Events[0]]);
      p.update(0.1);
      expect(started.length, 1);
      p.update(0.1); // the lift ends, the sow begins
      expect(started, example3Events.sublist(0, 2));
      p.update(100);
      expect(started, example3Events);
    });
  });

  group('skip', () {
    test('applies every remaining event at once', () {
      final p = playerFor(example3, example3Events);
      p.update(0.1);
      p.skip();
      expect(p.isDone, true);
      expect(
        p.model.matches([0, 0, 0, 0, 1, 2, 3, 0, 5, 0, 0, 4], [2, 0]),
        true,
      );
      expect(p.model.hand, 0);
    });

    test('does not announce the events it jumps over', () {
      final started = <GameEvent>[];
      final p = playerFor(example3, example3Events, onStarted: started.add);
      p.update(0.1); // the lift began
      p.skip();
      expect(started, [example3Events[0]]);
    });

    test('before anything started, nothing is announced at all', () {
      final started = <GameEvent>[];
      final p = playerFor(example3, example3Events, onStarted: started.add);
      p.skip();
      expect(started, isEmpty);
      expect(p.isDone, true);
    });

    test('does nothing when the turn is already over', () {
      final p = playerFor(example3, example3Events);
      p.update(100);
      p.skip();
      expect(p.model.pits, [2, 0]);
    });
  });

  group('impossible events', () {
    test('update throws StateError, as BoardModel does', () {
      final p = playerFor(
        example3,
        const [SowEvent(4)], // a sow with an empty hand
      );
      expect(() => p.update(1), throwsStateError);
    });

    test('skip throws StateError too', () {
      final p = playerFor(example3, const [LiftEvent(3, 9)]);
      expect(p.skip, throwsStateError);
    });
  });

  group('the reference traces', () {
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
    final expectedByName = {
      for (final c in cases['move_cases'] as List<dynamic>)
        c['name'] as String: c['expect'] as Map<String, dynamic>,
    };

    for (final t in traces['cases'] as List<dynamic>) {
      final name = t['name'] as String;
      final start = GameState(
        holes: List<int>.from(t['holes'] as List),
        pits: List<int>.from(t['pits'] as List),
        player: t['player'] as int,
      );
      final events = [
        for (final e in t['events'] as List<dynamic>)
          GameEvent.fromJson(e as List<dynamic>),
      ];
      final want = expectedByName[name]!;
      final wantHoles = List<int>.from(want['holes'] as List);
      final wantPits = List<int>.from(want['pits'] as List);

      test('trace $name played frame by frame ends on the reference board', () {
        final p = playerFor(start, events);
        var frames = 0;
        while (!p.isDone) {
          p.update(1 / 60);
          frames++;
          expect(frames < 100000, true, reason: '$name never finishes');
        }
        expect(p.model.matches(wantHoles, wantPits), true, reason: name);
        expect(p.model.hand, 0);
        // It took about as long as the timings say.
        expect(frames / 60, closeTo(p.totalSeconds, 0.05), reason: name);
      });

      test('trace $name skipped ends on the reference board', () {
        final p = playerFor(start, events);
        p.skip();
        expect(p.model.matches(wantHoles, wantPits), true, reason: name);
      });
    }
  });

  group('against the real engine', () {
    test('5,000 random turns played in random frames end like applyMove', () {
      final random = Random(5);
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
          final p = playerFor(
            s,
            result.events,
            scale: 0.6 + random.nextDouble(),
          );
          // Frames of random length, then a skip half of the time.
          while (!p.isDone && random.nextInt(4) != 0) {
            p.update(random.nextDouble() * 0.5);
          }
          p.skip();
          expect(
            p.model.matches(result.state.holes, result.state.pits),
            true,
            reason: 'from $s',
          );
          s = result.state;
          checked++;
        }
      }
    });

    test('a turn that hits the sowing cap plays to the end', () {
      final start = GameState(
        holes: [2, 6, 9, 6, 3, 5, 0, 1, 4, 7, 2, 3],
        pits: [0, 0],
        player: 0,
      );
      final result = applyMove(start, 4);
      expect(result.events.whereType<LiftEvent>().length, 1000);
      final p = playerFor(start, result.events);
      p.update(1e6);
      expect(p.isDone, true);
      expect(p.model.matches(result.state.holes, result.state.pits), true);
      // 1000 lifts and thousands of seeds at 30 ms: a long turn, which is why
      // the board offers a skip.
      expect(p.totalSeconds > 100, true, reason: '${p.totalSeconds}');
    });
  });
}
