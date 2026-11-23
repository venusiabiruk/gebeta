import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/constants.dart' as constants;
import 'package:gebeta/engine/events.dart';
import 'package:gebeta/engine/game_state.dart';
import 'package:gebeta/engine/turn.dart';

// E1-04. Checks the 7 rules for the event stream (guide, section 2) on 10,000
// positions from random play, then replays tests/event_traces.json.
//
// This file does not use rules.dart (Person 2), so it can run before that file
// is finished: legal moves and "game over" are written out below.

/// Holes of the mover that hold at least one seed.
List<int> _legal(GameState s) {
  final start = s.player == 0 ? 0 : 6;
  return [
    for (var h = start; h < start + 6; h++)
      if (s.holes[h] > 0) h,
  ];
}

/// Positions reached by random play from the start position.
List<GameState> _randomPositions(int count, int seed) {
  final random = Random(seed);
  final positions = <GameState>[];
  while (positions.length < count) {
    var s = GameState(
      holes: List<int>.filled(constants.holes, constants.seedsPerHole),
      pits: [0, 0],
      player: random.nextInt(2),
    );
    while (s.turns < constants.gameTurnCap && positions.length < count) {
      final moves = _legal(s);
      if (moves.isEmpty) break;
      positions.add(s);
      s = applyMove(s, moves[random.nextInt(moves.length)]).state;
    }
  }
  return positions;
}

/// Returns a description of the first broken rule, or null when all hold.
String? _checkStream(GameState before, int hole, TurnResult result) {
  final events = result.events;
  final mover = before.player;
  if (events.isEmpty) return 'no events';

  // Rule 1: the first event is a Lift of the chosen hole.
  final first = events.first;
  if (first is! LiftEvent || first.hole != hole) {
    return 'rule 1: first event is $first, expected a lift of hole $hole';
  }

  // Rule 6: exactly one TurnEnd, and it is the last event.
  final ends = events.whereType<TurnEndEvent>().length;
  if (ends != 1 || events.last is! TurnEndEvent) {
    return 'rule 6: $ends TurnEnd events, last is ${events.last}';
  }

  var lifts = 0;
  var lastSow = -1;
  for (var i = 0; i < events.length; i++) {
    final e = events[i];
    if (e is LiftEvent) {
      lifts++;
      // Rule 3: a later Lift lifts the hole of the Sow just before it.
      if (i > 0) {
        final prev = events[i - 1];
        if (prev is! SowEvent || prev.hole != e.hole) {
          return 'rule 3: event $i is $e but the event before is $prev';
        }
      }
      // Rule 2: exactly e.seeds Sow events at h+1, h+2, ... mod 12 follow.
      if (i + e.seeds >= events.length) {
        return 'rule 2: $e is not followed by ${e.seeds} events';
      }
      for (var k = 1; k <= e.seeds; k++) {
        final s = events[i + k];
        final want = (e.hole + k) % constants.holes;
        if (s is! SowEvent || s.hole != want) {
          return 'rule 2: after $e event ${i + k} is $s, expected SowEvent($want)';
        }
        lastSow = s.hole;
      }
      // Rule 2, other direction: the event after the sows is not a Sow.
      if (events[i + e.seeds + 1] is SowEvent) {
        return 'rule 2: more than ${e.seeds} sows after $e';
      }
    } else if (e is CaptureEvent) {
      // Rule 5: a Capture is directly before TurnEnd(captured) and its hole
      // is the opposite of the last Sow's hole.
      final next = i + 1 < events.length ? events[i + 1] : null;
      if (next != const TurnEndEvent(TurnEndReason.captured)) {
        return 'rule 5: capture is followed by $next';
      }
      if (e.hole != opposite(lastSow)) {
        return 'rule 5: captured hole ${e.hole}, last sow was $lastSow';
      }
    }
  }

  // Rule 4: at most sowingCap Lift events.
  if (lifts > constants.sowingCap) return 'rule 4: $lifts lifts';

  // Rule 5, other direction: TurnEnd(captured) always comes with a Capture.
  final end = events.last as TurnEndEvent;
  final hasCapture = events.whereType<CaptureEvent>().isNotEmpty;
  if ((end.reason == TurnEndReason.captured) != hasCapture) {
    return 'rule 5: reason ${end.reason.wire} but capture present: $hasCapture';
  }
  if (events.whereType<CaptureEvent>().length > 1) return 'two captures';

  // Rule 7: replaying the events on a copy of the start board gives the
  // board after the move.
  final board = List<int>.of(before.holes);
  final pits = List<int>.of(before.pits);
  var hand = 0;
  for (final e in events) {
    switch (e) {
      case LiftEvent():
        hand = board[e.hole];
        if (hand != e.seeds) return 'rule 7: $e but the hole held $hand';
        // A relay lifts a hole that was occupied before the last seed landed,
        // so it holds at least 2 seeds now.
        if (e != first && e.seeds < 2) {
          return 'relay from a hole with 1 seed: $e';
        }
        board[e.hole] = 0;
      case SowEvent():
        if (hand <= 0) return 'rule 7: sow with an empty hand';
        hand--;
        board[e.hole]++;
      case CaptureEvent():
        if (board[e.hole] != e.seeds) {
          return 'rule 7: $e but the hole held ${board[e.hole]}';
        }
        pits[mover] += board[e.hole];
        board[e.hole] = 0;
      case TurnEndEvent():
        break;
    }
  }
  if (hand != 0) return 'rule 7: $hand seeds left in the hand';
  if (jsonEncode(board) != jsonEncode(result.state.holes) ||
      jsonEncode(pits) != jsonEncode(result.state.pits)) {
    return 'rule 7: replay gives $board $pits, engine gave '
        '${result.state.holes} ${result.state.pits}';
  }

  // The turn ends in an empty hole (it holds just the landing seed) unless the
  // sowing cap stopped it, and then the landing hole was occupied.
  final landed = board[lastSow];
  if (end.reason == TurnEndReason.sowingCap ? landed < 2 : landed != 1) {
    return 'turn ended with ${end.reason.wire} but the landing hole holds $landed';
  }

  // The reason matches where the last seed landed (section 1, step 4).
  switch (end.reason) {
    case TurnEndReason.opponentSide:
      if (owner(lastSow) == mover) return 'opponent_side on my own side';
    case TurnEndReason.oppositeEmpty:
      if (owner(lastSow) != mover ||
          result.state.holes[opposite(lastSow)] != 0) {
        return 'opposite_empty but the opposite hole held seeds';
      }
    case TurnEndReason.captured:
      if (owner(lastSow) != mover) return 'captured on the opponent side';
    case TurnEndReason.sowingCap:
      if (lifts != constants.sowingCap) return 'sowing_cap after $lifts lifts';
  }

  // Seeds are only moved, never created; the next state is the other player's.
  final total = result.state.holes.fold<int>(0, (a, b) => a + b) +
      result.state.pits[0] +
      result.state.pits[1];
  final before48 = before.holes.fold<int>(0, (a, b) => a + b) +
      before.pits[0] +
      before.pits[1];
  if (total != before48) return 'seeds not conserved: $before48 -> $total';
  if (result.state.pits[1 - mover] != before.pits[1 - mover]) {
    return 'the other player\'s pit changed';
  }
  if (result.state.player != 1 - mover ||
      result.state.turns != before.turns + 1) {
    return 'player or turns not advanced';
  }
  return null;
}

void main() {
  group('event stream rules on random positions', () {
    final positions = _randomPositions(10000, 1);

    test('every position satisfies rules 1 to 7', () {
      final reasons = <TurnEndReason, int>{};
      for (final s in positions) {
        // Check every legal move, not only one, so rare shapes get covered.
        for (final hole in _legal(s)) {
          final r = applyMove(s, hole);
          final problem = _checkStream(s, hole, r);
          expect(problem, null, reason: '$s move $hole: $problem');
          final end = r.events.last as TurnEndEvent;
          reasons[end.reason] = (reasons[end.reason] ?? 0) + 1;
        }
      }
      // The sample must be varied enough to mean something.
      expect(reasons[TurnEndReason.captured]! > 100, true, reason: '$reasons');
      expect(
        reasons[TurnEndReason.opponentSide]! > 100,
        true,
        reason: '$reasons',
      );
      expect(
        reasons[TurnEndReason.oppositeEmpty]! > 100,
        true,
        reason: '$reasons',
      );
    });
  });

  group('tests/event_traces.json', () {
    final file = File('../tests/event_traces.json');
    final text = file.existsSync() ? file.readAsStringSync().trim() : '';

    if (text.isEmpty) {
      // The starter file is committed as an empty file for now.
      test(
        'traces replay exactly',
        () {},
        skip: 'tests/event_traces.json is missing or empty',
      );
      return;
    }

    final data = jsonDecode(text) as Map<String, dynamic>;
    if (data['version'] != 1) {
      // Refuse a file whose version this runner does not know (guide, sec. 5).
      test('version is known', () {
        fail(
          'event_traces.json has version ${data['version']}, runner knows 1',
        );
      });
      return;
    }

    for (final c in data['cases'] as List<dynamic>) {
      final name = c['name'] as String;
      test('trace $name', () {
        final start = GameState(
          holes: List<int>.from(c['holes'] as List),
          pits: List<int>.from(c['pits'] as List),
          player: c['player'] as int,
        );
        final expected = [
          for (final e in c['events'] as List<dynamic>)
            GameEvent.fromJson(e as List<dynamic>),
        ];
        final actual = applyMove(start, c['move'] as int).events;
        for (var i = 0; i < expected.length && i < actual.length; i++) {
          expect(
            actual[i],
            expected[i],
            reason: '$name: event $i differs (got ${actual[i]}, '
                'expected ${expected[i]})',
          );
        }
        expect(
          actual.length,
          expected.length,
          reason: '$name: number of events',
        );
      });
    }
  });
}
