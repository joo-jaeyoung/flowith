import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flowith/main.dart';

void main() {
  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      const ProviderScope(
        child: FlowithApp(),
      ),
    );

    // Verify that the app shows a loading indicator initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}