import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/engine.dart';

// The shared Dart test runner. It reads the files in ../tests/ and checks the
// Dart engine against the answers that came from the Python reference.
// Run it from the app_flutter folder (flutter test does that by itself).

/// The file version this runner understands.
const int knownVersion = 1;

/// Read a test file. Stop with a clear message when the file is missing or its
/// version is not the one this runner knows, so a format change cannot pass silently.
Map<String, dynamic> loadJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError(
        'Test file not found: $path (run flutter test from app_flutter/)');
  }
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  if (data['version'] != knownVersion) {
    throw StateError(
      '$path has version ${data['version']}, but this runner only knows version '
      '$knownVersion. Update the runner, the guide and the other engine together.',
    );
  }
  return data;
}

List<int> ints(Object? list) => List<int>.from(list as List);

/// The position described by a case. A missing turn count means 0.
GameState stateFrom(Map<String, dynamic> c) {
  return GameState(
    holes: ints(c['holes']),
    pits: ints(c['pits']),
    player: c['player'] as int,
    turns: (c['turns'] as int?) ?? 0,
  );
}

/// Compare two event lists. The message names the first event that differs.
void expectSameEvents(
    String name, List<GameEvent> actual, List<GameEvent> expected) {
  final shortest =
      actual.length < expected.length ? actual.length : expected.length;
  for (var i = 0; i < shortest; i++) {
    final got = jsonEncode(actual[i].toJson());
    final want = jsonEncode(expected[i].toJson());
    expect(got, want, reason: 'case $name: event #$i');
  }
  expect(actual.length, expected.length,
      reason: 'case $name: number of events');
  expect(actual, equals(expected),
      reason: 'case $name: events are not equal with ==');
}

void main() {
  final cases = loadJson('../tests/test_cases.json');
  final traces = loadJson('../tests/event_traces.json');

  group('move cases', () {
    for (final item in cases['move_cases'] as List<dynamic>) {
      final c = item as Map<String, dynamic>;
      final name = c['name'] as String;

      test(name, () {
        final state = stateFrom(c);

        expect(legalMoves(state), ints(c['legal_moves']),
            reason: 'case $name: legal_moves');
        expect(encode(state), ints(c['encoded']),
            reason: 'case $name: encoded');

        final result = applyMove(state, c['move'] as int);
        final expected = c['expect'] as Map<String, dynamic>;
        expect(result.state.holes, ints(expected['holes']),
            reason: 'case $name: holes');
        expect(result.state.pits, ints(expected['pits']),
            reason: 'case $name: pits');
        expect(
          result.state.player,
          expected['next_player'],
          reason: 'case $name: next_player',
        );
        expect(result.state.turns, state.turns + 1,
            reason: 'case $name: turns');

        final last = result.events.last;
        if (last is TurnEndEvent) {
          expect(last.reason.wire, expected['turn_ended'],
              reason: 'case $name: turn_ended');
        } else {
          fail('case $name: the last event is not a turn_end');
        }
      });
    }
  });

  group('end cases', () {
    for (final item in cases['end_cases'] as List<dynamic>) {
      final c = item as Map<String, dynamic>;
      final name = c['name'] as String;

      test(name, () {
        final state = stateFrom(c);
        final expected = c['expect'] as Map<String, dynamic>;

        expect(isGameOver(state), expected['game_over'],
            reason: 'case $name: game_over');
        if (expected['game_over'] == true) {
          expect(finalPits(state), ints(expected['final_pits']),
              reason: 'case $name: final_pits');
          expect(winner(state), expected['winner'],
              reason: 'case $name: winner');
        }
      });
    }
  });

  group('event traces', () {
    for (final item in traces['cases'] as List<dynamic>) {
      final c = item as Map<String, dynamic>;
      final name = c['name'] as String;

      test(name, () {
        final state = stateFrom(c);
        final expected = <GameEvent>[];
        for (final e in c['events'] as List<dynamic>) {
          expected.add(GameEvent.fromJson(e as List<dynamic>));
        }

        final result = applyMove(state, c['move'] as int);
        expectSameEvents(name, result.events, expected);
      });
    }
  });
}
