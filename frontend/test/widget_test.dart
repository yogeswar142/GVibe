import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gvibe/main.dart';

void main() {
  testWidgets('GVibe app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GVibeApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
