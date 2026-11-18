import 'package:flutter/material.dart';

import 'palette.dart';
import 'widgets.dart';

class _Lesson {
  const _Lesson(this.title, this.text);
  final String title;
  final String text;
}

const List<_Lesson> _lessons = [
  _Lesson(
    'Goal',
    'Collect more seeds in your pit than your opponent. Each side has 6 holes with 4 seeds.',
  ),
  _Lesson(
    'Sowing',
    'Pick one of your holes. Lift all its seeds and drop one in each hole after it, always moving the same way.',
  ),
  _Lesson(
    'Capture',
    'Land your last seed in an empty hole on your side. If the hole opposite has seeds, you take them all.',
  ),
  _Lesson(
    'Relay',
    'If your last seed lands in a hole that already had seeds, lift those and keep sowing.',
  ),
  _Lesson(
    'End of the game',
    'The game ends when the player to move has no seeds. The other player keeps the seeds left on their side. Most seeds in the pit wins.',
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
                      width: 270,
                      child: GPanel(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: GebetaColors.gold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(lesson.text, style: const TextStyle(fontSize: 16, height: 1.4)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // TODO(U2): small demo board with callouts and an animated seed (uses BoardView).
                    const Expanded(
                      child: Center(
                        child: Text('Demo board for this lesson goes here'),
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
