import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gebeta/ai/levels.dart';

import '../../ai/ai_service.dart';
import '../../state/game_ui_state.dart';
import '../../state/providers.dart';
import 'palette.dart';
import 'routes.dart';
import 'widgets.dart';

class _Opponent {
  const _Opponent(this.level, this.name, this.description, this.strength);

  final Level level;
  final String name;
  final String description;
  final double strength; // 0 to 1, drawn as the difficulty bar
}

const List<_Opponent> _opponents = [
  _Opponent(Level.novice, 'Novice',
      'Makes mistakes. Good for learning the rules.', 0.3),
  _Opponent(
      Level.amateur, 'Amateur', 'Plays sensibly, but you can beat it.', 0.66),
  _Opponent(Level.master, 'Master', 'Plans ahead. Hard to beat.', 1.0),
];

class OpponentSelectScreen extends ConsumerStatefulWidget {
  const OpponentSelectScreen({super.key});

  @override
  ConsumerState<OpponentSelectScreen> createState() =>
      _OpponentSelectScreenState();
}

class _OpponentSelectScreenState extends ConsumerState<OpponentSelectScreen> {
  int _selected = 1; // Amateur
  FirstMove _firstMove = FirstMove.alternate; // Take turns is the default

  /// Build the game settings from the two choices and start the game.
  void _start() {
    final config = GameConfig(
      mode: GameMode.vsAi,
      level: _opponents[_selected].level,
      firstMove: _firstMove,
    );
    ref.read(gameControllerProvider.notifier).startGame(config);
    Navigator.of(context).pushNamed(Routes.game);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WoodBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              _header(context),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < _opponents.length; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(child: _card(i)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Back button, title, and the "who goes first" choice.
  Widget _header(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              'Choose your opponent',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Who goes first? Take turns is recommended.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              SegmentedButton<FirstMove>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(
                      value: FirstMove.alternate, label: Text('Take turns')),
                  ButtonSegment(value: FirstMove.human, label: Text('I start')),
                  ButtonSegment(
                      value: FirstMove.ai, label: Text('Computer starts')),
                ],
                selected: {_firstMove},
                onSelectionChanged: (choice) {
                  setState(() => _firstMove = choice.first);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(int i) {
    final opponent = _opponents[i];
    final selected = i == _selected;
    return GestureDetector(
      onTap: () => setState(() => _selected = i),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0x805A2A0C) : GebetaColors.panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? GebetaColors.gold : const Color(0x99FFC878),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opponent.name,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text(opponent.description,
                        style: const TextStyle(fontSize: 16)),
                    const Spacer(),
                    const Text('DIFFICULTY',
                        style: TextStyle(fontSize: 13, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: GebetaColors.panel,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: opponent.strength,
                          child: Container(
                            decoration: BoxDecoration(
                              color: GebetaColors.gold,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: selected ? GebetaColors.gold : null,
                  foregroundColor:
                      selected ? GebetaColors.ink : GebetaColors.cream,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                // On the selected card the button starts the game.
                // On the other cards it only selects that card.
                onPressed: () {
                  if (selected) {
                    _start();
                  } else {
                    setState(() => _selected = i);
                  }
                },
                child: Text(selected ? 'Play Now' : 'Select'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
