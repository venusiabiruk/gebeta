import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/engine/rules.dart';
import 'package:gebeta/state/game_ui_state.dart';
import 'package:gebeta/state/providers.dart';

ProviderContainer makeContainer() {
  final container = ProviderContainer(
    overrides: [randomProvider.overrideWithValue(Random(1))],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  const twoPlayers = GameConfig(mode: GameMode.twoPlayers);

  test('a two-player game starts and waits for a tap', () async {
    final container = makeContainer();
    container.read(gameControllerProvider.notifier).startGame(twoPlayers);
    await pumpEventQueue();

    final state = container.read(gameControllerProvider);
    expect(state.phase, Phase.awaitingInput);
    expect(state.game.holes, List<int>.filled(12, 4));
  });

  test('a legal tap animates, then the turn passes', () async {
    final container = makeContainer();
    final controller = container.read(gameControllerProvider.notifier);
    controller.startGame(twoPlayers);
    await pumpEventQueue();

    final before = container.read(gameControllerProvider).game;
    controller.onHoleTapped(legalMoves(before).first);

    var state = container.read(gameControllerProvider);
    expect(state.phase, Phase.animating);
    expect(state.pendingEvents, isNotEmpty);

    controller.onEventsDone();
    state = container.read(gameControllerProvider);
    expect(state.phase, Phase.awaitingInput);
    expect(state.pendingEvents, isNull);
    expect(state.game.player, 1 - before.player);
    expect(state.game.turns, 1);
  });

  test('a tap on the other side is ignored', () async {
    final container = makeContainer();
    final controller = container.read(gameControllerProvider.notifier);
    controller.startGame(twoPlayers);
    await pumpEventQueue();

    final before = container.read(gameControllerProvider).game;
    final otherSideHole = before.player == 0 ? 6 : 0;
    controller.onHoleTapped(otherSideHole);

    final state = container.read(gameControllerProvider);
    expect(state.phase, Phase.awaitingInput);
    expect(state.game, before);
  });

  test('abandonGame goes back to idle', () async {
    final container = makeContainer();
    final controller = container.read(gameControllerProvider.notifier);
    controller.startGame(twoPlayers);
    await pumpEventQueue();

    controller.abandonGame();
    expect(container.read(gameControllerProvider).phase, Phase.idle);
  });
}
