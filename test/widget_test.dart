// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catering_client/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CateringApp());

    // Wait for splash screen animation
    await tester.pumpAndSettle();

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Splash screen shows app name', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const CateringApp());

    // Verify splash screen elements appear
    expect(find.text('Catering App'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}