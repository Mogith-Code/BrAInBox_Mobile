import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/insights_models.dart';
import '../../domain/insights_summary.dart';

// Every colour decision for the Insights screens lives in this file, so the
// palette can be changed in one place. Only `AppColors` tokens are used.
//
// The colour code, from strongest to weakest:
//   strong / mastered   success    (soft: successSoft,   text: successDark)
//   good / strong       secondary  (soft: secondarySoft, text: secondaryDark)
//   developing          warning    (soft: warningSoft,   text: warningDark)
//   weak / very weak    error      (soft: errorSoft,     text: error)
//   no data             mutedLight (soft: surfaceMuted,  text: muted)

/// Colour, icon and label for one [TopicStatus]. Every state is shown with
/// all three, never colour alone.
@immutable
class StatusStyle {
  const StatusStyle({
    required this.label,
    required this.icon,
    required this.accent,
    required this.soft,
    required this.onSoft,
    this.darkFillAlpha = 0.26,
    this.neutral = false,
  });

  final String label;
  final IconData icon;

  /// The status colour (icon dot, bars, rings, borders).
  final Color accent;

  /// Light background behind the status (chips, tiles) in the light theme.
  final Color soft;

  /// Text / icon colour on [soft] (readable, 4.5:1 or more).
  final Color onSoft;

  /// Strength of the [accent] tint used as background in the dark theme.
  final double darkFillAlpha;

  /// Not-enough-data / not-attempted / unknown: outlined, muted.
  final bool neutral;

  static StatusStyle of(TopicStatus status) => switch (status) {
    TopicStatus.strong => const StatusStyle(
      label: 'Strong',
      icon: Icons.eco_rounded,
      accent: AppColors.success,
      soft: AppColors.successSoft,
      onSoft: AppColors.successDark,
    ),
    TopicStatus.good => const StatusStyle(
      label: 'Good',
      icon: Icons.check_rounded,
      accent: AppColors.secondary,
      soft: AppColors.secondarySoft,
      onSoft: AppColors.secondaryDark,
    ),
    TopicStatus.developing => const StatusStyle(
      label: 'Developing',
      icon: Icons.trending_up_rounded,
      accent: AppColors.warning,
      soft: AppColors.warningSoft,
      onSoft: AppColors.warningDark,
    ),
    TopicStatus.weak => const StatusStyle(
      label: 'Weak',
      icon: Icons.warning_amber_rounded,
      accent: AppColors.error,
      soft: AppColors.errorSoft,
      onSoft: AppColors.error,
      darkFillAlpha: 0.18,
    ),
    TopicStatus.veryWeak => const StatusStyle(
      label: 'Very weak',
      icon: Icons.warning_rounded,
      accent: AppColors.error,
      soft: AppColors.errorSoft,
      onSoft: AppColors.error,
      darkFillAlpha: 0.32,
    ),
    TopicStatus.insufficientData => const StatusStyle(
      label: 'Not enough data',
      icon: Icons.info_outline_rounded,
      accent: AppColors.mutedLight,
      soft: AppColors.surfaceMuted,
      onSoft: AppColors.muted,
      darkFillAlpha: 0.12,
      neutral: true,
    ),
    TopicStatus.notAttempted => const StatusStyle(
      label: 'Not attempted',
      icon: Icons.remove_rounded,
      accent: AppColors.mutedLight,
      soft: AppColors.white,
      onSoft: AppColors.muted,
      darkFillAlpha: 0,
      neutral: true,
    ),
    TopicStatus.unknown => const StatusStyle(
      label: 'Unknown',
      icon: Icons.help_outline_rounded,
      accent: AppColors.mutedLight,
      soft: AppColors.white,
      onSoft: AppColors.muted,
      darkFillAlpha: 0,
      neutral: true,
    ),
  };

  /// Background for chips, tiles and cells: the soft token in light, a tint
  /// of [accent] in dark.
  Color fill(BuildContext context) => InsightsColors.isDark(context)
      ? accent.withValues(alpha: darkFillAlpha)
      : soft;

  /// Border for chips and cells.
  Color border(BuildContext context) =>
      neutral ? InsightsColors.line(context) : accent.withValues(alpha: 0.6);

  /// Text on [fill]: [onSoft] in light, the normal text colour in dark.
  Color text(BuildContext context) =>
      InsightsColors.isDark(context) ? InsightsColors.text(context) : onSoft;
}

/// Colours of the overview cards (mastery ring, study time, accuracy trend,
/// unit mastery). Same colour code as [StatusStyle].
abstract final class InsightsPalette {
  /// Legend dot / bar colour for a mastery band.
  static Color forBand(MasteryBandKey key) => switch (key) {
    MasteryBandKey.mastered => AppColors.success,
    MasteryBandKey.strong => AppColors.secondary,
    MasteryBandKey.improving => AppColors.warning,
    MasteryBandKey.weak => AppColors.error,
    MasteryBandKey.unknown => AppColors.mutedLight,
  };

  /// Unit mastery bar colour, from the backend's status.
  static Color forStatus(TopicStatus status) => StatusStyle.of(status).accent;

  /// Accuracy change text: up is successDark, down is error.
  static Color forChange(BuildContext context, double change) {
    if (change > 0) {
      return InsightsColors.isDark(context)
          ? AppColors.success
          : AppColors.successDark;
    }
    if (change < 0) return AppColors.error;
    return InsightsColors.mutedText(context);
  }

  /// Study time bars that are not highlighted.
  static Color barSoft(BuildContext context) => InsightsColors.isDark(context)
      ? AppColors.primary.withValues(alpha: 0.4)
      : AppColors.primaryLight;

  /// Ring track, unit bar track.
  static Color track(BuildContext context) => InsightsColors.line(context);
}

/// Shared colours and text helpers for the Insights screens.
abstract final class InsightsColors {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Ring / bar / heatmap colour by percent, same code as [StatusStyle]:
  /// below 35 error, 35 to under 55 warning, 55 to under 75 teal,
  /// 75 and above success. Null (not attempted) is muted.
  static Color forPercent(double? percent) {
    if (percent == null) return AppColors.mutedLight;
    if (percent < 35) return AppColors.error;
    if (percent < 55) return AppColors.warning;
    if (percent < 75) return AppColors.secondary;
    return AppColors.success;
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
