import 'package:flutter/widgets.dart';

/// Spacing and corner-radius tokens. Use these instead of magic numbers.
///
/// ```dart
/// const SizedBox(height: AppSpacing.lg)
/// BorderRadius.circular(AppSpacing.radiusMd)
/// ```
abstract final class AppSpacing {
  // Spacing scale
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // Corner radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  /// Default padding around a screen's content.
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);

  /// Default padding inside cards.
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}
