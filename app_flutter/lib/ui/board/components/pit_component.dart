import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../board_painter.dart';
import '../board_palette.dart';

/// One of the two capture pits: a tall slot holding up to 30 pebbles. The
/// board (BoardGame) sets [count].
class PitComponent extends PositionComponent {
  PitComponent({required this.player, required this.palette, super.priority})
      : super(anchor: Anchor.center);

  /// The player who owns the pit, 0 or 1.
  final int player;

  BoardPalette palette;

  /// Seeds in the pit.
  int count = 0;

  @override
  void render(Canvas canvas) {
    paintPit(
      canvas,
      Rect.fromLTWH(0, 0, size.x, size.y),
      palette,
      count: count,
      seed: 100 + player,
    );
  }
}
