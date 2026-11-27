import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gebeta/app.dart' show gebetaTheme;
import 'package:gebeta/ui/screens/how_to_play_screen.dart';

Widget screen() {
  return MaterialApp(theme: gebetaTheme(), home: const HowToPlayScreen());
}

void useLandscapePhone(WidgetTester tester, {required bool reducedMotion}) {
  tester.view.physicalSize = const Size(1688, 780);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  if (reducedMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
}

void main() {
  // For each lesson: the title, and the caption shown on its final frame.
  const lessons = [
    ['Goal and board', 'Seeds in your pit are your score. Most seeds wins.'],
    [
      'Sowing',
      'The last seed landed on a hole with seeds. That starts a relay (lesson 4).',
    ],
    ['Capture', 'The 2 seeds across from it are captured into your pit.'],
    ['Relay', 'The last seed landed in an empty hole, so the turn ends.'],
    ['End of the game', 'You win, 28 seeds to 20.'],
  ];

  testWidgets('all five lessons show, with Back and Next', (tester) async {
    useLandscapePhone(tester, reducedMotion: true);
    await tester.pumpWidget(screen());

    for (var i = 0; i < lessons.length; i++) {
      expect(find.text('Lesson ${i + 1} of 5'), findsOneWidget);
      expect(find.text(lessons[i][0]), findsOneWidget);
      expect(find.text(lessons[i][1]), findsOneWidget);
      if (i < lessons.length - 1) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
    }
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Next'), findsNothing);

    // Go back one lesson.
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson 4 of 5'), findsOneWidget);
    expect(find.text('Relay'), findsOneWidget);
  });

  testWidgets('Back does nothing on the first lesson', (tester) async {
    useLandscapePhone(tester, reducedMotion: true);
    await tester.pumpWidget(screen());

    await tester.tap(find.text('Back'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Lesson 1 of 5'), findsOneWidget);
  });

  testWidgets('the demo board plays its frames when motion is on',
      (tester) async {
    useLandscapePhone(tester, reducedMotion: false);
    await tester.pumpWidget(screen());

    // The first frame of lesson 1.
    expect(
      find.text('Each side has 6 holes with 4 seeds. Yours are on the bottom.'),
      findsOneWidget,
    );

    // After 1.5 seconds the next frame appears.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    expect(
      find.text('Seeds in your pit are your score. Most seeds wins.'),
      findsOneWidget,
    );

    // Remove the screen so the timer stops before the test ends.
    await tester.pumpWidget(const SizedBox());
  });
}
