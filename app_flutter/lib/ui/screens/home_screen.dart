import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_ui_state.dart';
import '../../state/providers.dart';
import 'palette.dart';
import 'routes.dart';
import 'widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Open a screen. When we come back, look for a saved game again.
  Future<void> _open(BuildContext context, WidgetRef ref, String route) async {
    await Navigator.of(context).pushNamed(route);
    if (!context.mounted) return;
    ref.invalidate(savedGameProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedGame = ref.watch(savedGameProvider).when(
          data: (snapshot) => snapshot,
          loading: () => null,
          error: (error, stack) => null,
        );
    final hasSavedGame = savedGame != null;

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
                  onPressed: () => _open(context, ref, Routes.settings),
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
                          Bob(
                            child: Text(
                              'Gebeta',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    fontSize: 84,
                                    color: GebetaColors.gold,
                                  ),
                            ),
                          ),
                          const Text(
                            'The traditional Ethiopian seed game',
                            style: TextStyle(
                              fontSize: 20,
                              color: GebetaColors.cream,
                            ),
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
                          if (savedGame != null) ...[
                            GButton(
                              'Resume',
                              primary: true,
                              shine: true,
                              onPressed: () {
                                ref
                                    .read(gameControllerProvider.notifier)
                                    .resumeGame(savedGame);
                                _open(context, ref, Routes.game);
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          GButton(
                            'Play vs Computer',
                            primary: !hasSavedGame,
                            shine: !hasSavedGame,
                            onPressed: () =>
                                _open(context, ref, Routes.opponent),
                          ),
                          const SizedBox(height: 14),
                          GButton(
                            'Play with a Friend',
                            onPressed: () {
                              ref
                                  .read(gameControllerProvider.notifier)
                                  .startGame(
                                    const GameConfig(mode: GameMode.twoPlayers),
                                  );
                              _open(context, ref, Routes.game);
                            },
                          ),
                          const SizedBox(height: 14),
                          GButton(
                            'How to Play',
                            onPressed: () =>
                                _open(context, ref, Routes.howToPlay),
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
