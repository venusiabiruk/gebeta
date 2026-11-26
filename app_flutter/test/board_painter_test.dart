import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

// import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/ui/board/board_painter.dart';
import 'package:gebeta/ui/board/board_palette.dart';

// These tests draw into an off-screen image and look at its pixels, so they
// check what the player would see without opening a window.

const palettes = <BoardPalette>[BoardPalette.darkWood, BoardPalette.lightWood];

/// Draws with [draw] on a [width] x [height] canvas and returns the RGBA bytes.
Future<ByteData> render(
  int width,
  int height,
  void Function(Canvas canvas) draw,
) async {
  final recorder = PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = (await image.toByteData())!;
  image.dispose();
  picture.dispose();
  return data;
}

Color pixelAt(ByteData data, int width, int x, int y) {
  final i = (y * width + x) * 4;
  return Color.fromARGB(
    data.getUint8(i + 3),
    data.getUint8(i),
    data.getUint8(i + 1),
    data.getUint8(i + 2),
  );
}

bool sameBytes(ByteData a, ByteData b) {
  final x = a.buffer.asUint8List(a.offsetInBytes, a.lengthInBytes);
  final y = b.buffer.asUint8List(b.offsetInBytes, b.lengthInBytes);
  if (x.length != y.length) return false;
  for (var i = 0; i < x.length; i++) {
    if (x[i] != y[i]) return false;
  }
  return true;
}

/// Pixels inside the circle that have exactly the color of a pebble.
int pebblePixels(
  ByteData data,
  int width,
  BoardPalette palette,
  Offset center,
  double radius,
) {
  var n = 0;
  for (var y = 0; y < data.lengthInBytes ~/ 4 ~/ width; y++) {
    for (var x = 0; x < width; x++) {
      if ((Offset(x + 0.5, y + 0.5) - center).distance > radius * 0.9) continue;
      if (palette.pebbles.contains(pixelAt(data, width, x, y))) n++;
    }
  }
  return n;
}

const size = 200;
const center = Offset(100, 100);
const radius = 60.0;

Future<ByteData> hole(
  BoardPalette palette,
  int count, {
  bool tappable = false,
  bool landing = false,
}) =>
    render(
      size,
      size,
      (canvas) => paintHole(
        canvas,
        center,
        radius,
        palette,
        count: count,
        seed: 3,
        tappable: tappable,
        landing: landing,
      ),
    );

void main() {
  testWidgets('every drawing function runs, for both palettes and any count', (
    tester,
  ) async {
    for (final palette in palettes) {
      for (final count in [0, 1, 4, 12, 40, 48]) {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        paintBoardBackground(canvas, const Size(844, 300), palette);
        for (final tappable in [false, true]) {
          for (final landing in [false, true]) {
            paintHole(
              canvas,
              const Offset(100, 100),
              45,
              palette,
              count: count,
              seed: count,
              tappable: tappable,
              landing: landing,
              pulse: 0.5,
            );
          }
        }
        paintHolePill(
          canvas,
          const Offset(100, 100),
          45,
          count,
          palette,
          above: true,
        );
        paintPit(
          canvas,
          const Rect.fromLTWH(0, 0, 80, 250),
          palette,
          count: count,
          seed: 1,
        );
        recorder.endRecording().dispose();
      }
    }
  });

  group('board background', () {
    testWidgets('is a rounded wooden board', (tester) async {
      await tester.runAsync(() async {
        final data = await render(
          400,
          200,
          (c) => paintBoardBackground(c, const Size(400, 200), palettes[0]),
        );
        expect(pixelAt(data, 400, 200, 100).a, 1.0); // the wood
        expect(pixelAt(data, 400, 0, 0).a, 0.0); // the rounded corner
      });
    });
  });

  group('pebbles in a hole', () {
    testWidgets('an empty hole has none, more seeds show more pebbles', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final palette in palettes) {
          final counts = <int>[];
          for (final n in [0, 1, 4, 12]) {
            counts.add(
              pebblePixels(
                await hole(palette, n),
                size,
                palette,
                center,
                radius,
              ),
            );
          }
          expect(counts[0], 0, reason: 'empty hole');
          expect(counts[1] > 0, true, reason: '1 seed');
          expect(counts[2] > counts[1], true, reason: '4 seeds vs 1: $counts');
          expect(counts[3] > counts[2], true, reason: '12 seeds vs 4: $counts');
        }
      });
    });

    testWidgets('40 and 48 seeds look exactly like a full hole of 12', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final full = await hole(palettes[0], 12);
        expect(sameBytes(full, await hole(palettes[0], 40)), true);
        expect(sameBytes(full, await hole(palettes[0], 48)), true);
      });
    });
  });

  group('rings', () {
    // A ring of width 6 around a hole of radius 60: its middle is at
    // 60 + 3 + 3 = 66 from the center.
    Future<ByteData> ring({required bool dashed}) => render(
          size,
          size,
          (canvas) => paintRing(
            canvas,
            center,
            radius,
            palettes[0].ring,
            width: 6,
            dashed: dashed,
          ),
        );

    // The fraction of 180 points around the ring that are painted.
    double painted(ByteData data) {
      var n = 0;
      for (var i = 0; i < 180; i++) {
        final angle = i * 2 * math.pi / 180;
        final x = (center.dx + 66 * math.cos(angle)).floor();
        final y = (center.dy + 66 * math.sin(angle)).floor();
        if (pixelAt(data, size, x, y).a > 0.9) n++;
      }
      return n / 180;
    }

    testWidgets('a solid ring is closed and in the ring color', (tester) async {
      await tester.runAsync(() async {
        final data = await ring(dashed: false);
        expect(painted(data) > 0.97, true, reason: '${painted(data)}');
        expect(pixelAt(data, size, 166, 100), palettes[0].ring);
        expect(pixelAt(data, size, 100, 166), palettes[0].ring);
        expect(pixelAt(data, size, 33, 100), palettes[0].ring);
        expect(pixelAt(data, size, 100, 33), palettes[0].ring);
        // Nothing is drawn inside the ring.
        expect(pixelAt(data, size, 100, 100).a, 0.0);
      });
    });

    testWidgets('a dashed ring has gaps', (tester) async {
      await tester.runAsync(() async {
        final share = painted(await ring(dashed: true));
        expect(share > 0.2 && share < 0.8, true, reason: '$share');
      });
    });

    testWidgets('only a tappable hole gets the solid ring', (tester) async {
      await tester.runAsync(() async {
        for (final palette in palettes) {
          // At pulse 0 the ring is 4.8 wide, its middle at 60 + 3 + 2.4 = 65.4.
          final plain = await hole(palette, 4);
          final tappable = await hole(palette, 4, tappable: true);
          expect(pixelAt(plain, size, 165, 100).a, 0.0);
          expect(pixelAt(tappable, size, 165, 100), palette.ring);
        }
      });
    });

    testWidgets('only the landing hole gets a dashed ring', (tester) async {
      await tester.runAsync(() async {
        final plain = await hole(palettes[0], 4);
        final landing = await hole(palettes[0], 4, landing: true);
        expect(sameBytes(plain, landing), false);
      });
    });
  });

  group('count pill', () {
    // A hole of radius 40 at (100, 100): the pill is 20 high and its middle is
    // 40 * 1.3 + 10 = 62 away, above or below.
    Future<ByteData> pill({required bool above}) => render(
          size,
          size,
          (canvas) =>
              paintHolePill(canvas, center, 40, 7, palettes[0], above: above),
        );

    testWidgets('sits above the hole for the top row', (tester) async {
      await tester.runAsync(() async {
        final data = await pill(above: true);
        expect(pixelAt(data, size, 86, 38), palettes[0].pillFill);
        expect(pixelAt(data, size, 86, 162).a, 0.0);
      });
    });

    testWidgets('sits below the hole for the bottom row', (tester) async {
      await tester.runAsync(() async {
        final data = await pill(above: false);
        expect(pixelAt(data, size, 86, 162), palettes[0].pillFill);
        expect(pixelAt(data, size, 86, 38).a, 0.0);
      });
    });
  });

  group('pit', () {
    Future<ByteData> pit(int count) => render(
          80,
          250,
          (canvas) => paintPit(
            canvas,
            const Rect.fromLTWH(0, 0, 80, 250),
            palettes[0],
            count: count,
            seed: 1,
          ),
        );

    testWidgets('shows pebbles when it holds seeds and up to 30 of them', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final empty = await pit(0);
        final some = await pit(20);
        expect(
          pebblePixels(empty, 80, palettes[0], const Offset(40, 125), 125),
          0,
        );
        expect(
          pebblePixels(some, 80, palettes[0], const Offset(40, 125), 125) > 0,
          true,
        );
        expect(sameBytes(await pit(30), await pit(48)), true);
      });
    });
  });
}
