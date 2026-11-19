import '../ai/ai_service.dart';

enum Outcome { win, loss, draw }

class Stats {
  const Stats(this.counts);
  final Map<Level, Map<Outcome, int>> counts;
}

/// Stub: Person 3 writes the shared_preferences version (U3-02).
class StatsStore {
  Future<Stats> load() async => throw UnimplementedError();
  Future<void> record(Level level, Outcome outcome) async =>
      throw UnimplementedError();
  Future<int?> lastFirstPlayer() async => throw UnimplementedError();
  Future<void> setLastFirstPlayer(int player) async =>
      throw UnimplementedError();
  Future<void> reset() async => throw UnimplementedError();
}
