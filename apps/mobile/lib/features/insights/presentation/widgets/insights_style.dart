import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/insights_models.dart';
import '../../domain/insights_summary.dart';

// Every colour decision for the Insights screens lives in this file, so the
// palette can be changed in one place.
//
// TODO(keshomigha): switch to the Figma status tokens once PR #7 lands in
// develop: strong -> AppColors.success / successSoft / successDark,
// developing -> warning / warningSoft / warningDark, weak -> errorSoft.
// Until then only the tokens that exist in develop are used (no hex values).

/// Colour, icon and label for one [TopicStatus]. Every state is shown with
/// all three, never colour alone.
@immutable
class StatusStyle {
  const StatusStyle({
    required this.label,
    required this.icon,
    required this.accent,
    this.fillAlpha = 0.18,
    this.neutral = false,
  });

  final String label;
  final IconData icon;

  /// The status colour (icon dot, border, tint).
  final Color accent;

  /// How strong the background tint is.
  final double fillAlpha;

  /// Not-enough-data / not-attempted / unknown: outlined, muted.
  final bool neutral;

  static StatusStyle of(TopicStatus status) => switch (status) {
    TopicStatus.strong => const StatusStyle(
      label: 'Strong',
      icon: Icons.eco_rounded,
      accent: AppColors.mint,
      fillAlpha: 0.28,
    ),
    TopicStatus.good => const StatusStyle(
      label: 'Good',
      icon: Icons.check_rounded,
      accent: AppColors.secondary,
    ),
    TopicStatus.developing => const StatusStyle(
      label: 'Developing',
      icon: Icons.trending_up_rounded,
      accent: AppColors.amber,
      fillAlpha: 0.28,
    ),
    TopicStatus.weak => const StatusStyle(
      label: 'Weak',
      icon: Icons.warning_amber_rounded,
      accent: AppColors.error,
      fillAlpha: 0.14,
    ),
    TopicStatus.veryWeak => const StatusStyle(
      label: 'Very weak',
      icon: Icons.warning_rounded,
      accent: AppColors.error,
      fillAlpha: 0.26,
    ),
    TopicStatus.insufficientData => const StatusStyle(
      label: 'Not enough data',
      icon: Icons.info_outline_rounded,
      accent: AppColors.muted,
      fillAlpha: 0.10,
      neutral: true,
    ),
    TopicStatus.notAttempted => const StatusStyle(
      label: 'Not attempted',
      icon: Icons.remove_rounded,
      accent: AppColors.muted,
      fillAlpha: 0,
      neutral: true,
    ),
    TopicStatus.unknown => const StatusStyle(
      label: 'Unknown',
      icon: Icons.help_outline_rounded,
      accent: AppColors.muted,
      fillAlpha: 0,
      neutral: true,
    ),
  };

  /// Background tint for chips and cells.
  Color fill(BuildContext context) => accent.withValues(
    alpha: InsightsColors.isDark(context) ? fillAlpha + 0.08 : fillAlpha,
  );

  /// Border for chips and cells.
  Color border(BuildContext context) =>
      neutral ? InsightsColors.line(context) : accent.withValues(alpha: 0.6);
}

/// Colours of the Insights overview design (mastery ring, study time,
/// accuracy trend, unit mastery).
///
// TODO(keshomigha): move the hex values into AppColors once PR #7 adds the
// success / warning tokens.
abstract final class InsightsPalette {
  static const Color mastered = Color(0xFF10B981); // green
  static const Color strong = AppColors.secondary; // teal
  static const Color improving = Color(0xFFF59E0B); // amber
  static const Color weak = Color(0xFFF87171); // coral
  static const Color positive = Color(0xFF059669); // "+22%" text
  static const Color negative = Color(0xFFDC2626); // "-5%" text
  static const Color barSoftLight = Color(0xFFC7D2FE); // indigo-200

  /// Legend dot / bar colour for a mastery band.
  static Color forBand(MasteryBandKey key) => switch (key) {
    MasteryBandKey.mastered => mastered,
    MasteryBandKey.strong => strong,
    MasteryBandKey.improving => improving,
    MasteryBandKey.weak => weak,
    MasteryBandKey.unknown => AppColors.muted,
  };

  /// Unit mastery bar colour, from the backend's status.
  static Color forStatus(TopicStatus status) => switch (status) {
    TopicStatus.strong => mastered,
    TopicStatus.good => strong,
    TopicStatus.developing => improving,
    TopicStatus.weak || TopicStatus.veryWeak => weak,
    _ => AppColors.muted,
  };

  /// Study time bars that are not highlighted.
  static Color barSoft(BuildContext context) => InsightsColors.isDark(context)
      ? AppColors.primary.withValues(alpha: 0.4)
      : barSoftLight;

  /// Ring track, unit bar track.
  static Color track(BuildContext context) => InsightsColors.isDark(context)
      ? AppColors.darkBorder
      : const Color(0xFFE5E7F0);
}

/// Shared colours and text helpers for the Insights screens.
abstract final class InsightsColors {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Ring / bar / heatmap colour by percent:
  /// below 35 error, 35 to under 55 amber, 55 to under 75 teal,
  /// 75 and above success. Null (not attempted) is muted.
  static Color forPercent(double? percent) {
    if (percent == null) return AppColors.muted;
    if (percent < 35) return AppColors.error;
    if (percent < 55) return AppColors.amber;
    if (percent < 75) return AppColors.secondary;
    // TODO(keshomigha): AppColors.success once PR #7 is in develop.
    return AppColors.mint;
  }

  /// Main text colour (ink in light, white in dark).
  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Secondary text. `AppColors.muted` is too dark on the dark surface, so
  /// dark mode uses the text colour at reduced opacity (still above 4.5:1).
  static Color mutedText(BuildContext context) => isDark(context)
      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72)
      : AppColors.muted;

  /// Card borders and ring tracks.
  static Color line(BuildContext context) =>
      isDark(context) ? AppColors.darkBorder : AppColors.border;

  /// Accent used on the info note (indigo in light, light indigo in dark).
  static Color infoAccent(BuildContext context) =>
      isDark(context) ? AppColors.taglineOnDark : AppColors.primary;
}

/// Text helpers. They only format what the backend sent; nothing is
/// recomputed in the app.
abstract final class InsightsText {
  /// 61.76 -> "62%". Null -> "Not attempted" (never "0%").
  static String percent(double? percent) =>
      percent == null ? 'Not attempted' : '${percent.round()}%';

  /// For screen readers: "62 percent".
  static String percentSpoken(double? percent) =>
      percent == null ? 'not attempted' : '${percent.round()} percent';

  /// 75.0 -> "75", 62.5 -> "62.5".
  static String number(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  /// "75% and above" / "65–75%".
  static String bandRange(GradeBand band) => band.maxPercent == null
      ? '${number(band.minPercent)}% and above'
      : '${number(band.minPercent)}–${number(band.maxPercent!)}%';

  /// "Needs 3 more questions" / "Needs 1 more question".
  static String needsMore(int count) =>
      'Needs $count more question${count == 1 ? '' : 's'}';

  /// Minutes as hours with one decimal: 90 -> "1.5h", 822 -> "13.7h".
  static String hours(int minutes) {
    final value = minutes / 60;
    return '${value >= 100 ? value.round() : number(_oneDecimal(value))}h';
  }

  static double _oneDecimal(double value) => (value * 10).round() / 10;

  /// Accuracy change: 22.0 -> "+22%", -4.5 -> "-4.5%", 0 -> "±0%".
  static String change(double points) {
    final rounded = _oneDecimal(points);
    if (rounded == 0) return '±0%';
    return '${rounded > 0 ? '+' : '-'}${number(rounded.abs())}%';
  }

  /// "6.2 · Genetics", "Genetics" or "".
  static String topicSubtitle(TopicResult topic) => [
    if (topic.topicNumber != null && topic.topicNumber!.isNotEmpty)
      topic.topicNumber!,
    if (topic.unit != null && topic.unit!.isNotEmpty) topic.unit!,
  ].join(' · ');
}
