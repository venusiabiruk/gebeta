import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'board_palette.dart';
import 'layout.dart';
import 'pebbles.dart';

// All the drawing of the board (U1-04), as plain functions on a Canvas. The
// Flame components call these, so the look lives in one place and can be tested
// by drawing into an image (test/board_painter_test.dart). Colors come from the
// BoardPalette; sizes come from the hole radius.

/// The wooden board: a gradient with faint grain lines and a rim.
void paintBoardBackground(Canvas canvas, Size size, BoardPalette palette) {
  final rect = Offset.zero & size;
  final shape = RRect.fromRectAndRadius(
    rect,
    Radius.circular(size.height * 0.08),
  );
  canvas.drawRRect(
    shape,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.boardTop, palette.boardBottom],
      ).createShader(rect),
  );

  // Faint horizontal grain, spaced unevenly so it does not look like stripes.
  canvas.save();
  canvas.clipRRect(shape);
  final grain = Paint()
    ..color = palette.rim.withValues(alpha: 0.10)
    ..strokeWidth = math.max(1, size.height * 0.004);
  var y = size.height * 0.01;
  var i = 0;
  while (y < size.height) {
    final wobble = ((i * 37) % 11 - 5) * size.height * 0.0015;
    canvas.drawLine(Offset(0, y), Offset(size.width, y + wobble), grain);
    y += size.height * (0.012 + 0.008 * ((i * 7) % 4));
    i++;
  }
  canvas.restore();

  canvas.drawRRect(
    shape.deflate(size.height * 0.006),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, size.height * 0.012)
      ..color = palette.rim,
  );
}

/// A hole: a recess with its pebbles, and the highlight rings.
///
/// [tappable] draws a solid ring whose width follows [pulse] (0 to 1, from the
/// component's clock). [landing] draws the dashed ring on the hole where the
/// last seed landed, turned by [spin] radians so that it can rotate. The count
/// pill is drawn separately (paintHolePill).
void paintHole(
  Canvas canvas,
  Offset center,
  double radius,
  BoardPalette palette, {
  required int count,
  required int seed,
  bool tappable = false,
  bool landing = false,
  double pulse = 0,
  double spin = 0,
}) {
  final rect = Rect.fromCircle(center: center, radius: radius);

  // The recess: lighter in the middle, darker towards the edge.
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.25),
        radius: 1.0,
        colors: [palette.holeFill, palette.holeShade],
        stops: const [0.55, 1.0],
      ).createShader(rect),
  );
  // The lower lip catches the light.
  canvas.drawArc(
    rect.deflate(radius * 0.03),
    math.pi * 0.15,
    math.pi * 0.7,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.05
      ..color = palette.boardTop.withValues(alpha: 0.55),
  );

  for (final pebble in pebblesFor(count, seed: seed)) {
    paintPebble(
      canvas,
      center + Offset(pebble.x * radius, pebble.y * radius),
      pebble.radius * radius,
      pebble,
      palette,
    );
  }

  if (tappable) {
    paintRing(
      canvas,
      center,
      radius,
      palette.ring,
      width: radius * (0.08 + 0.04 * pulse),
    );
  }
  if (landing) {
    paintRing(
      canvas,
      center,
      radius,
      palette.ring,
      width: radius * 0.06,
      dashed: true,
      gap: tappable ? radius * 0.17 : radius * 0.05,
      rotation: spin,
    );
  }
}

/// One pebble: an oval with an outline and a small highlight. [radiusPx] is the
/// long radius in pixels.
void paintPebble(
  Canvas canvas,
  Offset position,
  double radiusPx,
  Pebble pebble,
  BoardPalette palette,
) {
  final shortRadius = radiusPx * 0.78;
  final oval = Rect.fromCenter(
    center: Offset.zero,
    width: radiusPx * 2,
    height: shortRadius * 2,
  );
  canvas.save();
  canvas.translate(position.dx, position.dy);
  canvas.rotate(pebble.angle);
  canvas.drawOval(oval, Paint()..color = palette.pebbles[pebble.shade]);
  canvas.drawOval(
    oval,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, radiusPx * 0.08)
      ..color = palette.pebbleEdge.withValues(alpha: 0.55),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(-radiusPx * 0.25, -shortRadius * 0.3),
      width: radiusPx * 0.7,
      height: shortRadius * 0.45,
    ),
    Paint()..color = const Color(0x55FFFFFF),
  );
  canvas.restore();
}

/// A ring just outside a hole of [holeRadius]: solid, or dashed with rounded
/// dashes. [width] is its thickness and [gap] the space between the hole and
/// the ring.
/// A dashed ring is turned by [rotation] radians.
void paintRing(
  Canvas canvas,
  Offset center,
  double holeRadius,
  Color color, {
  required double width,
  bool dashed = false,
  double? gap,
  double rotation = 0,
}) {
  final ringRadius = holeRadius + (gap ?? holeRadius * 0.05) + width / 2;
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = dashed ? StrokeCap.round : StrokeCap.butt
    ..color = color;
  if (!dashed) {
    canvas.drawCircle(center, ringRadius, paint);
    return;
  }
  const dashes = 18;
  final rect = Rect.fromCircle(center: center, radius: ringRadius);
  for (var i = 0; i < dashes; i++) {
    canvas.drawArc(
      rect,
      rotation + i * 2 * math.pi / dashes,
      2 * math.pi / dashes * 0.5,
      false,
      paint,
    );
  }
}

/// The count pill of a hole, outside the hole: above it for the top row
/// ([above] true), below it for the bottom row.
void paintHolePill(
  Canvas canvas,
  Offset holeCenter,
  double holeRadius,
  int count,
  BoardPalette palette, {
  required bool above,
}) {
  final height = holeRadius * pillHeightFactor;
  final offset = holeRadius * (1 + pillGapFactor) + height / 2;
  final center = holeCenter + Offset(0, above ? -offset : offset);

  final text = TextPainter(
    text: TextSpan(
      text: '$count',
      style: TextStyle(
        color: palette.pillText,
        fontSize: height * 0.62,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = math.max(height * 1.6, text.width + height * 0.8);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      Radius.circular(height / 2),
    ),
    Paint()..color = palette.pillFill,
  );
  text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
}

/// A capture pit: a tall slot holding up to 30 pebbles (the count of the pit is
/// shown in the score box of the game screen).
void paintPit(
  Canvas canvas,
  Rect rect,
  BoardPalette palette, {
  required int count,
  required int seed,
}) {
  final slot = RRect.fromRectAndRadius(rect, Radius.circular(rect.width / 2));
  canvas.drawRRect(
    slot,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.holeShade, palette.pitFill],
      ).createShader(rect),
  );

  // The pebbles fill the slot as a heap: the unit disc of pebblesFor is
  // stretched to the slot (a little inside its walls).
  final halfWidth = rect.width / 2;
  final halfHeight = rect.height / 2;
  for (final pebble in pebblesFor(
    count,
    seed: seed,
    maxVisible: 30,
    radius: 0.2,
  )) {
    paintPebble(
      canvas,
      rect.center +
          Offset(pebble.x * halfWidth * 0.85, pebble.y * halfHeight * 0.92),
      pebble.radius * halfWidth,
      pebble,
      palette,
    );
  }
}
