import 'dart:math' as math;
import 'dart:ui';

// Where things sit on the board (guide, section 1 "Board and indexing". Pure functions: no Flutter widgets, so they are unit tested
// without a screen.
//
// On screen, with player 0 at the bottom:
//
//   pit 1 | 11 | 10 |  9 |  8 |  7 |  6 |
//         |  0 |  1 |  2 |  3 |  4 |  5 | pit 0
//
// Play runs left to right along the bottom row (holes 0 to 5), up to hole 6 at
// the top right, then right to left along the top row (6 to 11).

/// The landscape design size of the game screen. Positions below are fractions
/// of whatever size they are given, so they scale from this size to any other.
const Size designSize = Size(844, 390);

// The numbers to tune when the design is settled (U1-04).
const double _pitWidthFraction = 0.12; // each pit's share of the width
const double _topRowFraction = 0.30; // height of the top row's centers
const double _bottomRowFraction = 0.70; // height of the bottom row's centers

/// Height of a count pill, and the gap between a hole and its pill, as a
/// fraction of the hole's radius. The pill sits outside the hole, away from the
/// middle of the board (above the top row, below the bottom row).
const double pillHeightFactor = 0.5;
const double pillGapFactor = 0.3;

/// How far from the center of a hole its ring and pill reach, in hole radii.
/// The rows are placed so that this much room is left above and below them.
const double holeReachFactor = 1 + pillGapFactor + pillHeightFactor;

/// The center of [hole] (0 to 11) on a board of [size].
///
/// With [flip] true the whole board is rotated by 180 degrees, which puts
/// player 1 at the bottom (two-player mode, player 1 to move).
Offset holeCenter(int hole, Size size, {bool flip = false}) {
  assert(hole >= 0 && hole < 12, 'hole must be 0 to 11');
  final pitWidth = size.width * _pitWidthFraction;
  final cellWidth = (size.width - 2 * pitWidth) / 6;
  final inBottomRow = hole < 6;
  // Bottom row: hole 0 at the left. Top row: hole 6 at the right, 11 at the left.
  final column = inBottomRow ? hole : 11 - hole;
  final x = pitWidth + (column + 0.5) * cellWidth;
  final y = size.height * (inBottomRow ? _bottomRowFraction : _topRowFraction);
  return _place(Offset(x, y), size, flip);
}

/// The center of the capture pit of [player] (0 or 1): pit 0 at the right end,
/// pit 1 at the left end. [flip] rotates the board by 180 degrees.
Offset pitCenter(int player, Size size, {bool flip = false}) {
  assert(player == 0 || player == 1, 'player must be 0 or 1');
  final pitWidth = size.width * _pitWidthFraction;
  final x = player == 0 ? size.width - pitWidth / 2 : pitWidth / 2;
  return _place(Offset(x, size.height / 2), size, flip);
}

/// The radius of a hole on a board of [size]: the largest round hole that
/// leaves a small gap to its neighbours in the row and in the other row.
double holeRadius(Size size) {
  final pitWidth = size.width * _pitWidthFraction;
  final cellWidth = (size.width - 2 * pitWidth) / 6;
  final rowGap = size.height * (_bottomRowFraction - _topRowFraction);
  return math.min(cellWidth, rowGap) * 0.42;
}

/// The size of a capture pit on a board of [size] (a tall rounded slot).
Size pitSize(Size size) =>
    Size(size.width * _pitWidthFraction * 0.8, size.height * 0.80);

/// [point] rotated by 180 degrees around the center of a board of [size].
Offset rotate180(Offset point, Size size) =>
    Offset(size.width - point.dx, size.height - point.dy);

Offset _place(Offset point, Size size, bool flip) =>
    flip ? rotate180(point, size) : point;
