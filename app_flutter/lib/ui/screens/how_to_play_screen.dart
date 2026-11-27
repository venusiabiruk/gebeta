import 'package:flutter/material.dart';

import 'demo_board.dart';
import 'palette.dart';
import 'widgets.dart';

class _Lesson {
  const _Lesson(
      {required this.title, required this.text, required this.frames});

  final String title;
  final String text;
  final List<DemoFrame> frames;
}

// The boards below are only illustrations, not real game positions.
const List<_Lesson> _lessons = [
  _Lesson(
    title: 'Goal and board',
    text:
        'Collect more seeds in your pit than your opponent. Each side has 6 holes with 4 seeds, and a pit at the end.',
    frames: [
      DemoFrame(
        top: [4, 4, 4, 4, 4, 4],
        bottom: [4, 4, 4, 4, 4, 4],
        callout: Callout(Spot(1, 2), 'Your holes'),
        note: 'Each side has 6 holes with 4 seeds. Yours are on the bottom.',
      ),
      DemoFrame(
        top: [4, 4, 4, 4, 4, 4],
        bottom: [4, 4, 3, 4, 4, 4],
        yourPit: 1,
        from: Spot(1, 2),
        to: Spot.yourPit(),
        callout: Callout(Spot.yourPit(), 'Your pit'),
        note: 'Seeds in your pit are your score. Most seeds wins.',
      ),
    ],
  ),
  _Lesson(
    title: 'Sowing',
    text:
        'Pick one of your holes. Lift all its seeds and drop one in each hole after it, always moving the same way.',
    frames: [
      DemoFrame(
        top: [4, 4, 4, 4, 4, 4],
        bottom: [4, 4, 4, 4, 4, 4],
        ring: Spot(1, 2),
        callout: Callout(Spot(1, 2), 'Pick a hole'),
        note: 'Tap one of your holes. All its seeds are lifted.',
      ),
      DemoFrame(
        top: [4, 4, 4, 4, 4, 4],
        bottom: [4, 4, 0, 5, 4, 4],
        from: Spot(1, 2),
        to: Spot(1, 3),
        note: 'Drop one seed in each hole after it.',
      ),
      DemoFrame(
        top: [4, 4, 4, 4, 4, 4],
        bottom: [4, 4, 0, 5, 5, 4],
        from: Spot(1, 2),
        to: Spot(1, 4),
        note: 'Drop one seed in each hole after it.',
      ),
      DemoFrame(
        top: [4, 4, 4, 4, 4, 4],
        bottom: [4, 4, 0, 5, 5, 5],
        from: Spot(1, 2),
        to: Spot(1, 5),
        note: 'Drop one seed in each hole after it.',
      ),
      DemoFrame(
        top: [4, 4, 4, 4, 4, 5],
        bottom: [4, 4, 0, 5, 5, 5],
        from: Spot(1, 2),
        to: Spot(0, 5),
        callout: Callout(Spot(0, 5), 'Last seed'),
        note:
            'The last seed landed on a hole with seeds. That starts a relay (lesson 4).',
      ),
    ],
  ),
  _Lesson(
    title: 'Capture',
    text:
        'Land your last seed in an empty hole on your side. If the hole opposite has seeds, you take them all.',
    frames: [
      DemoFrame(
        top: [0, 0, 0, 0, 2, 0],
        bottom: [0, 0, 0, 1, 0, 2],
        ring: Spot(1, 3),
        callout: Callout(Spot(1, 3), 'Start'),
        note: 'Try it: sow the single seed.',
      ),
      DemoFrame(
        top: [0, 0, 0, 0, 2, 0],
        bottom: [0, 0, 0, 0, 1, 2],
        ring: Spot(1, 4),
        from: Spot(1, 3),
        to: Spot(1, 4),
        callout: Callout(Spot(1, 4), 'Land here'),
        note: 'The last seed lands in an empty hole on your side.',
      ),
      DemoFrame(
        top: [0, 0, 0, 0, 0, 0],
        bottom: [0, 0, 0, 0, 1, 2],
        yourPit: 2,
        ring: Spot(0, 4),
        from: Spot(0, 4),
        to: Spot.yourPit(),
        callout: Callout(Spot(0, 4), 'Opposite'),
        note: 'The 2 seeds across from it are captured into your pit.',
      ),
    ],
  ),
  _Lesson(
    title: 'Relay',
    text:
        'If your last seed lands in a hole that already had seeds, lift those and keep sowing.',
    frames: [
      DemoFrame(
        top: [0, 0, 0, 0, 0, 0],
        bottom: [2, 1, 1, 0, 0, 0],
        ring: Spot(1, 0),
        callout: Callout(Spot(1, 0), 'Start'),
        note: 'Lift the 2 seeds from this hole.',
      ),
      DemoFrame(
        top: [0, 0, 0, 0, 0, 0],
        bottom: [0, 2, 1, 0, 0, 0],
        from: Spot(1, 0),
        to: Spot(1, 1),
        note: 'Drop them one by one.',
      ),
      DemoFrame(
        top: [0, 0, 0, 0, 0, 0],
        bottom: [0, 2, 2, 0, 0, 0],
        ring: Spot(1, 2),
        from: Spot(1, 0),
        to: Spot(1, 2),
        callout: Callout(Spot(1, 2), 'Had a seed'),
        note: 'The last seed landed on a hole that already had a seed.',
      ),
      DemoFrame(
        top: [0, 0, 0, 0, 0, 0],
        bottom: [0, 2, 0, 0, 0, 0],
        ring: Spot(1, 2),
        callout: Callout(Spot(1, 2), 'Relay'),
        note: 'So lift that hole too, and keep sowing.',
      ),
      DemoFrame(
        top: [0, 0, 0, 0, 0, 0],
        bottom: [0, 2, 0, 1, 0, 0],
        from: Spot(1, 2),
        to: Spot(1, 3),
        note: 'So lift that hole too, and keep sowing.',
      ),
      DemoFrame(
        top: [0, 0, 0, 0, 0, 0],
        bottom: [0, 2, 0, 1, 1, 0],
        ring: Spot(1, 4),
        from: Spot(1, 2),
        to: Spot(1, 4),
        callout: Callout(Spot(1, 4), 'Empty'),
        note: 'The last seed landed in an empty hole, so the turn ends.',
      ),
    ],
  ),
  _Lesson(
    title: 'End of the game',
    text:
        'The game ends when the player to move has no seeds. The other player keeps the seeds left on their side. Most seeds in the pit wins.',
    frames: [
      DemoFrame(
        top: [0, 0, 0, 0, 0, 0],
        bottom: [3, 0, 2, 0, 1, 0],
        opponentPit: 20,
        yourPit: 22,
        callout: Callout(Spot(0, 2), 'No seeds'),
        note: 'The opponent has no seeds to move, so the game is over.',
      ),
      DemoFrame(
        top: [0, 0, 0, 0, 0, 0],
        bottom: [0, 0, 2, 0, 1, 0],
        opponentPit: 20,
        yourPit: 25,
        from: Spot(1, 0),
        to: Spot.yourPit(),
        note: 'You keep the seeds left on your side.',
      ),
      DemoFrame(
        top: [0, 0, 0, 0, 0, 0],
        bottom: [0, 0, 0, 0, 1, 0],
        opponentPit: 20,
        yourPit: 27,
        from: Spot(1, 2),
        to: Spot.yourPit(),
        note: 'You keep the seeds left on your side.',
      ),
      DemoFrame(
        top: [0, 0, 0, 0, 0, 0],
        bottom: [0, 0, 0, 0, 0, 0],
        opponentPit: 20,
        yourPit: 28,
        from: Spot(1, 4),
        to: Spot.yourPit(),
        callout: Callout(Spot.yourPit(), 'You: 28'),
        note: 'You win, 28 seeds to 20.',
      ),
    ],
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
                                style:
                                    const TextStyle(fontSize: 16, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // The key restarts the board when the lesson changes.
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: DemoBoard(
                            key: ValueKey(_index),
                            frames: lesson.frames,
                          ),
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
                      onPressed:
                          _index == 0 ? null : () => setState(() => _index--),
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
