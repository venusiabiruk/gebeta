import 'package:flutter/material.dart';

import 'widgets.dart';

/// Placeholder settings screen with local state.
/// TODO(U2): read and write SettingsStore (Person 3) and reset stats through StatsStore.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sound = true;
  bool _music = false;
  bool _haptics = true;
  String _speed = 'normal';
  String _board = 'dark';

  @override
  Widget build(BuildContext context) {
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
                        child: Material(
                          type: MaterialType.transparency,
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Sound effects'),
                                value: _sound,
                                onChanged: (v) => setState(() => _sound = v),
                              ),
                              SwitchListTile(
                                title: const Text('Music'),
                                value: _music,
                                onChanged: (v) => setState(() => _music = v),
                              ),
                              SwitchListTile(
                                title: const Text('Haptics'),
                                value: _haptics,
                                onChanged: (v) => setState(() => _haptics = v),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Animation speed', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'slow', label: Text('Slow')),
                                ButtonSegment(value: 'normal', label: Text('Normal')),
                                ButtonSegment(value: 'fast', label: Text('Fast')),
                              ],
                              selected: {_speed},
                              onSelectionChanged: (s) => setState(() => _speed = s.first),
                            ),
                            const SizedBox(height: 16),
                            const Text('Board', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'dark', label: Text('Dark wood')),
                                ButtonSegment(value: 'light', label: Text('Light wood')),
                              ],
                              selected: {_board},
                              onSelectionChanged: (s) => setState(() => _board = s.first),
                            ),
                            const Spacer(),
                            const Text('Gebeta v1.0', style: TextStyle(fontSize: 14)),
                          ],
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
