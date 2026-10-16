import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Puts the logo on a light or dark (brand gradient) background.
Widget _onBackground(Widget logo, {required bool dark}) {
  return MaterialApp(
    home: Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? null : AppColors.background,
          gradient: dark ? AppColors.brandGradient : null,
        ),
        child: Center(child: logo),
      ),
    ),
  );
}

void main() {
  for (final dark in [false, true]) {
    for (final variant in AppLogoVariant.values) {
      for (final tagline in [false, true]) {
        final name =
            '${variant.name} on ${dark ? 'dark' : 'light'}'
            '${tagline ? ' with tagline' : ''}';

        testWidgets('AppLogo renders $name', (tester) async {
          await tester.pumpWidget(
            _onBackground(
              AppLogo(
                variant: variant,
                size: 64,
                onDark: dark,
                showTagline: tagline,
              ),
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.bySemanticsLabel('BrAInBox logo'), findsOneWidget);

          final hasWordmark =
              variant == AppLogoVariant.horizontal ||
              variant == AppLogoVariant.stacked;
          expect(
            find.text('BrAInBox', findRichText: true),
            hasWordmark ? findsOneWidget : findsNothing,
          );
          expect(
            find.text(BrandAssets.tagline),
            hasWordmark && tagline ? findsOneWidget : findsNothing,
          );
        });
      }
    }
  }

  testWidgets('"AI" is highlighted in the wordmark', (tester) async {
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        _onBackground(
          AppLogo(variant: AppLogoVariant.horizontal, onDark: dark),
          dark: dark,
        ),
      );
      final richText = tester.widget<RichText>(
        find.text('BrAInBox', findRichText: true),
      );
      final ai = (richText.text as TextSpan).children![1] as TextSpan;
      expect(ai.text, 'AI');
      expect(
        ai.style!.color,
        dark ? AppColors.aiHighlightOnDark : AppColors.primary,
      );
    }
  });
}
