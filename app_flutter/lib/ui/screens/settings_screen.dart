import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/settings_store.dart';
import '../../state/providers.dart';
import '../../state/settings_state.dart';
import 'widgets.dart';

/// Shown at the bottom of the screen. Keep it equal to `version:` in pubspec.yaml.
const String appVersion = '1.0.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Ask first, then set the win, loss and draw counts back to zero.
  Future<void> _resetStats(BuildContext context, WidgetRef ref) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset stats?'),
        content:
            const Text('Your wins, losses and draws will be set back to zero.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (sure != true) return;

    var message = 'Stats reset';
    try {
      await ref.read(statsStoreProvider).reset();
    } catch (e) {
      debugPrint('Could not reset the stats: $e');
      message = 'Could not reset the stats';
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: WoodBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              const ScreenHeader('Settings'),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: GPanel(
                        child: SingleChildScrollView(
                          child: Material(
                            type: MaterialType.transparency,
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: const Text('Sound effects'),
                                  value: settings.sound,
                                  onChanged: notifier.setSound,
                                ),
                                SwitchListTile(
                                  title: const Text('Music'),
                                  value: settings.music,
                                  onChanged: notifier.setMusic,
                                ),
                                SwitchListTile(
                                  title: const Text('Haptics'),
                                  value: settings.haptics,
                                  onChanged: notifier.setHaptics,
                                ),
                                const SizedBox(height: 12),
                                GButton(
                                  'Reset stats',
                                  onPressed: () => _resetStats(context, ref),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GPanel(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Animation speed',
                                  style: TextStyle(fontSize: 18)),
                              const SizedBox(height: 8),
                              SegmentedButton<AnimationSpeed>(
                                segments: const [
                                  ButtonSegment<AnimationSpeed>(
                                    value: AnimationSpeed.slow,
                                    label: Text('Slow'),
                                  ),
                                  ButtonSegment<AnimationSpeed>(
                                    value: AnimationSpeed.normal,
                                    label: Text('Normal'),
                                  ),
                                  ButtonSegment<AnimationSpeed>(
                                    value: AnimationSpeed.fast,
                                    label: Text('Fast'),
                                  ),
                                ],
                                selected: {settings.speed},
                                onSelectionChanged: (choice) =>
                                    notifier.setSpeed(choice.first),
                              ),
                              const SizedBox(height: 16),
                              const Text('Board',
                                  style: TextStyle(fontSize: 18)),
                              const SizedBox(height: 8),
                              SegmentedButton<BoardTheme>(
                                segments: const [
                                  ButtonSegment<BoardTheme>(
                                    value: BoardTheme.darkWood,
                                    label: Text('Dark wood'),
                                  ),
                                  ButtonSegment<BoardTheme>(
                                    value: BoardTheme.lightWood,
                                    label: Text('Light wood'),
                                  ),
                                ],
                                selected: {settings.board},
                                onSelectionChanged: (choice) =>
                                    notifier.setBoard(choice.first),
                              ),
                              const SizedBox(height: 16),
                              const Text('Gebeta v$appVersion',
                                  style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
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
