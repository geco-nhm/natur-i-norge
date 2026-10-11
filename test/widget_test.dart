import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Natur i Norge'),
        ),
      ),
    );

    expect(find.text('Natur i Norge'), findsOneWidget);
  });
}
