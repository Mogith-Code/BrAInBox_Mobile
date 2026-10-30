import 'package:flutter/material.dart';

import 'insights_style.dart';

/// A progress ring coloured by the Insights percent rule
/// (see [InsightsColors.forPercent]).
///
// TODO(keshomigha): replace with `MasteryRing(color: ...)` once PR #7 adds
// the colour override to brainbox_core. Today's MasteryRing uses different
// thresholds (40 / 70 %) and can't be recoloured.
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
    final value = percent == null ? 0.0 : (percent! / 100).clamp(0.0, 1.0);
    final label = percent == null ? '—' : '${percent!.round()}%';
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
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                backgroundColor: InsightsColors.line(context),
                color: InsightsColors.forPercent(percent),
              ),
              Center(
                child: Text(
                  label,
                  style: textStyle?.copyWith(
                    color: InsightsColors.text(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
