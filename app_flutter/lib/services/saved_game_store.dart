import '../engine/engine.dart';
import '../state/game_ui_state.dart';

/// A saved game. Stub: Person 3 writes toJson and fromJson (U3-02).
class GameSnapshot {
  const GameSnapshot({
    required this.state,
    required this.config,
    required this.humanPlayer,
    required this.nextFirstPlayer,
  });

  final GameState state;
  final GameConfig config;
  final int? humanPlayer;
  final int nextFirstPlayer;

  Map<String, dynamic> toJson() => throw UnimplementedError();
  factory GameSnapshot.fromJson(Map<String, dynamic> json) =>
      throw UnimplementedError();
}

class SavedGameStore {
  Future<void> save(GameSnapshot snapshot) async => throw UnimplementedError();
  Future<GameSnapshot?> load() async => throw UnimplementedError();
  Future<void> clear() async => throw UnimplementedError();
}
