import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../board_painter.dart';
import '../board_palette.dart';

/// The wooden board behind everything. The game gives it the size of the board.
class BoardBackgroundComponent extends PositionComponent {
  BoardBackgroundComponent({required this.palette, super.priority});

  BoardPalette palette;

  @override
  void render(Canvas canvas) {
    paintBoardBackground(canvas, Size(size.x, size.y), palette);
  }
}
