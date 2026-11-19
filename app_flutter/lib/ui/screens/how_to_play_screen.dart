import 'package:flutter/material.dart';

import 'palette.dart';
import 'widgets.dart';

class _Lesson {
  const _Lesson({
    required this.title,
    required this.text,
    required this.caption,
    required this.bottom,
    this.top,
    this.mark,
  });

  final String title;
  final String text;
  final String caption;
  final List<int> bottom; // the player's row, six holes
  final List<int>? top; // the opponent's row, when the lesson needs it
  final int? mark; // hole on the bottom row to ring in gold
}

const List<_Lesson> _lessons = [
  _Lesson(
    title: 'Goal',
    text:
        'Collect more seeds in your pit than your opponent. Each side has 6 holes with 4 seeds.',
    caption: 'Each side has 6 holes with 4 seeds.',
    top: [4, 4, 4, 4, 4, 4],
    bottom: [4, 4, 4, 4, 4, 4],
  ),
  _Lesson(
    title: 'Sowing',
    text:
        'Pick one of your holes. Lift all its seeds and drop one in each hole after it, always moving the same way.',
    caption: 'Hole 3 was lifted. Its seeds go one by one into the holes after it.',
    bottom: [4, 4, 0, 5, 5, 5],
    mark: 2,
  ),
  _Lesson(
    title: 'Capture',
    text:
        'Land your last seed in an empty hole on your side. If the hole opposite has seeds, you take them all.',
    caption:
        'The last seed lands in an empty hole. The 2 seeds across from it are captured.',
    top: [0, 0, 0, 0, 2, 0],
    bottom: [0, 0, 0, 0, 1, 2],
    mark: 4,
  ),
  _Lesson(
    title: 'Relay',
    text:
        'If your last seed lands in a hole that already had seeds, lift those and keep sowing.',
    caption: 'The last seed landed on a full hole, so lift it and keep sowing.',
    bottom: [4, 4, 0, 5, 5, 6],
    mark: 5,
  ),
  _Lesson(
    title: 'End of the game',
    text:
        'The game ends when the player to move has no seeds. The other player keeps the seeds left on their side. Most seeds in the pit wins.',
    caption: 'One side is empty, so the game is over.',
    top: [0, 0, 0, 0, 0, 0],
    bottom: [3, 0, 2, 0, 1, 0],
  ),
];

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final lesson = _lessons[_index];
    final last = _index == _lessons.length - 1;
    return Scaffold(
      body: WoodBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              const ScreenHeader('How to Play'),
              Text(
                'Lesson ${_index + 1} of ${_lessons.length}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 300,
                      child: GPanel(
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: GebetaColors.gold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                lesson.text,
                                style: const TextStyle(fontSize: 16, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // TODO(U2): replace this static drawing with a real BoardView
                    // demo and an animated seed.
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _LessonDrawing(lesson),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 140,
                    child: GButton(
                      'Back',
                      onPressed: _index == 0 ? null : () => setState(() => _index--),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: GButton(
                      last ? 'Done' : 'Next',
                      primary: true,
                      onPressed: () {
                        if (last) {
                          Navigator.of(context).maybePop();
                        } else {
                          setState(() => _index++);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small wooden board with one or two rows of holes, and a caption.
class _LessonDrawing extends StatelessWidget {
  const _LessonDrawing(this.lesson);

  final _Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFB96B34),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFFFD68C), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lesson.top != null) ...[
                _HoleRow(lesson.top!),
                const SizedBox(height: 10),
              ],
              _HoleRow(lesson.bottom, mark: lesson.mark),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 330,
          child: Text(
            lesson.caption,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}

/// Six holes with their seed counts. [mark] gets a gold ring.
class _HoleRow extends StatelessWidget {
  const _HoleRow(this.counts, {this.mark});

  final List<int> counts;
  final int? mark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < counts.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3B1A09),
              border: i == mark
                  ? Border.all(color: GebetaColors.gold, width: 3)
                  : null,
            ),
            child: Text(
              '${counts[i]}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: GebetaColors.cream,
              ),
            ),
          ),
        ],
      ],
    );
  }
}