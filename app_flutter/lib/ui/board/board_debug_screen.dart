import 'package:flutter/material.dart';

import '../../engine/events.dart';
import '../../engine/game_state.dart';
import 'board_view.dart';

/// A developer screen for trying the board by hand. It is not part of the app:
/// run it with
///   flutter run -t lib/ui/board/board_debug_main.dart -d chrome
///
/// The sample turn below is spec example 3 from the guide. Feeding the files in
/// tests/event_traces.json comes later, once the board animates (U1-04).
class BoardDebugScreen extends StatefulWidget {
  const BoardDebugScreen({super.key});

  @override
  State<BoardDebugScreen> createState() => _BoardDebugScreenState();
}

class _BoardDebugScreenState extends State<BoardDebugScreen> {
  static final GameState _start = GameState(
    holes: List<int>.filled(12, 4),
    pits: [0, 0],
    player: 0,
  );

  // Spec example 3: player 0 plays hole 3 and captures 2 seeds.
  static final GameState _example3 = GameState(
    holes: [0, 0, 0, 1, 0, 2, 3, 2, 5, 0, 0, 4],
    pits: [0, 0],
    player: 0,
  );
  static final GameState _example3After = GameState(
    holes: [0, 0, 0, 0, 1, 2, 3, 0, 5, 0, 0, 4],
    pits: [2, 0],
    player: 1,
    turns: 1,
  );
  static const List<GameEvent> _example3Events = [
    LiftEvent(3, 1),
    SowEvent(4),
    CaptureEvent(7, 2),
    TurnEndEvent(TurnEndReason.captured),
  ];

  GameState _state = _start;
  List<GameEvent>? _events;
  GameState? _after;
  bool _inputEnabled = true;
  bool _flip = false;
  String _log = 'Tap a glowing hole, or press a button.';

  void _show(GameState state) {
    setState(() {
      _state = state;
      _events = null;
      _after = null;
      _log = 'Showing a position.';
    });
  }

  void _playExample3() {
    setState(() {
      _state = _example3;
      _events = _example3Events;
      _after = _example3After;
      _log = 'Playing example 3 (${_example3Events.length} events)...';
    });
  }

  void _eventsDone() {
    setState(() {
      _state = _after ?? _state;
      _events = null;
      _after = null;
      _log = 'onEventsDone was called. The board now shows the after-state.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Board debug screen')),
      body: Column(
        children: [
          Expanded(
            child: BoardView(
              state: _state,
              inputEnabled: _inputEnabled,
              flipForPlayerOne: _flip,
              events: _events,
              expectedAfter: _after,
              onHoleTap: (hole) => setState(() => _log = 'Tapped hole $hole'),
              onEventStarted: (event) => debugPrint('event started: $event'),
              onEventsDone: _eventsDone,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _show(_start),
                  child: const Text('Start position'),
                ),
                ElevatedButton(
                  onPressed: () => _show(_example3),
                  child: const Text('Example 3 position'),
                ),
                ElevatedButton(
                  onPressed: () => _show(_start.copyWith(player: 1)),
                  child: const Text('Player 1 to move'),
                ),
                ElevatedButton(
                  onPressed: _playExample3,
                  child: const Text('Play example 3 events'),
                ),
                FilterChip(
                  label: const Text('Input enabled'),
                  selected: _inputEnabled,
                  onSelected: (v) => setState(() => _inputEnabled = v),
                ),
                FilterChip(
                  label: const Text('Flip for player 1'),
                  selected: _flip,
                  onSelected: (v) => setState(() => _flip = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_log),
          ),
        ],
      ),
    );
  }
}