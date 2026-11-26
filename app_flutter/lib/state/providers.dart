import 'dart:math';
/// The random number source. Tests replace it with a fixed one, for example Random(1).
final randomProvider = Provider<Random>((ref) => Random());
