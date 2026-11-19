import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/app.dart';

void main() {
  testWidgets('splash opens home, and home reaches the other screens',
      (tester) async {
    // A landscape phone: 844 x 390 logical pixels.
    tester.view.physicalSize = const Size(1688, 780);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: GebetaApp()));
    expect(find.text('Gebeta'), findsOneWidget); // splash

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    expect(find.text('Play vs Computer'), findsOneWidget); // home

    // How to play
    await tester.tap(find.text('How to Play'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson 1 of 5'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson 2 of 5'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Settings
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Sound effects'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Opponent select, then the game screen and its pause overlay
    await tester.tap(find.text('Play vs Computer'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your opponent'), findsOneWidget);
    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();
    expect(find.text('BoardView goes here (Person 1, U1)'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Paused'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(find.text('Paused'), findsNothing);
  });
}