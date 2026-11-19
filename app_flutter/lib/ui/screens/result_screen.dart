import 'package:flutter/material.dart';

import 'palette.dart';
import 'routes.dart';
import 'widgets.dart';

/// Placeholder result screen. The real one reads GameUiState.result and finalPits.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WoodBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You won!',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 72,
                      color: GebetaColors.gold,
                    ),
              ),
              const SizedBox(height: 6),
              const Text('A great game against Master.', style: TextStyle(fontSize: 19)),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _card(context, 'You', '26', true),
                  const SizedBox(width: 18),
                  _card(context, 'Computer', '22', false),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 180,
                    child: GButton(
                      'Play Again',
                      primary: true,
                      // TODO(U2): call GameController.restartGame().
                      onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.game),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 140,
                    child: GButton(
                      'Home',
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil(Routes.home, (route) => false),
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

  Widget _card(BuildContext context, String name, String value, bool winner) {
    return SizedBox(
      width: 200,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: GebetaColors.panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: winner ? GebetaColors.gold : const Color(0x99FFC878),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(name, style: const TextStyle(fontSize: 16)),
            Text(
              value,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 54,
                    color: winner ? GebetaColors.gold : GebetaColors.cream,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
