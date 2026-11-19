import '../ai/ai_service.dart';
import '../engine/engine.dart';

enum GameMode { twoPlayers, vsAi }

enum FirstMove { alternate, human, ai } // default: alternate

enum Phase { idle, awaitingInput, animating, aiThinking, gameOver }

class GameConfig {
  const GameConfig({
    required this.mode,
    this.level, // null in two-player mode
    this.firstMove = FirstMove.alternate, // ignored in two-player mode
  });

  final GameMode mode;
  final Level? level;
  final FirstMove firstMove;
}

class GameUiState {
  const GameUiState({
    required this.game,
    this.pendingEvents,
    this.pendingAfter,
    this.phase = Phase.idle,
    this.config,
    this.humanPlayer,
    this.paused = false,
    this.result,
    this.finalPits,
  });

  /// Nothing is happening: a fresh board, no config.
  factory GameUiState.initial() => GameUiState(
        game: GameState(holes: List<int>.filled(12, 4), pits: [0, 0], player: 0),
      );

  final GameState game; // the position at rest
  final List<GameEvent>? pendingEvents; // being animated, null at rest
  final GameState? pendingAfter; // the position after pendingEvents
  final Phase phase;
  final GameConfig? config;
  final int? humanPlayer; // vsAi: 0 or 1, null in two-player mode
  final bool paused; // true while the pause overlay is open
  final int? result; // 0, 1 or -1 (draw) once gameOver, else null
  final List<int>? finalPits; // once gameOver

  /// Copies the fields the stubs need. U2-03 may extend it.
  GameUiState copyWith({GameState? game, Phase? phase, bool? paused}) {
    return GameUiState(
      game: game ?? this.game,
      pendingEvents: pendingEvents,
      pendingAfter: pendingAfter,
      phase: phase ?? this.phase,
      config: config,
      humanPlayer: humanPlayer,
      paused: paused ?? this.paused,
      result: result,
      finalPits: finalPits,
    );
  }
}
