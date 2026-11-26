import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/engine.dart';

// Replays tests/crosscheck.json (made by tools/make_crosscheck.py) with the
// Dart engine. The file is not committed, so the test skips itself without it.
void main() {
  final file = File('../tests/crosscheck.json');
  final missing = !file.existsSync();

  test(
    'crosscheck: Dart applyMove matches Python on every case',
    () {
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      if (data['version'] != 1) {
        throw StateError('crosscheck.json version ${data['version']}, runner knows 1');
      }
      final cases = (data['cases'] as List).cast<Map<String, dynamic>>();
      final problems = <String>[];

      for (final c in cases) {
        final state = GameState(
          holes: List<int>.from(c['holes'] as List),
          pits: List<int>.from(c['pits'] as List),
          player: c['player'] as int,
          turns: c['turns'] as int,
        );
        final want = c['expect'] as Map<String, dynamic>;
        final result = applyMove(state, c['move'] as int);
        final name = c['name'];

        if (result.state.holes.join(',') != (want['holes'] as List).join(',')) {
          problems.add('$name: holes differ');
        }
        if (result.state.pits.join(',') != (want['pits'] as List).join(',')) {
          problems.add('$name: pits differ');
        }
        if (result.state.player != want['player']) {
          problems.add('$name: next player differs');
        }
        if (result.state.turns != want['turns']) {
          problems.add('$name: turns differ');
        }
        final wantEvents = (want['events'] as List)
            .map((e) => GameEvent.fromJson(e as List<dynamic>))
            .toList();
        if (result.events.length != wantEvents.length) {
          problems.add('$name: event count differs');
        } else {
          for (var i = 0; i < wantEvents.length; i++) {
            if (result.events[i] != wantEvents[i]) {
              problems.add('$name: event $i differs');
              break;
            }
          }
        }
      }

      expect(problems, isEmpty,
          reason: '${problems.length} mismatches, first: ${problems.take(20).toList()}');
    },
    skip: missing ? 'tests/crosscheck.json not generated (run make_crosscheck.py)' : false,
  );
}