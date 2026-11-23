import 'package:flutter_test/flutter_test.dart';

import 'package:gebeta/services/haptics_service.dart';

void main() {
  test('tap and capture call the right haptic when on', () async {
    final calls = <String>[];
    final haptics = HapticsService(
      selectionClick: () async => calls.add('selection'),
      mediumImpact: () async => calls.add('medium'),
    );
    await haptics.tap();
    await haptics.capture();
    expect(calls, ['selection', 'medium']);
  });

  test('haptic calls are skipped when the Haptics setting is off', () async {
    final calls = <String>[];
    final haptics = HapticsService(
      selectionClick: () async => calls.add('selection'),
      mediumImpact: () async => calls.add('medium'),
    )..setEnabled(false);
    await haptics.tap();
    await haptics.capture();
    expect(calls, isEmpty);
  });
}
