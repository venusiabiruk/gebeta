import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/ai/ai_service.dart';
import 'package:gebeta/engine/engine.dart';
import 'package:gebeta/services/saved_game_store.dart';
import 'package:gebeta/services/stats_store.dart';
import 'package:gebeta/state/fakes.dart';
import 'package:gebeta/state/game_ui_state.dart';
import 'package:gebeta/state/providers.dart';

// ---------------------------------------------------------------- test helpers

/// An AI that answers at once with the lowest legal hole.
class InstantAi implements AiService {
  @override
  Future<void> init() async {}

  @override
  Future<int> chooseMove(GameState state, Level level, {Random? random}) async {
    return legalMoves(state).first;
  }
}

/// An AI that waits until the test completes [answer].
class HoldingAi implements AiService {
  final Completer<int> answer = Completer<int>();

  @override
  Future<void> init() async {}

  @override
  Future<int> chooseMove(GameState state, Level level, {Random? random}) {
    return answer.future;
  }
}

/// A saved-game store that remembers every save.
class RecordingSavedGameStore extends FakeSavedGameStore {
  final List<GameSnapshot> saved = [];

  @override
  Future<void> save(GameSnapshot snapshot) async {
    saved.add(snapshot);
    await super.save(snapshot);
  }
}

ProviderContainer makeContainer({
  AiService? ai,
  FakeSavedGameStore? saved,
  FakeStatsStore? stats,
}) {
  final container = ProviderContainer(
    overrides: [
      randomProvider.overrideWithValue(Random(1)),
      if (ai != null) aiServiceProvider.overrideWithValue(ai),
      if (saved != null) savedGameStoreProvider.overrideWithValue(saved),
      if (stats != null) statsStoreProvider.overrideWithValue(stats),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

GameState position(
  List<int> cells, {
  List<int> pits = const [0, 0],
  int player = 0,
  int turns = 0,
}) {
  return GameState(holes: cells, pits: pits, player: player, turns: turns);
}

GameSnapshot snapshotOf(GameState state, GameConfig config, {int? human}) {
  return GameSnapshot(
    state: state,
    config: config,
    humanPlayer: human,
    nextFirstPlayer: 1,
  );
}

// ----------------------------------------------------------------------- tests

void main() {
  const twoPlayers = GameConfig(mode: GameMode.twoPlayers);
  const vsNovice = GameConfig(
    mode: GameMode.vsAi,
    level: Level.novice,
    firstMove: FirstMove.human,
  );
  const aiFirst = GameConfig(
    mode: GameMode.vsAi,
    level: Level.novice,
    firstMove: FirstMove.ai,
  );

  group('basics', () {
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
  });

  group('playing against the AI', () {
    test('human moves, then the AI answers', () async {
      final container = makeContainer(ai: InstantAi());
      final controller = container.read(gameControllerProvider.notifier);
      controller.startGame(vsNovice); // the human starts
      await pumpEventQueue();

      var state = container.read(gameControllerProvider);
      expect(state.phase, Phase.awaitingInput);
      expect(state.game.player, 0);
      expect(state.humanPlayer, 0);

      controller.onHoleTapped(2);
      controller.onEventsDone(); // the board finished the human's animation
      state = container.read(gameControllerProvider);
      expect(state.phase, Phase.aiThinking);
      expect(state.game.player, 1);

      await pumpEventQueue(); // the AI answers
      state = container.read(gameControllerProvider);
      expect(state.phase, Phase.animating);
      expect(state.pendingEvents, isNotEmpty);
      expect(state.pendingAfter!.player, 0);

      controller.onEventsDone();
      state = container.read(gameControllerProvider);
      expect(state.phase, Phase.awaitingInput);
      expect(state.game.player, 0);
      expect(state.game.turns, 2);
    });

    test('the AI plays first when firstMove is ai', () async {
      final container = makeContainer(ai: InstantAi());
      final controller = container.read(gameControllerProvider.notifier);
      controller.startGame(aiFirst);
      await pumpEventQueue();

      var state = container.read(gameControllerProvider);
      expect(state.humanPlayer, 0);
      expect(state.game.player, 1); // the AI is to move
      expect(state.phase, Phase.animating); // and has already chosen
      expect(state.pendingEvents, isNotEmpty);

      controller.onEventsDone();
      state = container.read(gameControllerProvider);
      expect(state.phase, Phase.awaitingInput);
      expect(state.game.player, 0);
    });

    test('a late AI answer is ignored after abandonGame', () async {
      final ai = HoldingAi();
      final container = makeContainer(ai: ai);
      final controller = container.read(gameControllerProvider.notifier);
      controller.startGame(aiFirst);
      await pumpEventQueue();
      expect(container.read(gameControllerProvider).phase, Phase.aiThinking);

      controller.abandonGame();
      expect(container.read(gameControllerProvider).phase, Phase.idle);

      ai.answer.complete(6); // the AI answers too late
      await pumpEventQueue();
      final state = container.read(gameControllerProvider);
      expect(state.phase, Phase.idle);
      expect(state.pendingEvents, isNull);
    });

    test('an AI answer that arrives while paused is held until resume',
        () async {
      final ai = HoldingAi();
      final container = makeContainer(ai: ai);
      final controller = container.read(gameControllerProvider.notifier);
      controller.startGame(aiFirst);
      await pumpEventQueue();

      controller.setPaused(true);
      ai.answer.complete(6);
      await pumpEventQueue();
      var state = container.read(gameControllerProvider);
      expect(state.phase, Phase.aiThinking);
      expect(state.pendingEvents, isNull);

      controller.setPaused(false);
      state = container.read(gameControllerProvider);
      expect(state.phase, Phase.animating);
      expect(state.pendingEvents, isNotEmpty);
    });
  });

  group('the end of a game', () {
    test('game over when the next player has no seeds', () async {
      final saved = FakeSavedGameStore();
      final stats = FakeStatsStore();
      final container = makeContainer(saved: saved, stats: stats);
      final controller = container.read(gameControllerProvider.notifier);

      // Player 0 plays hole 3. The seed lands in empty hole 4 and captures the
      // 3 seeds in hole 7, so player 1 is left with nothing.
      final start = position(
        [0, 0, 0, 1, 0, 0, 0, 3, 0, 0, 0, 0],
        pits: [10, 10],
      );
      await saved.save(snapshotOf(start, vsNovice, human: 0));
      controller.resumeGame(snapshotOf(start, vsNovice, human: 0));

      controller.onHoleTapped(3);
      controller.onEventsDone();
      await pumpEventQueue();

      final state = container.read(gameControllerProvider);
      expect(state.phase, Phase.gameOver);
      expect(state.result, 0);
      expect(
          state.finalPits, [14, 10]); // 13 after the capture, plus 1 leftover

      final counts = (await stats.load()).counts;
      expect(counts[Level.novice]?[Outcome.win], 1);
      expect(await saved.load(), isNull); // the saved game was cleared
    });

    test('game over at the turn cap', () async {
      final container = makeContainer();
      final controller = container.read(gameControllerProvider.notifier);

      final almost = position(
        List<int>.filled(12, 4),
        pits: [10, 12],
        turns: gameTurnCap - 1,
      );
      controller.resumeGame(snapshotOf(almost, vsNovice, human: 0));

      controller.onHoleTapped(0);
      controller.onEventsDone();
      await pumpEventQueue();

      final state = container.read(gameControllerProvider);
      expect(state.phase, Phase.gameOver);
      expect(state.game.turns, gameTurnCap);
      // At the cap the pits are compared as they stand.
      expect(state.finalPits, [state.game.pits[0], state.game.pits[1]]);
      expect(state.result, winner(state.game));
    });
  });

  group('resume', () {
    test('goes straight to the saved position with no animation', () async {
      final container = makeContainer();
      final controller = container.read(gameControllerProvider.notifier);

      final saved = position(
        [6, 6, 2, 7, 1, 6, 1, 0, 6, 6, 0, 1],
        pits: [6, 0],
        player: 1,
        turns: 1,
      );
      controller.resumeGame(snapshotOf(saved, twoPlayers));

      final state = container.read(gameControllerProvider);
      expect(state.game, saved);
      expect(state.phase, Phase.awaitingInput);
      expect(state.pendingEvents, isNull);
      expect(state.flipForPlayerOne, true); // player 1 is to move
    });
  });

  group('taps are ignored', () {
    test('when no game is running', () {
      final container = makeContainer();
      final controller = container.read(gameControllerProvider.notifier);
      final before = container.read(gameControllerProvider);

      controller.onHoleTapped(0);

      final state = container.read(gameControllerProvider);
      expect(state.phase, Phase.idle);
      expect(state.game, before.game);
    });

    test('while the board is animating', () async {
      final container = makeContainer();
      final controller = container.read(gameControllerProvider.notifier);
      controller.startGame(twoPlayers);
      await pumpEventQueue();

      final moves = legalMoves(container.read(gameControllerProvider).game);
      controller.onHoleTapped(moves[0]);
      final events = container.read(gameControllerProvider).pendingEvents;

      controller.onHoleTapped(moves[1]); // a second tap, too early

      final state = container.read(gameControllerProvider);
      expect(state.phase, Phase.animating);
      expect(state.pendingEvents, same(events));
    });

    test('while the AI is thinking', () async {
      final ai = HoldingAi();
      final container = makeContainer(ai: ai);
      final controller = container.read(gameControllerProvider.notifier);
      controller.startGame(aiFirst);
      await pumpEventQueue();

      controller.onHoleTapped(0);

      final state = container.read(gameControllerProvider);
      expect(state.phase, Phase.aiThinking);
      expect(state.pendingEvents, isNull);
    });

    test('while the game is paused', () async {
      final container = makeContainer();
      final controller = container.read(gameControllerProvider.notifier);
      controller.startGame(twoPlayers);
      await pumpEventQueue();
      final move =
          legalMoves(container.read(gameControllerProvider).game).first;

      controller.setPaused(true);
      controller.onHoleTapped(move);
      expect(container.read(gameControllerProvider).phase, Phase.awaitingInput);

      controller.setPaused(false);
      controller.onHoleTapped(move);
      expect(container.read(gameControllerProvider).phase, Phase.animating);
    });
  });

  group('saving', () {
    test('the game is saved right after each move', () async {
      final saved = RecordingSavedGameStore();
      final container = makeContainer(saved: saved);
      final controller = container.read(gameControllerProvider.notifier);
      controller.startGame(twoPlayers);
      await pumpEventQueue();
      expect(saved.saved, isEmpty);

      final first =
          legalMoves(container.read(gameControllerProvider).game).first;
      controller.onHoleTapped(first);
      await pumpEventQueue();
      expect(saved.saved.length, 1);
      // The saved position is the one after the move, before the animation ends.
      expect(
        saved.saved.last.state,
        container.read(gameControllerProvider).pendingAfter,
      );

      controller.onEventsDone();
      final second =
          legalMoves(container.read(gameControllerProvider).game).first;
      controller.onHoleTapped(second);
      await pumpEventQueue();
      expect(saved.saved.length, 2);
    });
  });
}
