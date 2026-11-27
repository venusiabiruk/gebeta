import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'palette.dart';
import 'widgets.dart';

// Sizes of the demo board, in logical pixels.
const double _boardWidth = 456;
const double _boardHeight = 132;
const double _chipSpace = 36; // room above and below the board for callouts

/// A place on the demo board. Row 0 is the top row, row 1 is the bottom row.
/// Column -1 is the left pit (the opponent's), column 6 is the right pit (yours).
class Spot {
  const Spot(this.row, this.col);
  const Spot.yourPit()
      : row = 1,
        col = 6;

  final int row;
  final int col;
}

/// A short label that points at a place on the board.
class Callout {
  const Callout(this.spot, this.text);

  final Spot spot;
  final String text;
}

/// One snapshot of the lesson board.
class DemoFrame {
  const DemoFrame({
    required this.top,
    required this.bottom,
    required this.note,
    this.opponentPit = 0,
    this.yourPit = 0,
    this.ring,
    this.from,
    this.to,
    this.callout,
  });

  final List<int> top; // six holes, the opponent's row
  final List<int> bottom; // six holes, your row
  final String note; // one sentence under the board
  final int opponentPit;
  final int yourPit;
  final Spot? ring; // a hole circled in gold
  final Spot? from; // a seed flies from here...
  final Spot? to; // ...to here
  final Callout? callout;
}

/// A small board that plays a list of frames in a loop.
class DemoBoard extends StatefulWidget {
  const DemoBoard({super.key, required this.frames});

  final List<DemoFrame> frames;

  @override
  State<DemoBoard> createState() => _DemoBoardState();
}

class _DemoBoardState extends State<DemoBoard> {
  Timer? _timer;
  int _index = 0;
  bool _reduced = false;
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = reduceMotion(context);
    if (_checked && reduced == _reduced) return;
    _checked = true;
    _reduced = reduced;
    _timer?.cancel();
    _timer = null;
    if (reduced) {
      // Motion is reduced: show the final position and stand still.
      _index = widget.frames.length - 1;
    } else {
      _index = 0;
      _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % widget.frames.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// The middle of a hole or pit, measured from the top-left of the board.
  Offset _center(Spot spot) {
    if (spot.col < 0) return const Offset(34, 66);
    if (spot.col > 5) return const Offset(422, 66);
    final x = 64.0 + spot.col * 56 + 24;
    final y = spot.row == 0 ? 36.0 : 96.0;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.frames[_index];
    final callout = frame.callout;
    final from = frame.from;
    final to = frame.to;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _boardWidth,
          height: _boardHeight + 2 * _chipSpace,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: _chipSpace,
                child: _board(frame),
              ),
              if (callout != null) _calloutChip(callout),
              if (from != null && to != null && !_reduced)
                _flyingSeed(from, to, _index),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: _boardWidth,
          height: 44,
          child: Center(
            child: Text(
              frame.note,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _board(DemoFrame frame) {
    final pieces = <Widget>[];
    for (var col = 0; col < 6; col++) {
      pieces.add(_hole(Spot(0, col), frame.top[col], frame.ring));
      pieces.add(_hole(Spot(1, col), frame.bottom[col], frame.ring));
    }
    pieces.add(_pit(12, frame.opponentPit));
    pieces.add(_pit(400, frame.yourPit));
    return Container(
      width: _boardWidth,
      height: _boardHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFB96B34),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFFD68C), width: 2),
      ),
      child: Stack(children: pieces),
    );
  }

  Widget _hole(Spot spot, int count, Spot? ring) {
    final c = _center(spot);
    final circled =
        ring != null && ring.row == spot.row && ring.col == spot.col;
    return Positioned(
      left: c.dx - 24,
      top: c.dy - 24,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF3B1A09),
          border:
              circled ? Border.all(color: GebetaColors.gold, width: 3) : null,
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: GebetaColors.cream,
          ),
        ),
      ),
    );
  }

  Widget _pit(double left, int count) {
    return Positioned(
      left: left,
      top: 12,
      child: Container(
        width: 44,
        height: 108,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF3B1A09),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: GebetaColors.cream,
          ),
        ),
      ),
    );
  }

  Widget _calloutChip(Callout callout) {
    final c = _center(callout.spot);
    const width = 150.0;
    var left = c.dx - width / 2;
    if (left < 0) left = 0;
    if (left > _boardWidth - width) left = _boardWidth - width;
    // The chip sits above the top row, or below the bottom row.
    final top = callout.spot.row == 0 ? 0.0 : _chipSpace + _boardHeight + 6;
    return Positioned(
      left: left,
      top: top,
      width: width,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xCC3A1B0A),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: GebetaColors.gold, width: 2),
          ),
          child: Text(
            callout.text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: GebetaColors.cream,
            ),
          ),
        ),
      ),
    );
  }

  /// A seed that hops from one place to another. The key restarts the
  /// animation each time a new frame appears.
  Widget _flyingSeed(Spot from, Spot to, int index) {
    final a = _center(from);
    final b = _center(to);
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, t, _) {
        if (t >= 1) return const SizedBox.shrink(); // it has landed
        final x = a.dx + (b.dx - a.dx) * t;
        final y = a.dy + (b.dy - a.dy) * t - 22 * sin(pi * t); // a small hop
        return Positioned(
          left: x - 11,
          top: _chipSpace + y - 8,
          child: Container(
            width: 22,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE8C58C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3B1A09), width: 1),
            ),
          ),
        );
      },
    );
  }
}
