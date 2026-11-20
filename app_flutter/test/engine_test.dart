import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/encoding.dart';
import 'package:gebeta/engine/game_state.dart';

// The version of the test files this runner understands (guide section 5).
const int knownVersion = 1;

Map<String, dynamic>? loadJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError(
        'Missing test file: $path (run flutter test inside app_flutter/)');
  }
  final raw = file.readAsStringSync().trim();
  if (raw.isEmpty) {
    return null;
  }
  final data = jsonDecode(raw) as Map<String, dynamic>;
  if (data['version'] != knownVersion) {
    throw StateError(
        '$path has version ${data['version']}, this runner knows $knownVersion');
  }
  return data;
}

GameState stateOf(Map<String, dynamic> c) => GameState(
      holes: List<int>.from(c['holes'] as List),
      pits: List<int>.from(c['pits'] as List),
      player: c['player'] as int,
      turns: (c['turns'] as int?) ?? 0,
    );

void main() {
  final cases = loadJson('../tests/test_cases.json');
  final traces = loadJson('../tests/event_traces.json');

  if (cases == null) {
    test('encode on every move case', () {},
        skip: 'tests/test_cases.json is currently empty on main');
  } else {
    final moveCases =
        (cases['move_cases'] as List).cast<Map<String, dynamic>>();
    group('encode on every move case', () {
      for (final c in moveCases) {
        test(c['name'] as String, () {
          expect(
            encode(stateOf(c)),
            equals(List<int>.from(c['encoded'] as List)),
            reason: 'case ${c['name']}: field "encoded" differs',
          );
        });
      }
    });
  }

  test('decodeMove: start + k for both players', () {
    final p0 = GameState(holes: List.filled(12, 4), pits: [0, 0], player: 0);
    final p1 = GameState(holes: List.filled(12, 4), pits: [0, 0], player: 1);
    expect(decodeMove(p0, 3), 3);
    expect(decodeMove(p1, 3), 9);
  });

  // Unfinished parts: skipped until the Dart engine exists.
  test('legalMoves on every move case', () {},
      skip: 'rules.dart is not written yet (E2)');
  test('applyMove: holes, pits, turn end reason, next player', () {},
      skip: 'turn.dart is not written yet (E1)');
  test('end cases: isGameOver, finalPits, winner', () {},
      skip: 'rules.dart is not written yet (E2)');
  test(
      'event traces (${traces == null ? 0 : (traces['cases'] as List).length} cases)',
      () {},
      skip: 'turn.dart is not written yet (E1)');
}