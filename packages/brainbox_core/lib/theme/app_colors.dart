import 'package:flutter/material.dart';

/// BrAInBox brand colors. Use these instead of hard-coded hex values.
///
/// ```dart
/// Container(color: AppColors.primary)
/// ```
abstract final class AppColors {
  static const Color primary = Color(0xFF4F46E5); // indigo
  static const Color secondary = Color(0xFF0EA5A4); // teal
  static const Color mint = Color(0xFF6EE7B7); // success / mastered
  static const Color amber = Color(0xFFFCD34D); // AI badge / warning

  /// Darker amber for warning icons, lines and bars on white. [amber] is too
  /// light there (contrast below 3:1).
  static const Color warning = Color(0xFFD97706);
  static const Color ink = Color(0xFF1E1B4B); // main text
  static const Color muted = Color(0xFF64748B); // secondary text
  static const Color border = Color(0xFFE2E8F0);
  static const Color background = Color(0xFFF8FAFC);
  static const Color error = Color(0xFFEF4444);
  static const Color white = Color(0xFFFFFFFF);

  // Logo colours on dark / gradient backgrounds (from the brand pack).
  static const Color aiHighlightOnDark = Color(
    0xFFA5F3FC,
  ); // "AI" in the wordmark
  static const Color taglineOnDark = Color(0xFFE0E7FF);

  // Dark mode surfaces. Not in the brand sheet yet.
  // TODO(samni): replace with the Figma dark palette when it exists.
  static const Color darkBackground = Color(0xFF0F0E24);
  static const Color darkSurface = Color(0xFF1B1A3A);
  static const Color darkBorder = Color(0xFF2E2C5A);

  /// Brand gradient: secondary -> primary at 135 degrees
  /// (top-left to bottom-right).
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, primary],
  );
}
