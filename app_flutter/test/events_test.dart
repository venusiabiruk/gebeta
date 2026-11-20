import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/constants.dart' as constants;
import 'package:gebeta/engine/events.dart';

void main() {
  group('constants', () {
    test('match section 1', () {
      expect(constants.holes, 12);
      expect(constants.seedsPerHole, 4);
      expect(constants.totalSeeds, 48);
      expect(constants.sowingCap, 1000);
      expect(constants.gameTurnCap, 300);
      expect(constants.draw, -1);
      expect(constants.holes * constants.seedsPerHole, constants.totalSeeds);
    });
  });

  group('TurnEndReason', () {
    test('wire strings are exactly the four from the guide', () {
      expect(TurnEndReason.captured.wire, 'captured');
      expect(TurnEndReason.opponentSide.wire, 'opponent_side');
      expect(TurnEndReason.oppositeEmpty.wire, 'opposite_empty');
      expect(TurnEndReason.sowingCap.wire, 'sowing_cap');
    });

    test('fromWire round trips every reason', () {
      for (final reason in TurnEndReason.values) {
        expect(TurnEndReasonWire.fromWire(reason.wire), reason);
      }
    });

    test('fromWire throws ArgumentError on unknown text', () {
      expect(() => TurnEndReasonWire.fromWire('nonsense'), throwsArgumentError);
      expect(
        () => TurnEndReasonWire.fromWire('opponentSide'),
        throwsArgumentError,
      );
      expect(() => TurnEndReasonWire.fromWire(''), throwsArgumentError);
    });
  });

  group('GameEvent JSON', () {
    test('toJson gives the array forms of the guide', () {
      expect(const LiftEvent(2, 4).toJson(), ['lift', 2, 4]);
      expect(const SowEvent(4).toJson(), ['sow', 4]);
      expect(const CaptureEvent(7, 2).toJson(), ['capture', 7, 2]);
      expect(const TurnEndEvent(TurnEndReason.captured).toJson(), [
        'turn_end',
        'captured',
      ]);
      expect(const TurnEndEvent(TurnEndReason.opponentSide).toJson(), [
        'turn_end',
        'opponent_side',
      ]);
    });

    test('fromJson parses the array forms of the guide', () {
      expect(GameEvent.fromJson(['lift', 3, 1]), const LiftEvent(3, 1));
      expect(GameEvent.fromJson(['sow', 4]), const SowEvent(4));
      expect(GameEvent.fromJson(['capture', 7, 2]), const CaptureEvent(7, 2));
      expect(
        GameEvent.fromJson(['turn_end', 'sowing_cap']),
        const TurnEndEvent(TurnEndReason.sowingCap),
      );
    });

    test('every event survives a round trip', () {
      const events = <GameEvent>[
        LiftEvent(0, 12),
        SowEvent(11),
        CaptureEvent(5, 40),
        TurnEndEvent(TurnEndReason.oppositeEmpty),
      ];
      for (final e in events) {
        expect(GameEvent.fromJson(e.toJson()), e);
      }
    });

    test('fromJson rejects malformed events with ArgumentError', () {
      final bad = <List<dynamic>>[
        [],
        ['lift'],
        ['lift', 1],
        ['lift', 1, 2, 3],
        ['lift', '1', 2],
        ['lift', 1.5, 2],
        ['sow'],
        ['sow', 1, 2],
        ['capture', 1],
        ['turn_end'],
        ['turn_end', 5],
        ['turn_end', 'nonsense'],
        ['jump', 1],
        [3, 4],
      ];
      for (final json in bad) {
        expect(
          () => GameEvent.fromJson(json),
          throwsArgumentError,
          reason: '$json',
        );
      }
    });
  });

  group('GameEvent equality', () {
    test('equal events are equal and share a hash code', () {
      expect(const LiftEvent(1, 2), const LiftEvent(1, 2));
      expect(const LiftEvent(1, 2).hashCode, const LiftEvent(1, 2).hashCode);
      expect(const SowEvent(3), const SowEvent(3));
      expect(const SowEvent(3).hashCode, const SowEvent(3).hashCode);
      expect(const CaptureEvent(4, 5), const CaptureEvent(4, 5));
      expect(
        const CaptureEvent(4, 5).hashCode,
        const CaptureEvent(4, 5).hashCode,
      );
      expect(
        const TurnEndEvent(TurnEndReason.captured),
        const TurnEndEvent(TurnEndReason.captured),
      );
      expect(
        const TurnEndEvent(TurnEndReason.captured).hashCode,
        const TurnEndEvent(TurnEndReason.captured).hashCode,
      );
    });

    test('different events are not equal', () {
      expect(const LiftEvent(1, 2) == const LiftEvent(1, 3), false);
      expect(const LiftEvent(1, 2) == const LiftEvent(2, 2), false);
      expect(const SowEvent(3) == const SowEvent(4), false);
      expect(const CaptureEvent(4, 5) == const CaptureEvent(5, 5), false);
      expect(
        const TurnEndEvent(TurnEndReason.captured) ==
            const TurnEndEvent(TurnEndReason.sowingCap),
        false,
      );
    });

    test('events of different kinds are never equal', () {
      // Lift and Capture both hold (hole, seeds).
      expect(const LiftEvent(1, 2) == const CaptureEvent(1, 2), false);
      expect(const CaptureEvent(1, 2) == const LiftEvent(1, 2), false);
    });

    test('lists of events compare with ==, as the trace runner needs', () {
      final a = <GameEvent>[const LiftEvent(3, 1), const SowEvent(4)];
      final b = <GameEvent>[
        GameEvent.fromJson(['lift', 3, 1]),
        GameEvent.fromJson(['sow', 4]),
      ];
      expect(a, b);
    });
  });
}