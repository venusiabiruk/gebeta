import 'dart:math';

import 'package:gebeta/ai/levels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/ai/ai_service.dart';
import 'package:gebeta/app.dart';
import 'package:gebeta/engine/engine.dart';
import 'package:gebeta/services/saved_game_store.dart';
import 'package:gebeta/state/fakes.dart';
import 'package:gebeta/state/game_ui_state.dart';
import 'package:gebeta/state/providers.dart';

/// An AI that only remembers that init was called.
class SpyAi implements AiService {
  bool initCalled = false;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  Future<int> chooseMove(GameState state, Level level, {Random? random}) async {
    return legalMoves(state).first;
  }
}

/// Opens the app on a landscape phone with reduced motion,
/// and waits past the splash.
Future<ProviderContainer> openHome(
  WidgetTester tester, {
  SavedGameStore? savedStore,
}) async {
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
        savedGameStoreProvider.overrideWithValue(
          savedStore ?? FakeSavedGameStore(),
        ),
        settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
      ],
      child: const GebetaApp(),
    ),
  );

  await tester.pump(const Duration(milliseconds: 1600));
  await tester.pumpAndSettle();

  return ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
}

void main() {
  const savedPosition = [6, 6, 2, 7, 1, 6, 1, 0, 6, 6, 0, 1];

  testWidgets('the splash starts the AI service and then shows Home',
      (tester) async {
    final ai = SpyAi();

    tester.view.physicalSize = const Size(1688, 780);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(ai),
          statsStoreProvider.overrideWithValue(FakeStatsStore()),
          savedGameStoreProvider.overrideWithValue(FakeSavedGameStore()),
          settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
        ],
        child: const GebetaApp(),
      ),
    );

    expect(find.text('The traditional Ethiopian seed game'), findsOneWidget);
    expect(ai.initCalled, true);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Play vs Computer'), findsOneWidget);
  });

  testWidgets('Home has no Resume button without a saved game', (tester) async {
    await openHome(tester);

    expect(find.text('Resume'), findsNothing);
    expect(find.text('Play vs Computer'), findsOneWidget);
    expect(find.text('Play with a Friend'), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets('Home shows Resume when a game is saved, and Resume restores it',
      (tester) async {
    final store = FakeSavedGameStore();

    final saved = GameState(
      holes: savedPosition,
      pits: const [6, 0],
      player: 1,
      turns: 1,
    );

    await store.save(
      GameSnapshot(
        state: saved,
        config: const GameConfig(mode: GameMode.twoPlayers),
        humanPlayer: null,
        nextFirstPlayer: 1,
      ),
    );

    final container = await openHome(
      tester,
      savedStore: store,
    );

    expect(find.text('Resume'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();

    final state = container.read(gameControllerProvider);

    expect(state.game, saved);
    expect(state.phase, Phase.awaitingInput);
    expect(state.pendingEvents, isNull);
  });

  testWidgets('Play with a Friend starts a two-player game', (tester) async {
    final container = await openHome(tester);

    await tester.tap(find.text('Play with a Friend'));
    await tester.pumpAndSettle();

    final state = container.read(gameControllerProvider);

    expect(state.config?.mode, GameMode.twoPlayers);
    expect(state.phase, Phase.awaitingInput);
  });

  testWidgets('Play vs Computer opens the opponent screen', (tester) async {
    await openHome(tester);

    await tester.tap(find.text('Play vs Computer'));
    await tester.pumpAndSettle();

    expect(find.text('Choose your opponent'), findsOneWidget);
  });
}
