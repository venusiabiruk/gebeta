import 'package:flutter/material.dart';

import 'palette.dart';
import 'routes.dart';
import 'widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WoodBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Settings',
                  onPressed: () => Navigator.of(context).pushNamed(Routes.settings),
                  icon: const Icon(Icons.settings),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gebeta',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: 84,
                                  color: GebetaColors.gold,
                                ),
                          ),
                          const Text(
                            'The traditional Ethiopian seed game',
                            style: TextStyle(fontSize: 20, color: GebetaColors.cream),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // TODO(U2): show Resume first when SavedGameStore has a game.
                          GButton(
                            'Play vs Computer',
                            primary: true,
                            onPressed: () => Navigator.of(context).pushNamed(Routes.opponent),
                          ),
                          const SizedBox(height: 14),
                          GButton(
                            'Play with a Friend',
                            // TODO(U2): call GameController.startGame(twoPlayers).
                            onPressed: () => Navigator.of(context).pushNamed(Routes.game),
                          ),
                          const SizedBox(height: 14),
                          GButton(
                            'How to Play',
                            onPressed: () => Navigator.of(context).pushNamed(Routes.howToPlay),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
