import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fonts: Poppins for headings, Inter for body text.
///
/// In widgets, use the theme instead of calling this directly:
/// `Theme.of(context).textTheme.titleLarge`.
///
// TODO(samni): bundle the font files in assets/ before release, so the app
// does not need to download them on first launch (see google_fonts docs).
abstract final class AppTypography {
  static TextTheme textTheme({required Color color}) {
    // Material 3 sizes, without colors.
    final base = Typography.material2021().black;
    final body = GoogleFonts.interTextTheme(base);
    final heading = GoogleFonts.poppinsTextTheme(base);

    return body
        .copyWith(
          displayLarge: heading.displayLarge,
          displayMedium: heading.displayMedium,
          displaySmall: heading.displaySmall,
          headlineLarge: _semiBold(heading.headlineLarge),
          headlineMedium: _semiBold(heading.headlineMedium),
          headlineSmall: _semiBold(heading.headlineSmall),
          titleLarge: _semiBold(heading.titleLarge),
          titleMedium: _semiBold(heading.titleMedium),
          titleSmall: _semiBold(heading.titleSmall),
        )
        .apply(bodyColor: color, displayColor: color);
  }

  static TextStyle? _semiBold(TextStyle? style) =>
      style?.copyWith(fontWeight: FontWeight.w600);
}
