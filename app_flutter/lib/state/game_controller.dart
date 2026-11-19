import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/saved_game_store.dart';
import 'game_ui_state.dart';

/// Stub controller. The public methods are final, the behavior comes in U2-03.
class GameController extends Notifier<GameUiState> {
  @override
  GameUiState build() => GameUiState.initial();

  /// Starts a new game. TODO(U2-03): first-player rule, AI turn, saving.
  void startGame(GameConfig config) {
    state = GameUiState(
      game: GameUiState.initial().game,
      phase: Phase.awaitingInput,
      config: config,
      humanPlayer: config.mode == GameMode.vsAi ? 0 : null,
    );
  }

  /// Same config, a new game.
  void restartGame() {
    final config = state.config;
    if (config != null) startGame(config);
  }

  void resumeGame(GameSnapshot snapshot) {
    state = GameUiState(
      game: snapshot.state,
      phase: Phase.awaitingInput,
      config: snapshot.config,
      humanPlayer: snapshot.humanPlayer,
    );
  }

  /// TODO(U2-03): applyMove, publish events, save the game.
  void onHoleTapped(int hole) {}

  /// TODO(U2-03): game over, AI turn, or wait for input.
  void onEventsDone() {}

  /// Pause overlay: taps are ignored and an AI move is held while paused.
  void setPaused(bool paused) {
    state = state.copyWith(paused: paused);
  }

  /// Back to idle. TODO(U2-03): also clear the saved game.
  void abandonGame() {
    state = GameUiState.initial();
  }
}
