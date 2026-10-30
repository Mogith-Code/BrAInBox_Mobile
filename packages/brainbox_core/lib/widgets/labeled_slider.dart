import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Brand slider: teal -> indigo filled track, white thumb with an indigo
/// ring, and labels under both ends ("Not at all" ... "Very", "1h" ... "6h").
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    required this.minLabel,
    required this.maxLabel,
    this.divisions,
    this.semanticFormatter,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final String minLabel;
  final String maxLabel;
  final int? divisions;

  /// How screen readers read the value, e.g. (v) => '2 hours'.
  final String Function(double value)? semanticFormatter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 7,
            trackShape: const GradientSliderTrackShape(),
            inactiveTrackColor: AppColors.border,
            thumbShape: const _RingThumbShape(),
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            // Figma's track runs (almost) edge to edge.
            padding: const EdgeInsets.symmetric(horizontal: 17),
            tickMarkShape: SliderTickMarkShape.noTickMark,
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            semanticFormatterCallback: semanticFormatter,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: [
              Text(
                minLabel,
                style: textTheme.labelMedium?.copyWith(color: AppColors.muted),
              ),
              const Spacer(),
              Text(
                maxLabel,
                style: textTheme.labelMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rounded track whose filled part is the brand gradient.
class GradientSliderTrackShape extends RoundedRectSliderTrackShape {
  const GradientSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final radius = Radius.circular(rect.height / 2);
    final canvas = context.canvas;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = sliderTheme.inactiveTrackColor ?? AppColors.border,
    );

    final active = Rect.fromLTRB(
      rect.left,
      rect.top,
      thumbCenter.dx.clamp(rect.left, rect.right),
      rect.bottom,
    );
    if (active.width > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(active, radius),
        Paint()
          ..shader = const LinearGradient(
            colors: [AppColors.secondary, AppColors.primary],
          ).createShader(active),
      );
    }
  }
}

/// White thumb with a thick indigo ring.
class _RingThumbShape extends SliderComponentShape {
  const _RingThumbShape();

  static const double _radius = 17;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(
      center.translate(0, 1.5),
      _radius,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, _radius, Paint()..color = AppColors.white);
    canvas.drawCircle(
      center,
      _radius - 1.75,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
  }
}
