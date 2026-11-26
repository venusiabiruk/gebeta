import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/ui/board/pebbles.dart';

void main() {
  group('pebblesFor', () {
    test('draws one pebble per seed, up to the cap', () {
      expect(pebblesFor(0, seed: 1), isEmpty);
      for (var n = 1; n <= defaultMaxPebbles; n++) {
        expect(pebblesFor(n, seed: 1).length, n);
      }
      expect(pebblesFor(13, seed: 1).length, defaultMaxPebbles);
      expect(pebblesFor(40, seed: 1).length, defaultMaxPebbles);
      expect(pebblesFor(48, seed: 1).length, defaultMaxPebbles);
    });

    test('a negative count draws nothing', () {
      expect(pebblesFor(-3, seed: 1), isEmpty);
    });

    test('a bigger cap draws more (used for the pits)', () {
      expect(pebblesFor(40, seed: 1, maxVisible: 30).length, 30);
      expect(pebblesFor(20, seed: 1, maxVisible: 30).length, 20);
    });

    test('it is stable: adding a seed adds one pebble and moves none', () {
      for (var seed = 0; seed < 12; seed++) {
        final all = pebblesFor(defaultMaxPebbles, seed: seed);
        for (var n = 0; n <= defaultMaxPebbles; n++) {
          expect(
            pebblesFor(n, seed: seed),
            all.sublist(0, n),
            reason: 'seed $seed, $n seeds',
          );
        }
      }
    });

    test('a hole above the cap looks the same as a full one', () {
      expect(pebblesFor(40, seed: 3), pebblesFor(defaultMaxPebbles, seed: 3));
    });

    test('it is repeatable, and different holes look different', () {
      expect(pebblesFor(8, seed: 5), pebblesFor(8, seed: 5));
      expect(pebblesFor(8, seed: 5) == pebblesFor(8, seed: 6), false);
      final a = pebblesFor(8, seed: 5);
      final b = pebblesFor(8, seed: 6);
      expect(a.first == b.first, false);
    });

    test('every pebble lies inside the hole, for every seed and count', () {
      for (var seed = 0; seed < 50; seed++) {
        for (final p in pebblesFor(defaultMaxPebbles, seed: seed)) {
          final reach = math.sqrt(p.x * p.x + p.y * p.y) + p.radius;
          expect(reach <= 1.0, true, reason: 'seed $seed $p reaches $reach');
        }
      }
    });

    test('pebbles inside a bigger-cap pit also stay inside the disc', () {
      for (var seed = 0; seed < 5; seed++) {
        for (final p in pebblesFor(48, seed: seed, maxVisible: 30)) {
          expect(math.sqrt(p.x * p.x + p.y * p.y) + p.radius <= 1.0, true);
        }
      }
    });

    test('the pebbles of one hole do not sit on top of each other', () {
      for (var seed = 0; seed < 20; seed++) {
        final ps = pebblesFor(defaultMaxPebbles, seed: seed);
        for (var i = 0; i < ps.length; i++) {
          for (var j = i + 1; j < ps.length; j++) {
            final d = math.sqrt(
              math.pow(ps[i].x - ps[j].x, 2) + math.pow(ps[i].y - ps[j].y, 2),
            );
            expect(d > 0.08, true, reason: 'seed $seed pebbles $i and $j');
          }
        }
      }
    });

    test('shades are valid and all of them get used', () {
      final shades = <int>{};
      for (var seed = 0; seed < 20; seed++) {
        for (final p in pebblesFor(defaultMaxPebbles, seed: seed)) {
          expect(p.shade >= 0 && p.shade < pebbleShades, true);
          shades.add(p.shade);
        }
      }
      expect(shades.length, pebbleShades);
    });

    test('angles are in a half turn', () {
      for (final p in pebblesFor(defaultMaxPebbles, seed: 2)) {
        expect(p.angle >= 0 && p.angle <= math.pi, true);
      }
    });
  });
}
