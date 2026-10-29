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

  // Supporting UI colours used by the Figma screens (Tailwind-style scale).
  static const Color primarySoft = Color(0xFFEEF2FF); // selected card / chip bg
  static const Color primaryLight = Color(0xFFC7D2FE); // filled OTP box border
  static const Color secondaryDark = Color(0xFF0F766E); // teal text on light bg
  static const Color secondarySoft = Color(0xFFF0FDFA); // teal icon bubble
  static const Color success = Color(0xFF10B981); // strong / done
  static const Color successSoft = Color(0xFFD1FAE5); // "Your strongest" card
  static const Color successDark = Color(0xFF047857); // "+4% wk", success text
  static const Color warningSoft = Color(0xFFFFFBEB); // "Needs work" card
  static const Color warningBorder = Color(0xFFFDE68A);
  static const Color warningDark = Color(0xFFB45309); // amber text
  static const Color streakSoft = Color(0xFFFEF3C7); // streak chip bg
  static const Color streakDark = Color(0xFF92400E); // streak chip text
  static const Color surfaceMuted = Color(0xFFF1F5F9); // disabled bg
  static const Color mutedLight = Color(
    0xFF94A3B8,
  ); // placeholder / disabled text
  static const Color errorSoft = Color(0xFFFEF2F2);

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
