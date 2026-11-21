import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, String message) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ErrorBanner(message: message, onRetry: () {}),
      ),
    ),
  );

  testWidgets('a network error shows the offline state', (tester) async {
    await pump(
      tester,
      ErrorMessages.of(
        const ApiException(
          code: 'network',
          message: ApiException.networkMessage,
        ),
      ),
    );
    expect(find.text("You're offline"), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('other errors stay red errors', (tester) async {
    await pump(tester, 'Something broke');
    expect(find.text('Something broke'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
