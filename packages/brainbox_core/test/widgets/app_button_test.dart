import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps a widget in the minimum needed to render it.
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AppButton', () {
    testWidgets('shows the label and calls onPressed when tapped', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(AppButton(label: 'Sign in', onPressed: () => taps++)),
      );

      expect(find.text('Sign in'), findsOneWidget);
      await tester.tap(find.text('Sign in'));
      expect(taps, 1);
    });

    testWidgets('shows a spinner and ignores taps while loading', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          AppButton(label: 'Sign in', isLoading: true, onPressed: () => taps++),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Sign in'));
      expect(taps, 0);
    });

    testWidgets('renders every variant', (tester) async {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(
          _wrap(
            AppButton(label: variant.name, variant: variant, onPressed: () {}),
          ),
        );
        expect(find.text(variant.name), findsOneWidget);
      }
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppButton(label: 'Disabled', onPressed: null)),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });
}
