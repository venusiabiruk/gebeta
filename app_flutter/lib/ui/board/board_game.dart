import 'package:flame/extensions.dart';
import 'package:flame/game.dart';

import 'board_palette.dart';
import 'components/board_background_component.dart';
import 'components/hole_component.dart';
import 'components/pit_component.dart';
import 'layout.dart';

/// The Flame game that draws the board (U1-04): the wooden background, 12 holes
/// and 2 pits, placed by layout.dart. For now it shows a position at rest
/// ([showPosition]); the animation of a turn comes in U1-05.
class BoardGame extends FlameGame {
  BoardGame({BoardPalette palette = BoardPalette.darkWood, bool flip = false})
      : _palette = palette,
        _flip = flip;

  BoardPalette _palette;
  bool _flip;

  List<int> _holeCounts = List<int>.filled(12, 0);
  List<int> _pitCounts = [0, 0];
  Set<int> _tappable = <int>{};
  int? _landing;

  final BoardBackgroundComponent _background = BoardBackgroundComponent(
    palette: BoardPalette.darkWood,
  );
  final List<HoleComponent> _holes = [];
  final List<PitComponent> _pits = [];

  Size _boardSize = Size.zero;
  bool _ready = false;

  /// True once the components exist and are placed.
  bool get isReady => _ready;

  /// The 12 hole components, by hole number (empty until [isReady]).
  List<HoleComponent> get holeComponents => List.unmodifiable(_holes);

  /// The 2 pit components, by player (empty until [isReady]).
  List<PitComponent> get pitComponents => List.unmodifiable(_pits);

  BoardPalette get palette => _palette;
  set palette(BoardPalette value) {
    _palette = value;
    if (_ready) _applyState();
  }

  /// Rotate the board by 180 degrees (two-player mode, player 1 to move).
  bool get flip => _flip;
  set flip(bool value) {
    _flip = value;
    if (_ready) _applyLayout();
  }

  /// The board is drawn over whatever is behind the game.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    for (var h = 0; h < 12; h++) {
      _holes.add(HoleComponent(hole: h, palette: _palette, priority: 2));
    }
    for (var p = 0; p < 2; p++) {
      _pits.add(PitComponent(player: p, palette: _palette, priority: 1));
    }
    _background.priority = 0;
    await addAll([_background, ..._pits, ..._holes]);
    _ready = true;
    _applyState();
    _applyLayout();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _boardSize = Size(size.x, size.y);
    if (_ready) _applyLayout();
  }

  /// Shows a position at rest: the seeds in the [holes] (12) and [pits] (2),
  /// a ring on each of the [tappable] holes, and a dashed ring on the [landing]
  /// hole.
  void showPosition({
    required List<int> holes,
    required List<int> pits,
    Set<int> tappable = const <int>{},
    int? landing,
  }) {
    assert(holes.length == 12 && pits.length == 2);
    _holeCounts = List<int>.of(holes);
    _pitCounts = List<int>.of(pits);
    _tappable = Set<int>.of(tappable);
    _landing = landing;
    if (_ready) _applyState();
  }

  void _applyState() {
    _background.palette = _palette;
    for (final hole in _holes) {
      hole
        ..palette = _palette
        ..count = _holeCounts[hole.hole]
        ..tappable = _tappable.contains(hole.hole)
        ..landing = _landing == hole.hole;
    }
    for (final pit in _pits) {
      pit
        ..palette = _palette
        ..count = _pitCounts[pit.player];
    }
  }

  void _applyLayout() {
    final board = _boardSize;
    if (board.isEmpty) return;
    _background
      ..position = Vector2.zero()
      ..size = Vector2(board.width, board.height);

    final diameter = holeRadius(board) * 2;
    for (final hole in _holes) {
      final center = holeCenter(hole.hole, board, flip: _flip);
      hole
        ..position = Vector2(center.dx, center.dy)
        ..size = Vector2.all(diameter)
        // The pill goes on the outside: above the top row, below the bottom.
        ..pillAbove = center.dy < board.height / 2;
    }

    final pit = pitSize(board);
    for (final component in _pits) {
      final center = pitCenter(component.player, board, flip: _flip);
      component
        ..position = Vector2(center.dx, center.dy)
        ..size = Vector2(pit.width, pit.height);
    }
  }
}
