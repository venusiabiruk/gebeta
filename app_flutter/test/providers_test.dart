import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/ai/ai_service.dart';
import 'package:gebeta/state/game_ui_state.dart';
import 'package:gebeta/state/providers.dart';

void main() {
  test('the controller starts idle, starts a game, and abandons it', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(gameControllerProvider).phase, Phase.idle);

    final controller = container.read(gameControllerProvider.notifier);
    controller.startGame(const GameConfig(mode: GameMode.twoPlayers));
    expect(container.read(gameControllerProvider).phase, Phase.awaitingInput);

    controller.setPaused(true);
    expect(container.read(gameControllerProvider).paused, true);

    controller.abandonGame();
    expect(container.read(gameControllerProvider).phase, Phase.idle);
  });

  test('providers can be overridden', () {
    final fake = FakeAiService();
    final container = ProviderContainer(
      overrides: [aiServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    expect(container.read(aiServiceProvider), same(fake));
  });
}
