import 'package:flutter/material.dart';

import '../../engine/events.dart';
import '../../engine/game_state.dart';

/// The Gebeta board (guide, section 8, "The board").
///
/// U1-01 is a stub: it has the exact constructor from the guide and draws a
/// plain placeholder board from [state], but it does not animate yet. When
/// [events] is given it "plays" them instantly: it calls [onEventStarted] for
/// each event, then [onEventsDone] once, so the game controller (Person 2) can
/// already work with it. The real animation comes in U1-04.
///
/// It is a StatefulWidget (the guide says StatelessWidget) because it must run
/// code once when [events] arrives. The constructor, which is the contract,
/// is unchanged.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.state,
    required this.inputEnabled,
    required this.onHoleTap,
    this.events,
    this.expectedAfter,
    this.onEventsDone,
    this.onEventStarted,
    this.flipForPlayerOne = false,
  });

  /// The position drawn at rest, before any event.
  final GameState state;

  /// false: taps are ignored and no hole is highlighted.
  final bool inputEnabled;

  /// Called with the hole number when the player taps a legal hole.
  final void Function(int hole) onHoleTap;

  /// The events of one turn to animate, starting from [state].
  final List<GameEvent>? events;

  /// Debug check: the board must end in this position (used from U1-05).
  final GameState? expectedAfter;

  /// Called once after the last event.
  final VoidCallback? onEventsDone;

  /// Called before each event animates (the sound service listens to it).
  final void Function(GameEvent event)? onEventStarted;

  /// Rotate the whole board 180 degrees so that player 1 sits at the bottom.
  final bool flipForPlayerOne;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  @override
  void initState() {
    super.initState();
    _finishEventsSoon();
  }

  @override
  void didUpdateWidget(BoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new list of events arrived.
    if (widget.events != null && !identical(widget.events, oldWidget.events)) {
      _finishEventsSoon();
    }
  }

  /// Stub for the animation: report every event, then report that we are done.
  void _finishEventsSoon() {
    final events = widget.events;
    if (events == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Skip if this widget is gone or the parent has moved on.
      if (!mounted || !identical(widget.events, events)) return;
      for (final event in events) {
        widget.onEventStarted?.call(event);
      }
      widget.onEventsDone?.call();
    });
  }

  /// Holes the player may tap. Written out here, instead of calling
  /// legalMoves, because the engine functions are still stubs.
  Set<int> _tappableHoles() {
    if (!widget.inputEnabled || widget.events != null) return <int>{};
    final start = widget.state.player == 0 ? 0 : 6;
    return {
      for (var h = start; h < start + 6; h++)
        if (widget.state.holes[h] > 0) h,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Guide, section 1: top row holes 11..6 with pit 1 on the left, bottom row
    // holes 0..5 with pit 0 on the right. Flipping rotates all of it by 180
    // degrees: the rows swap and each is reversed, and the pits swap sides.
    final flip = widget.flipForPlayerOne;
    final topRow = flip ? [5, 4, 3, 2, 1, 0] : [11, 10, 9, 8, 7, 6];
    final bottomRow = flip ? [6, 7, 8, 9, 10, 11] : [0, 1, 2, 3, 4, 5];
    final leftPit = flip ? 0 : 1;
    final rightPit = flip ? 1 : 0;
    final tappable = _tappableHoles();

    // A fixed design size that is scaled to fit whatever space it is given.
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 840,
          height: 300,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.brown.shade700,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                _pit(leftPit),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _row(topRow, tappable)),
                      Expanded(child: _row(bottomRow, tappable)),
                    ],
                  ),
                ),
                _pit(rightPit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(List<int> holes, Set<int> tappable) {
    return Row(
      children: [
        for (final hole in holes)
          Expanded(child: _hole(hole, tappable.contains(hole))),
      ],
    );
  }

  Widget _hole(int hole, bool canTap) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GestureDetector(
        key: ValueKey('hole-$hole'),
        onTap: canTap ? () => widget.onHoleTap(hole) : null,
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.brown.shade300,
              border: Border.all(
                color: canTap ? Colors.amber : Colors.transparent,
                width: 5,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.state.holes[hole]}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '#$hole',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pit(int player) {
    return SizedBox(
      width: 90,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DecoratedBox(
          key: ValueKey('pit-$player'),
          decoration: BoxDecoration(
            color: Colors.brown.shade900,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pit $player',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  '${widget.state.pits[player]}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}