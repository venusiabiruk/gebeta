import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/ui/board/layout.dart';

const sizes = <Size>[
  designSize,
  Size(400, 300),
  Size(1200, 500),
  Size(667, 375),
];

void expectNear(Offset a, Offset b, {String? reason}) {
  expect((a - b).distance, lessThan(1e-9), reason: '$reason: $a vs $b');
}

void main() {
  group('holeCenter and pitCenter', () {
    test('the 12 holes and 2 pits are all distinct and inside the board', () {
      for (final size in sizes) {
        final all = <Offset>[
          for (var h = 0; h < 12; h++) holeCenter(h, size),
          pitCenter(0, size),
          pitCenter(1, size),
        ];
        expect(all.toSet().length, 14, reason: '$size');
        for (final p in all) {
          expect(p.dx > 0 && p.dx < size.width, true, reason: '$size $p');
          expect(p.dy > 0 && p.dy < size.height, true, reason: '$size $p');
        }
      }
    });

    test('the bottom row runs left to right, holes 0 to 5', () {
      for (final size in sizes) {
        for (var h = 0; h < 5; h++) {
          expect(
            holeCenter(h, size).dx < holeCenter(h + 1, size).dx,
            true,
            reason: '$size hole $h',
          );
          expect(holeCenter(h, size).dy, holeCenter(0, size).dy);
        }
      }
    });

    test(
      'the top row runs right to left: hole 6 on the right, 11 on the left',
      () {
        for (final size in sizes) {
          for (var h = 6; h < 11; h++) {
            expect(
              holeCenter(h, size).dx > holeCenter(h + 1, size).dx,
              true,
              reason: '$size hole $h',
            );
            expect(holeCenter(h, size).dy, holeCenter(6, size).dy);
          }
          // Player 0's row is below player 1's row (screen y grows downwards).
          expect(holeCenter(0, size).dy > holeCenter(6, size).dy, true);
        }
      },
    );

    test(
        'play goes from hole 5 up to hole 6, on the right, and 11 to 0 on the '
        'left', () {
      for (final size in sizes) {
        expect(holeCenter(5, size).dx, holeCenter(6, size).dx);
        expect(holeCenter(11, size).dx, holeCenter(0, size).dx);
      }
    });

    test('a hole faces its opposite hole (11 - hole): same column', () {
      for (final size in sizes) {
        for (var h = 0; h < 12; h++) {
          expect(
            holeCenter(h, size).dx,
            holeCenter(11 - h, size).dx,
            reason: '$size hole $h',
          );
          expect(holeCenter(h, size).dy == holeCenter(11 - h, size).dy, false);
        }
      }
    });

    test('pit 0 is at the right end and pit 1 at the left end', () {
      for (final size in sizes) {
        final xs = [for (var h = 0; h < 12; h++) holeCenter(h, size).dx];
        final minX = xs.reduce((a, b) => a < b ? a : b);
        final maxX = xs.reduce((a, b) => a > b ? a : b);
        expect(pitCenter(0, size).dx > maxX, true, reason: '$size');
        expect(pitCenter(1, size).dx < minX, true, reason: '$size');
        expect(pitCenter(0, size).dy, size.height / 2);
        expect(pitCenter(1, size).dy, size.height / 2);
      }
    });

    test('positions scale with the size', () {
      const small = designSize;
      const big = Size(844 * 2, 390 * 2);
      for (var h = 0; h < 12; h++) {
        expectNear(
          holeCenter(h, big),
          holeCenter(h, small) * 2,
          reason: 'hole $h',
        );
      }
      for (var p = 0; p < 2; p++) {
        expectNear(
          pitCenter(p, big),
          pitCenter(p, small) * 2,
          reason: 'pit $p',
        );
      }
    });
  });

  group('flip', () {
    test('flip rotates every position by 180 degrees', () {
      for (final size in sizes) {
        for (var h = 0; h < 12; h++) {
          expectNear(
            holeCenter(h, size, flip: true),
            rotate180(holeCenter(h, size), size),
            reason: 'hole $h',
          );
        }
        for (var p = 0; p < 2; p++) {
          expectNear(
            pitCenter(p, size, flip: true),
            rotate180(pitCenter(p, size), size),
            reason: 'pit $p',
          );
        }
      }
    });

    test('flipping twice returns the original', () {
      for (final size in sizes) {
        for (var h = 0; h < 12; h++) {
          expectNear(
            rotate180(holeCenter(h, size, flip: true), size),
            holeCenter(h, size),
            reason: 'hole $h',
          );
        }
        for (var p = 0; p < 2; p++) {
          expectNear(
            rotate180(pitCenter(p, size, flip: true), size),
            pitCenter(p, size),
            reason: 'pit $p',
          );
        }
      }
    });

    test(
        'flip puts player 1 at the bottom: pit 1 on the right, holes 6 to 11 '
        'on the lower row', () {
      for (final size in sizes) {
        expect(
          holeCenter(6, size, flip: true).dy >
              holeCenter(0, size, flip: true).dy,
          true,
        );
        expect(
          pitCenter(1, size, flip: true).dx > pitCenter(0, size, flip: true).dx,
          true,
        );
        // Play still goes left to right along the (new) bottom row: 6 to 11.
        for (var h = 6; h < 11; h++) {
          expect(
            holeCenter(h, size, flip: true).dx <
                holeCenter(h + 1, size, flip: true).dx,
            true,
            reason: '$size hole $h',
          );
        }
      }
    });

    test('flip keeps all 14 positions distinct and inside the board', () {
      for (final size in sizes) {
        final all = <Offset>[
          for (var h = 0; h < 12; h++) holeCenter(h, size, flip: true),
          pitCenter(0, size, flip: true),
          pitCenter(1, size, flip: true),
        ];
        expect(all.toSet().length, 14);
        for (final p in all) {
          expect(p.dx > 0 && p.dx < size.width, true);
          expect(p.dy > 0 && p.dy < size.height, true);
        }
      }
    });
  });
}
