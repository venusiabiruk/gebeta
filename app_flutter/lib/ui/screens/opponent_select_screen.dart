import 'package:flutter/material.dart';

import 'palette.dart';
import 'routes.dart';
import 'widgets.dart';

class _Opponent {
  const _Opponent(this.name, this.description, this.strength);
  final String name;
  final String description;
  final double strength; // 0 to 1, drawn as the difficulty bar
}

const List<_Opponent> _opponents = [
  _Opponent('Novice', 'Makes mistakes. Good for learning the rules.', 0.3),
  _Opponent('Amateur', 'Plays sensibly, but you can beat it.', 0.66),
  _Opponent('Master', 'Plans ahead. Hard to beat.', 1.0),
];

class OpponentSelectScreen extends StatefulWidget {
  const OpponentSelectScreen({super.key});

  @override
  State<OpponentSelectScreen> createState() => _OpponentSelectScreenState();
}

class _OpponentSelectScreenState extends State<OpponentSelectScreen> {
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WoodBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              const ScreenHeader('Choose your opponent'),
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

  Widget _card(int i) {
    final o = _opponents[i];
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
                    Text(o.name, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text(o.description, style: const TextStyle(fontSize: 16)),
                    const Spacer(),
                    const Text('DIFFICULTY', style: TextStyle(fontSize: 13, letterSpacing: 1)),
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
                          widthFactor: o.strength,
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
                  foregroundColor: selected ? GebetaColors.ink : GebetaColors.cream,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                // TODO(U2): choose who goes first (Take turns is the default), then call
                // GameController.startGame with the chosen level.
                onPressed: () {
                  if (selected) {
                    Navigator.of(context).pushNamed(Routes.game);
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
