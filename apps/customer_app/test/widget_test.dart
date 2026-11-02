// Placeholder smoke test — the default Flutter counter-app template test
// this replaced referenced a nonexistent `MyApp` class and never matched
// this project. Pumping the real `VarnixoApp` here would need
// flutter_secure_storage's platform channel mocked (it has no test-mode
// fallback), so this stays a minimal harness sanity check until real
// widget tests are added.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test harness renders a basic widget',
      (WidgetTester tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: Text('ok'))));
    expect(find.text('ok'), findsOneWidget);
  });
}
