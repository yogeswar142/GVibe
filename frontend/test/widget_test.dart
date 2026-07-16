import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gvibe/main.dart';

void main() {
  testWidgets('GVibe app smoke test', (WidgetTester tester) async {
    // Load environment variables for testing
    await dotenv.load(fileName: '.env');

    await tester.pumpWidget(const ProviderScope(child: GVibeApp()));
    expect(find.byType(MaterialApp), findsOneWidget);

    // Let the splash animation finish (2.5s) and trigger navigation
    await tester.pump(const Duration(seconds: 3));
    // Process route changes
    await tester.pump();
  });
}
