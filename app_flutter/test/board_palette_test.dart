import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/ui/board/board_palette.dart';
import 'package:gebeta/ui/board/pebbles.dart';

/// WCAG contrast ratio between two colors: 1 (identical) to 21 (black on white).
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const palettes = <String, BoardPalette>{
    'darkWood': BoardPalette.darkWood,
    'lightWood': BoardPalette.lightWood,
  };

  group('BoardPalette', () {
    for (final entry in palettes.entries) {
      final name = entry.key;
      final p = entry.value;

      test('$name has one pebble color per shade', () {
        expect(p.pebbles.length, pebbleShades);
      });

      test(
        '$name: the count is readable on its pill (contrast at least 4.5)',
        () {
          expect(
            contrast(p.pillText, p.pillFill) >= 4.5,
            true,
            reason: '${contrast(p.pillText, p.pillFill)}',
          );
        },
      );

      test(
          '$name: the ring stands out on the hole and on the board '
          '(contrast at least 3)', () {
        for (final background in [p.holeFill, p.boardTop, p.boardBottom]) {
          expect(
            contrast(p.ring, background) >= 3,
            true,
            reason: 'ring on $background: ${contrast(p.ring, background)}',
          );
        }
      });

      test(
          '$name: every pebble shade can be seen on the hole '
          '(contrast at least 2)', () {
        for (final pebble in p.pebbles) {
          expect(
            contrast(pebble, p.holeFill) >= 2,
            true,
            reason: '$pebble on the hole: ${contrast(pebble, p.holeFill)}',
          );
        }
      });

      test(
        '$name: the hole is darker than the board, as a recess should be',
        () {
          expect(
            p.holeFill.computeLuminance() < p.boardBottom.computeLuminance(),
            true,
          );
          expect(
            p.holeShade.computeLuminance() < p.holeFill.computeLuminance(),
            true,
          );
        },
      );
    }

    test('the light palette is lighter than the dark one', () {
      expect(
        BoardPalette.lightWood.boardTop.computeLuminance() >
            BoardPalette.darkWood.boardTop.computeLuminance(),
        true,
      );
    });
  });
}
