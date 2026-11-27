import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../board_painter.dart';
import '../board_palette.dart';

/// One of the 12 holes: the recess with its pebbles, its count pill, and the
/// rings. The component is a square whose side is the hole's diameter; the pill
/// and the rings are drawn just outside it.
///
/// The board (BoardGame) sets [count], [tappable], [landing] and [pillAbove].
class HoleComponent extends PositionComponent {
  HoleComponent({required this.hole, required this.palette, super.priority})
      : super(anchor: Anchor.center);

  /// The hole number, 0 to 11. It also makes every hole's pebbles look a little
  /// different.
  final int hole;

  BoardPalette palette;

  /// Seeds in the hole.
  int count = 0;

  /// The player may tap this hole: a solid ring that pulses gently.
  bool tappable = false;

  /// The last seed landed here: a dashed ring.
  bool landing = false;

  /// The count pill sits above the hole (top row) or below it (bottom row).
  bool pillAbove = false;

  /// Seconds since the component started: the clock of the pulse.
  double _clock = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
  }

  @override
  void render(Canvas canvas) {
    final radius = size.x / 2;
    final center = Offset(radius, size.y / 2);
    // 0 to 1 and back, once every 1.4 seconds.
    final pulse =
        tappable ? 0.5 + 0.5 * math.sin(_clock * 2 * math.pi / 1.4) : 0.0;
    paintHole(
      canvas,
      center,
      radius,
      palette,
      count: count,
      seed: hole,
      tappable: tappable,
      landing: landing,
      pulse: pulse,
      spin: _clock * 0.6, // the dashed ring turns about once every 10 seconds
    );
    paintHolePill(canvas, center, radius, count, palette, above: pillAbove);
  }
}
