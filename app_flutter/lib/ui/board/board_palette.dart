import 'dart:ui';

import 'pebbles.dart';

/// All the colors of the board in one place (U1-04), so the look can change
/// without touching the drawing code. The design is not settled yet: these
/// values follow the team palette (lib/ui/screens/palette.dart) and the
/// mockup, and the tests only protect what must stay true whatever the design:
/// text is readable and the highlight rings stand out.
class BoardPalette {
  const BoardPalette({
    required this.boardTop,
    required this.boardBottom,
    required this.rim,
    required this.holeFill,
    required this.holeShade,
    required this.pitFill,
    required this.pillFill,
    required this.pillText,
    required this.ring,
    required this.pebbles,
    required this.pebbleEdge,
  });

  /// The wooden board: a vertical gradient from [boardTop] to [boardBottom].
  final Color boardTop;
  final Color boardBottom;

  /// The border of the board.
  final Color rim;

  /// The inside of a hole, and the darker color used for its inner shadow.
  final Color holeFill;
  final Color holeShade;

  /// The inside of a capture pit.
  final Color pitFill;

  /// The count pill next to each hole.
  final Color pillFill;
  final Color pillText;

  /// The ring around a tappable hole and the dashed ring around the hole where
  /// the last seed landed. It must stand out on the board and on the hole.
  final Color ring;

  /// One color per pebble shade (exactly [pebbleShades] of them, which the
  /// palette tests check), and their outline.
  final List<Color> pebbles;
  final Color pebbleEdge;

  /// Dark wood, from the mockup and the team palette.
  static const BoardPalette darkWood = BoardPalette(
    boardTop: Color(0xFFA9622F),
    boardBottom: Color(0xFF8A4A26),
    rim: Color(0xFF6E371B),
    holeFill: Color(0xFF5B2D14),
    holeShade: Color(0xFF3F1E0C),
    pitFill: Color(0xFF4A2310),
    pillFill: Color(0xFF3A1B0A),
    pillText: Color(0xFFFFF3DC),
    ring: Color(0xFFFFC857),
    pebbles: [
      Color(0xFFE2CFA3), // sand
      Color(0xFFA9B6C4), // blue-grey
      Color(0xFFA07F66), // brown
      Color(0xFFC9A98A), // tan
    ],
    pebbleEdge: Color(0xFF2B1406),
  );

  /// Light wood. The ring is dark brown here: gold does not stand out on light
  /// wood (contrast about 1.7 to 1, where at least 3 to 1 is needed).
  static const BoardPalette lightWood = BoardPalette(
    boardTop: Color(0xFFE6B882),
    boardBottom: Color(0xFFD9A468),
    rim: Color(0xFFA9703A),
    holeFill: Color(0xFF9A5F33),
    holeShade: Color(0xFF7A4724),
    pitFill: Color(0xFF7E4824),
    pillFill: Color(0xFF5A2D14),
    pillText: Color(0xFFFFF3DC),
    ring: Color(0xFF2B1406),
    pebbles: [
      Color(0xFFF1E3BE),
      Color(0xFFC4CFDA),
      Color(0xFFD7BBA0),
      Color(0xFFE6CDAE),
    ],
    pebbleEdge: Color(0xFF3A1B0A),
  );
}
