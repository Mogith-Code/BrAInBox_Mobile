import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import 'insights_style.dart';

/// The shared [MasteryRing], coloured by the Insights colour code
/// (see [InsightsColors.forPercent]), with "—" for not attempted and a faded
/// look for results that are not reliable yet.
class InsightsRing extends StatelessWidget {
  const InsightsRing({
    super.key,
    required this.percent,
    this.size = 56,
    this.strokeWidth = 6,
    this.faded = false,
    this.labelStyle,
  });

  /// 0 - 100, or null for "not attempted" (empty ring, "—").
  final double? percent;
  final double size;
  final double strokeWidth;

  /// Not reliable yet (fewer answers than the backend's minimum).
  final bool faded;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final textStyle =
        labelStyle ??
        Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
    return Semantics(
      container: true,
      label: InsightsText.percentSpoken(percent),
      excludeSemantics: true,
      child: Opacity(
        opacity: faded ? 0.45 : 1,
        child: MasteryRing(
          value: percent == null ? 0 : percent! / 100,
          size: size,
          strokeWidth: strokeWidth,
          label: percent == null ? '—' : '${percent!.round()}%',
          color: InsightsColors.forPercent(percent),
          labelStyle: textStyle?.copyWith(color: InsightsColors.text(context)),
        ),
      ),
    );
  }
}
