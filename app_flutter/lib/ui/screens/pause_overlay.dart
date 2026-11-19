import 'package:flutter/material.dart';

import 'routes.dart';
import 'widgets.dart';

/// The pause menu. Resume closes it; Quit to Home asks first.
Future<void> showPauseOverlay(BuildContext context) {
  // TODO(U2): call GameController.setPaused(true) before and setPaused(false) after.
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: const Color(0xFF6E371B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paused', style: Theme.of(dialogContext).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GButton(
                      'Resume',
                      primary: true,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GButton(
                      'Restart',
                      // TODO(U2): call GameController.restartGame().
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GButton(
                      'Settings',
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pushNamed(Routes.settings);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GButton(
                      'Quit to Home',
                      onPressed: () async {
                        final leave = await showLeaveGameDialog(dialogContext);
                        if (leave == true && dialogContext.mounted && context.mounted) {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.home,
                            (route) => false,
                          );
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
    ),
  );
}

/// Asks before leaving a game. Returns true when the player chooses Leave.
Future<bool?> showLeaveGameDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF6E371B),
      title: const Text('Leave this game?'),
      content: const Text('Your progress is saved. You can continue from the home screen.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep playing'),
        ),
        TextButton(
          // TODO(U2): call GameController.abandonGame() only if the game should not be kept.
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
}
