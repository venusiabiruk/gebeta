import 'package:flutter/material.dart';

import 'palette.dart';
import 'pause_overlay.dart';
import 'routes.dart';
import 'widgets.dart';

/// Placeholder game screen. Person 1's BoardView goes in the middle (U1).
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WoodBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () async {
                      final leave = await showLeaveGameDialog(context);
                      if (leave == true && context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.home,
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  // TODO(U2): Slow / Normal / Fast and Skip animation controls go here.
                  const Spacer(),
                  IconButton(
                    tooltip: 'Pause',
                    onPressed: () => showPauseOverlay(context),
                    icon: const Icon(Icons.pause),
                  ),
                ],
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'BoardView goes here (Person 1, U1)',
                    style: TextStyle(fontSize: 20, color: GebetaColors.cream),
                  ),
                ),
              ),
              Row(
                children: [
                  _score(context, 'Computer', '0'),
                  const Spacer(),
                  // TODO(U2): turn indicator ("Your turn: tap a glowing hole").
                  _score(context, 'You', '0'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _score(BuildContext context, String name, String value) {
    return SizedBox(
      width: 200,
      child: GPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 13)),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    color: GebetaColors.gold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
