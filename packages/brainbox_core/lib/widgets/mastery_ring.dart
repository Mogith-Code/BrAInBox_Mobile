import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A circular progress ring showing how well a topic is mastered.
///
/// [value] goes from 0.0 to 1.0. The color changes with the value:
/// red below 40%, amber below 70%, teal above.
class MasteryRing extends StatelessWidget {
  const MasteryRing({
    super.key,
    required this.value,
    this.size = 56,
    this.strokeWidth = 6,
    this.label,
  });

  final double value;
  final double size;
  final double strokeWidth;

  /// Text in the middle. Defaults to the percentage, e.g. "72%".
  final String? label;

  static Color colorFor(double value) {
    if (value < 0.4) return AppColors.error;
    if (value < 0.7) return AppColors.amber;
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final text = label ?? '${(clamped * 100).round()}%';
    return Semantics(
      label: 'Mastery $text',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: clamped,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.border,
              color: colorFor(clamped),
            ),
            Center(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
