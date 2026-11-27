import 'package:flutter/material.dart';
import 'package:gebeta/ai/levels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/app.dart' show gebetaTheme;
import 'package:gebeta/services/settings_store.dart';
import 'package:gebeta/services/stats_store.dart';
import 'package:gebeta/state/fakes.dart';
import 'package:gebeta/state/providers.dart';
import 'package:gebeta/ui/screens/settings_screen.dart';

Widget settingsApp(FakeSettingsStore settings, FakeStatsStore stats) {
  return ProviderScope(
    overrides: [
      settingsStoreProvider.overrideWithValue(settings),
      statsStoreProvider.overrideWithValue(stats),
    ],
    child: MaterialApp(theme: gebetaTheme(), home: const SettingsScreen()),
  );
}

void useLandscapePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1688, 780);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

bool switchValue(WidgetTester tester, String title) {
  final tile =
      tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, title));
  return tile.value;
}

void main() {
  testWidgets('the screen shows the defaults and the version', (tester) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(settingsApp(FakeSettingsStore(), FakeStatsStore()));
    await tester.pumpAndSettle();

    expect(switchValue(tester, 'Sound effects'), true);
    expect(switchValue(tester, 'Music'), false);
    expect(switchValue(tester, 'Haptics'), true);
    expect(find.text('Gebeta v$appVersion'), findsOneWidget);
    expect(find.text('Reset stats'), findsOneWidget);
  });

  testWidgets('every change is written to the SettingsStore', (tester) async {
    useLandscapePhone(tester);
    final store = FakeSettingsStore();
    await tester.pumpWidget(settingsApp(store, FakeStatsStore()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Music'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Haptics'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light wood'));
    await tester.pumpAndSettle();

    expect(await store.musicEnabled(), true);
    expect(await store.hapticsEnabled(), false);
    expect(await store.animationSpeed(), AnimationSpeed.fast);
    expect(await store.boardTheme(), BoardTheme.lightWood);
  });

  testWidgets('saved values come back after a restart', (tester) async {
    useLandscapePhone(tester);
    final store = FakeSettingsStore(); // the same store for both launches

    // First launch: change everything.
    await tester.pumpWidget(settingsApp(store, FakeStatsStore()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Sound effects'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Music'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Slow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light wood'));
    await tester.pumpAndSettle();

    // Close the app, then open it again with a new ProviderScope.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(settingsApp(store, FakeStatsStore()));
    await tester.pumpAndSettle();

    expect(switchValue(tester, 'Sound effects'), false);
    expect(switchValue(tester, 'Music'), true);
    final speed = tester.widget<SegmentedButton<AnimationSpeed>>(
      find.byType(SegmentedButton<AnimationSpeed>),
    );
    expect(speed.selected, {AnimationSpeed.slow});
    final board = tester.widget<SegmentedButton<BoardTheme>>(
      find.byType(SegmentedButton<BoardTheme>),
    );
    expect(board.selected, {BoardTheme.lightWood});
  });

  testWidgets('Reset stats asks first, then clears the counts', (tester) async {
    useLandscapePhone(tester);
    final stats = FakeStatsStore();
    await stats.record(Level.novice, Outcome.win);
    await tester.pumpWidget(settingsApp(FakeSettingsStore(), stats));
    await tester.pumpAndSettle();

    // Cancel: nothing changes.
    await tester.tap(find.text('Reset stats'));
    await tester.pumpAndSettle();
    expect(find.text('Reset stats?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((await stats.load()).counts, isNotEmpty);

    // Reset: the counts are cleared.
    await tester.tap(find.text('Reset stats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect((await stats.load()).counts, isEmpty);
    expect(find.text('Stats reset'), findsOneWidget);
  });
}
