import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Text colours that stay readable in light AND dark mode.
///
/// `AppColors.ink`, `AppColors.muted` and `AppColors.primary` are tuned for
/// light backgrounds; on the dark background they fall below WCAG AA. Use
/// these for text and icons drawn on the page or card background:
///
/// ```dart
/// Text('Hello', style: TextStyle(color: context.appMuted))
/// ```
/// On a fixed light surface (e.g. a white chip) keep the `AppColors` value.
extension AppTextColors on BuildContext {
  bool get _isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  /// Main text: ink on light, near-white on dark.
  Color get appInk => _isDarkTheme ? AppColors.darkInk : AppColors.ink;

  /// Secondary text: slate-500 on light, slate-400 on dark.
  Color get appMuted => _isDarkTheme ? AppColors.mutedLight : AppColors.muted;

  /// Links, text buttons, selected tabs: indigo on light, indigo-200 on dark.
  Color get appPrimaryText =>
      _isDarkTheme ? AppColors.primaryLight : AppColors.primary;
}
