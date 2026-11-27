import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import 'package:gebeta/ai/ai_service.dart';
import 'package:gebeta/ai/levels.dart';
import 'package:gebeta/app.dart';
import 'package:gebeta/engine/game_state.dart';
import 'package:gebeta/state/fakes.dart';
import 'package:gebeta/state/game_ui_state.dart';
import 'package:gebeta/state/providers.dart';

/// Test AI that returns a legal move immediately.
///
/// Unlike FakeAiService, this implementation does not wait 600 ms.
/// This prevents pending timers when a test starts with the AI's turn.
class ImmediateAiService implements AiService {
  @override
  Future<void> init() async {}

  @override
  Future<int> chooseMove(
    GameState state,
    Level level, {
    Random? random,
  }) async {
    final start = state.player == 0 ? 0 : 6;

    for (var hole = start; hole < start + 6; hole++) {
      if (state.holes[hole] > 0) {
        return hole;
      }
    }

    throw StateError('No legal moves');
  }
}

/// Opens the app on a landscape phone with reduced motion, goes past the
/// splash screen, and opens the opponent selection screen.
Future<ProviderContainer> openOpponentScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1688, 780);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        statsStoreProvider.overrideWithValue(FakeStatsStore()),
        savedGameStoreProvider.overrideWithValue(FakeSavedGameStore()),
        settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
        aiServiceProvider.overrideWithValue(ImmediateAiService()),
      ],
      child: const GebetaApp(),
    ),
  );

  // Wait for the splash screen to finish.
  await tester.pump(const Duration(milliseconds: 1800));
  await tester.pumpAndSettle();
   // Temporary debugging output.

  // Navigate to opponent selection.
  await tester.tap(find.text('Play vs Computer'));
  await tester.pumpAndSettle();

  expect(find.text('Choose your opponent'), findsOneWidget);

  return ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
}

void main() {
  testWidgets('the defaults are Amateur and Take turns', (tester) async {
    final container = await openOpponentScreen(tester);

    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    final config = container.read(gameControllerProvider).config;

    expect(config?.mode, GameMode.vsAi);
    expect(config?.level, Level.amateur);
    expect(config?.firstMove, FirstMove.alternate);
  });

  testWidgets('choosing Master and "I start" gives that GameConfig',
      (tester) async {
    final container = await openOpponentScreen(tester);

    await tester.tap(find.text('Master'));
    await tester.pump();

    await tester.tap(find.text('I start'));
    await tester.pump();

    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    final state = container.read(gameControllerProvider);

    expect(state.config?.mode, GameMode.vsAi);
    expect(state.config?.level, Level.master);
    expect(state.config?.firstMove, FirstMove.human);
    expect(state.humanPlayer, 0);
    expect(state.game.player, 0);
  });

  testWidgets('choosing Novice and "Computer starts" gives that GameConfig',
      (tester) async {
    final container = await openOpponentScreen(tester);

    await tester.tap(find.text('Novice'));
    await tester.pump();

    await tester.tap(find.text('Computer starts'));
    await tester.pump();

    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    final config = container.read(gameControllerProvider).config;

    expect(config?.mode, GameMode.vsAi);
    expect(config?.level, Level.novice);
    expect(config?.firstMove, FirstMove.ai);
  });

  testWidgets('the Select button on another card only selects it',
      (tester) async {
    final container = await openOpponentScreen(tester);

    await tester.tap(find.text('Select').first);
    await tester.pump();

    // Selecting another opponent must not start a game.
    expect(container.read(gameControllerProvider).config, isNull);
    expect(find.text('Choose your opponent'), findsOneWidget);
  });
}
