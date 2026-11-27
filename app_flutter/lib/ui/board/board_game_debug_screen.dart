import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'board_game.dart';
import 'board_palette.dart';

/// A developer screen for looking at the Flame board (U1-04). Not part of the
/// app. Run it with
///   flutter run -t lib/ui/board/board_game_debug_main.dart -d linux
class BoardGameDebugScreen extends StatefulWidget {
  const BoardGameDebugScreen({super.key});

  @override
  State<BoardGameDebugScreen> createState() => _BoardGameDebugScreenState();
}

class _BoardGameDebugScreenState extends State<BoardGameDebugScreen> {
  final BoardGame _game = BoardGame();

  // The position in the mockup: the top row (holes 11 to 6) shows 0 2 1 0 3 4,
  // the bottom row (holes 0 to 5) shows 2 0 4 3 1 5, the pits hold 9 and 14.
  static const _mockupHoles = [2, 0, 4, 3, 1, 5, 4, 3, 0, 1, 2, 0];
  static const _mockupPits = [9, 14];
  static const _startHoles = [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];
  static const _example3Holes = [0, 0, 0, 1, 0, 2, 3, 2, 5, 0, 0, 4];
  static const _crowdedHoles = [0, 1, 12, 40, 0, 0, 0, 0, 0, 0, 0, 0];

  List<int> _holes = _mockupHoles;
  List<int> _pits = _mockupPits;
  int _player = 0;
  int? _landing = 4;
  bool _rings = true;
  bool _light = false;
  bool _flip = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _show(List<int> holes, List<int> pits, {int player = 0, int? landing}) {
    setState(() {
      _holes = holes;
      _pits = pits;
      _player = player;
      _landing = landing;
    });
    _refresh();
  }

  void _refresh() {
    _game
      ..palette = _light ? BoardPalette.lightWood : BoardPalette.darkWood
      ..flip = _flip
      ..showPosition(
        holes: _holes,
        pits: _pits,
        tappable: _rings
            ? {
                for (var h = _player * 6; h < _player * 6 + 6; h++)
                  if (_holes[h] > 0) h,
              }
            : <int>{},
        landing: _landing,
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B1406),
      appBar: AppBar(title: const Text('Flame board debug screen')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AspectRatio(
                  aspectRatio: 844 / 330,
                  child: GameWidget(game: _game),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _show(_mockupHoles, _mockupPits, landing: 4),
                  child: const Text('Mockup position'),
                ),
                ElevatedButton(
                  onPressed: () => _show(_startHoles, [0, 0]),
                  child: const Text('Start position'),
                ),
                ElevatedButton(
                  onPressed: () => _show(_example3Holes, [0, 0], landing: 4),
                  child: const Text('Example 3'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      _show(_crowdedHoles, [0, 48], player: 0, landing: 3),
                  child: const Text('1, 12 and 40 seeds'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      _show(_startHoles, [0, 0], player: 1, landing: null),
                  child: const Text('Player 1 to move'),
                ),
                FilterChip(
                  label: const Text('Rings on legal holes'),
                  selected: _rings,
                  onSelected: (v) {
                    setState(() => _rings = v);
                    _refresh();
                  },
                ),
                FilterChip(
                  label: const Text('Light wood'),
                  selected: _light,
                  onSelected: (v) {
                    setState(() => _light = v);
                    _refresh();
                  },
                ),
                FilterChip(
                  label: const Text('Flip'),
                  selected: _flip,
                  onSelected: (v) {
                    setState(() => _flip = v);
                    _refresh();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
