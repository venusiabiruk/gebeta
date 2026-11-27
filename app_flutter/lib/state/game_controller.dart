import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/engine.dart';
import '../services/saved_game_store.dart';
import '../services/stats_store.dart';
import 'game_ui_state.dart';
import 'providers.dart';

/// Drives the whole game flow. Screens read its state and call its methods.
class GameController extends Notifier<GameUiState> {
  // The human is always player 0 (the bottom row) in a game against the AI.
  static const int _human = 0;

  // Goes up when a game starts, restarts or is abandoned. A late AI answer
  // that carries an old number is ignored.
  int _gameId = 0;

  // Who starts the game after this one (saved with the game).
  int _nextFirstPlayer = 0;

  // An AI move that arrived while the game was paused. It is played on resume.
  int? _heldAiMove;

  @override
  GameUiState build() => GameUiState.initial();

  // ---------------------------------------------------------------- starting

  void startGame(GameConfig config) {
    unawaited(_begin(config));
  }

  /// Same config, a new game.
  void restartGame() {
    final config = state.config;
    if (config != null) {
      startGame(config);
    }
  }

  Future<void> _begin(GameConfig config) async {
    _gameId++;
    final id = _gameId;
    _heldAiMove = null;

    final first = await _pickFirstPlayer(config);
    if (id != _gameId) return; // abandoned or restarted while we waited
    _nextFirstPlayer = 1 - first;

    await _safely(() => ref.read(statsStoreProvider).setLastFirstPlayer(first));
    await _safely(() => ref.read(savedGameStoreProvider).clear());
    if (id != _gameId) return;

    state = GameUiState(
      game: newGame(firstPlayer: first),
      phase: Phase.awaitingInput,
      config: config,
      humanPlayer: config.mode == GameMode.vsAi ? _human : null,
    );
    _continueFromRest(id);
  }

  Future<int> _pickFirstPlayer(GameConfig config) async {
    if (config.mode == GameMode.vsAi) {
      if (config.firstMove == FirstMove.human) return _human;
      if (config.firstMove == FirstMove.ai) return 1 - _human;
    }
    // Alternate, and every two-player game: the first game is random,
    // then the first player swaps each game.
    int? last;
    try {
      last = await ref.read(statsStoreProvider).lastFirstPlayer();
    } catch (e) {
      debugPrint('lastFirstPlayer failed: $e');
    }
    if (last == null) {
      return ref.read(randomProvider).nextInt(2);
    }
    return 1 - last;
  }

  /// Continue a saved game. It shows the saved position at once, no animation.
  void resumeGame(GameSnapshot snapshot) {
    _gameId++;
    final id = _gameId;
    _heldAiMove = null;
    _nextFirstPlayer = snapshot.nextFirstPlayer;

    state = GameUiState(
      game: snapshot.state,
      phase: Phase.awaitingInput,
      config: snapshot.config,
      humanPlayer: snapshot.humanPlayer,
    );
    if (isGameOver(snapshot.state)) {
      _finish(snapshot.state);
    } else {
      _continueFromRest(id);
    }
  }

  // ----------------------------------------------------------------- playing

  /// A tap on a hole. Ignored unless we wait for input and the hole is legal.
  void onHoleTapped(int hole) {
    if (state.phase != Phase.awaitingInput) return;
    if (state.paused) return;
    if (!legalMoves(state.game).contains(hole)) return;
    _play(hole);
  }

  /// Play one move: work out the result, hand the events to the board,
  /// and save the position after the move right away.
  void _play(int hole) {
    final result = applyMove(state.game, hole);
    state = state.copyWith(
      pendingEvents: result.events,
      pendingAfter: result.state,
      phase: Phase.animating,
    );
    unawaited(_saveSnapshot(result.state));
  }

  /// The board calls this when the animation has finished.
  void onEventsDone() {
    if (state.phase != Phase.animating) return;
    final after = state.pendingAfter;
    if (after == null) return;

    state = state.copyWith(
      game: after,
      clearPending: true,
      phase: Phase.awaitingInput,
    );
    if (isGameOver(after)) {
      _finish(after);
    } else {
      _continueFromRest(_gameId);
    }
  }

  /// The position is at rest. Either the AI moves next, or we wait for a tap.
  void _continueFromRest(int id) {
    if (_isAiTurn()) {
      state = state.copyWith(phase: Phase.aiThinking);
      unawaited(_runAi(id));
    } else {
      state = state.copyWith(phase: Phase.awaitingInput);
    }
  }

  bool _isAiTurn() {
    final config = state.config;
    if (config == null) return false;
    if (config.mode != GameMode.vsAi) return false;
    return state.game.player != state.humanPlayer;
  }

  /// Ask the AI for a move and play it like a tap.
  Future<void> _runAi(int id) async {
    final level = state.config?.level;
    if (level == null) return;

    int hole;
    try {
      hole = await ref.read(aiServiceProvider).chooseMove(
            state.game,
            level,
            random: ref.read(randomProvider),
          );
    } catch (e) {
      debugPrint('The AI failed, playing the lowest legal hole: $e');
      hole = legalMoves(state.game).first;
    }

    if (id != _gameId) return; // the game was abandoned or restarted
    if (state.phase != Phase.aiThinking) return;
    if (state.paused) {
      _heldAiMove = hole; // play it when the game is resumed
      return;
    }
    _play(hole);
  }

  // ---------------------------------------------------------------- game end

  void _finish(GameState position) {
    final result = winner(position);
    state = state.copyWith(
      game: position,
      clearPending: true,
      phase: Phase.gameOver,
      result: result,
      finalPits: finalPits(position),
    );
    unawaited(_recordResult(result));
  }

  Future<void> _recordResult(int result) async {
    final config = state.config;
    final level = config?.level;
    if (config != null && config.mode == GameMode.vsAi && level != null) {
      Outcome outcome;
      if (result == draw) {
        outcome = Outcome.draw;
      } else if (result == _human) {
        outcome = Outcome.win;
      } else {
        outcome = Outcome.loss;
      }
      await _safely(() => ref.read(statsStoreProvider).record(level, outcome));
    }
    await _safely(() => ref.read(savedGameStoreProvider).clear());
  }

  // ------------------------------------------------------- pause and abandon

  /// Pause overlay: taps are ignored and an AI move is held while paused.
  void setPaused(bool paused) {
    state = state.copyWith(paused: paused);
    final held = _heldAiMove;
    if (!paused && held != null) {
      _heldAiMove = null;
      if (state.phase == Phase.aiThinking) {
        _play(held);
      }
    }
  }

  /// Back to idle and the saved game is deleted.
  void abandonGame() {
    _gameId++; // any AI answer still on its way is now ignored
    _heldAiMove = null;
    state = GameUiState.initial();
    unawaited(_safely(() => ref.read(savedGameStoreProvider).clear()));
  }

  // ----------------------------------------------------------------- helpers

  Future<void> _saveSnapshot(GameState position) async {
    final config = state.config;
    if (config == null) return;
    final snapshot = GameSnapshot(
      state: position,
      config: config,
      humanPlayer: state.humanPlayer,
      nextFirstPlayer: _nextFirstPlayer,
    );
    await _safely(() => ref.read(savedGameStoreProvider).save(snapshot));
  }

  /// Storage must never crash the game, so errors are only printed.
  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Storage problem (ignored): $e');
    }
  }
}
