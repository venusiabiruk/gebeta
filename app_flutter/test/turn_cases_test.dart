import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/events.dart';
import 'package:gebeta/engine/game_state.dart';
import 'package:gebeta/engine/turn.dart';

// E1-03 "done when": applyMove reproduces the move cases of
// tests/test_cases.json (guide, section 5). For each case it checks the holes,
// the pits, the reason of the last TurnEnd and the next player, and when it
// fails it names the case and the field that differs.
//
// legal_moves and encoded belong to rules.dart and encoding.dart (Persons 2
// and 3), so they are checked by the shared runner (engine_test.dart), not here.

const int _knownVersion = 1;

void main() {
  final file = File('../tests/test_cases.json');
  final text = file.existsSync() ? file.readAsStringSync().trim() : '';

  if (text.isEmpty) {
    test(
      'applyMove reproduces the move cases',
      () {},
      skip: 'tests/test_cases.json is missing or empty',
    );
    return;
  }

  final data = jsonDecode(text) as Map<String, dynamic>;
  if (data['version'] != _knownVersion) {
    // Refuse a file whose version this runner does not know (guide, sec. 5).
    test('version is known', () {
      fail(
        'test_cases.json has version ${data['version']}, runner knows '
        '$_knownVersion',
      );
    });
    return;
  }

  test('applyMove reproduces every move case', () {
    final cases = data['move_cases'] as List<dynamic>;
    final problems = <String>[];

    for (final c in cases) {
      final name = c['name'] as String;
      final start = GameState(
        holes: List<int>.from(c['holes'] as List),
        pits: List<int>.from(c['pits'] as List),
        player: c['player'] as int,
        turns: (c['turns'] as int?) ?? 0,
      );
      final expected = c['expect'] as Map<String, dynamic>;
      final result = applyMove(start, c['move'] as int);

      void check(String field, Object? got, Object? want) {
        if (jsonEncode(got) != jsonEncode(want)) {
          problems.add('$name: $field is $got, expected $want');
        }
      }

      check('holes', result.state.holes, expected['holes']);
      check('pits', result.state.pits, expected['pits']);
      check('next_player', result.state.player, expected['next_player']);
      check('turns', result.state.turns, start.turns + 1);
      final last = result.events.last;
      check(
        'turn_ended',
        last is TurnEndEvent ? last.reason.wire : null,
        expected['turn_ended'],
      );
    }

    expect(cases.length, greaterThan(0));
    expect(problems, isEmpty, reason: problems.take(10).join('\n'));
  });
}
