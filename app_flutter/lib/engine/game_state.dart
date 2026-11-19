/// The position of a game: 12 holes, 2 pits, whose turn it is, turns played.
/// It is an immutable value: a move never changes a state, it returns a new one.
class GameState {
  GameState({
    required List<int> holes,
    required List<int> pits,
    required this.player,
    this.turns = 0,
  })  : assert(holes.length == 12, 'holes must have length 12'),
        assert(pits.length == 2, 'pits must have length 2'),
        holes = List<int>.unmodifiable(holes),
        pits = List<int>.unmodifiable(pits);

  /// Seeds in holes 0 to 11.
  final List<int> holes;

  /// Pit of player 0, then pit of player 1.
  final List<int> pits;

  /// Whose turn it is, 0 or 1.
  final int player;

  /// Turns played so far in this game.
  final int turns;

  /// A copy with the given fields replaced.
  GameState copyWith({
    List<int>? holes,
    List<int>? pits,
    int? player,
    int? turns,
  }) {
    return GameState(
      holes: holes ?? this.holes,
      pits: pits ?? this.pits,
      player: player ?? this.player,
      turns: turns ?? this.turns,
    );
  }

  /// {"holes":[...],"pits":[a,b],"player":0,"turns":0}
  Map<String, dynamic> toJson() => {
        'holes': List<int>.of(holes),
        'pits': List<int>.of(pits),
        'player': player,
        'turns': turns,
      };

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      holes: List<int>.from(json['holes'] as List),
      pits: List<int>.from(json['pits'] as List),
      player: json['player'] as int,
      turns: (json['turns'] as int?) ?? 0,
    );
  }

  /// Two states are equal when all four fields are equal.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameState &&
          player == other.player &&
          turns == other.turns &&
          _sameList(holes, other.holes) &&
          _sameList(pits, other.pits));

  @override
  int get hashCode =>
      Object.hash(player, turns, Object.hashAll(holes), Object.hashAll(pits));

  @override
  String toString() =>
      'GameState(holes: $holes, pits: $pits, player: $player, turns: $turns)';

  static bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}