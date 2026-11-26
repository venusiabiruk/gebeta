import 'dart:math' as math;

// Where the pebbles of a hole or a pit are drawn 
//
// Pure Dart with no Flutter import, so it is unit tested without a screen.
// Positions are in a unit disc: the center of the hole is (0, 0) and its edge
// is at distance 1. The component scales them to pixels.
//
// Two properties matter for the animation:
//  * Stable: the first n pebbles are the same whether the hole holds n seeds or
//    more. Adding a seed adds one pebble and moves no other.
//  * Capped: at most [defaultMaxPebbles] are drawn. The count pill beside the
//    hole shows the true number.

/// Number of different pebble shades (the component maps each to a color).
const int pebbleShades = 4;

/// Most pebbles drawn in one hole.
const int defaultMaxPebbles = 12;

/// Radius of a pebble as a fraction of the hole's radius.
const double pebbleRadius = 0.29;

/// One pebble: its center in the unit disc, its size, the angle of its oval and
/// its shade.
class Pebble {
  const Pebble({
    required this.x,
    required this.y,
    required this.radius,
    required this.angle,
    required this.shade,
  });

  final double x;
  final double y;

  /// Radius as a fraction of the hole's radius.
  final double radius;

  /// Rotation of the oval, in radians.
  final double angle;

  /// 0 to [pebbleShades] - 1.
  final int shade;

  @override
  bool operator ==(Object other) =>
      other is Pebble &&
      other.x == x &&
      other.y == y &&
      other.radius == radius &&
      other.angle == angle &&
      other.shade == shade;

  @override
  int get hashCode => Object.hash(x, y, radius, angle, shade);

  @override
  String toString() => 'Pebble($x, $y, r=$radius, shade=$shade)';
}

/// The pebbles to draw for [count] seeds. [seed] (for example the hole number)
/// makes every hole look a little different but the same every time.
///
/// Returns min([count], [maxVisible]) pebbles, all inside the unit disc.
List<Pebble> pebblesFor(
  int count, {
  required int seed,
  int maxVisible = defaultMaxPebbles,
  double radius = pebbleRadius,
}) {
  final visible = math.min(math.max(count, 0), maxVisible);
  // Pebbles sit on a sunflower spiral: slot k is at a distance that grows with
  // the square root of k and at the golden angle from slot k - 1. This packs
  // them evenly, and slot k does not depend on the count, which keeps it stable.
  const goldenAngle = 2.399963229728653;
  const jitter = 0.04;
  final reach = 1 - radius - jitter; // keeps every pebble inside the disc
  final phase = _unit(seed, 1000) * 2 * math.pi;

  return [
    for (var k = 0; k < visible; k++)
      () {
        final distance = reach * math.sqrt((k + 0.5) / maxVisible);
        final theta = phase + k * goldenAngle;
        final dx = (_unit(seed, 3 * k) * 2 - 1) * jitter;
        final dy = (_unit(seed, 3 * k + 1) * 2 - 1) * jitter;
        return Pebble(
          x: distance * math.cos(theta) + dx,
          y: distance * math.sin(theta) + dy,
          radius: radius,
          angle: _unit(seed, 3 * k + 2) * math.pi,
          shade: (_unit(seed, 5000 + k) * pebbleShades).floor() % pebbleShades,
        );
      }(),
  ];
}

/// A repeatable number in [0, 1) from [seed] and [index]. A small integer hash
/// (Park-Miller, multiplier 48271) whose products stay below 2^53, so it gives
/// the same result in the browser and on the phone.
double _unit(int seed, int index) {
  var x = (seed * 7919 + index * 104729 + 12345) % 2147483647;
  if (x <= 0) x += 1;
  for (var i = 0; i < 3; i++) {
    x = (x * 48271) % 2147483647;
  }
  return x / 2147483647;
}
