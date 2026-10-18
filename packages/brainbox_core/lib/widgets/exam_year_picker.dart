import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// "‹  2026  2027  2028  ›" - the selected year is big and indigo, its
/// neighbours are small and grey. Arrows (or tapping a neighbour) move it.
class ExamYearPicker extends StatelessWidget {
  const ExamYearPicker({
    super.key,
    required this.years,
    required this.value,
    required this.onChanged,
  });

  /// Allowed years, in order (e.g. from `GET /profile/options`).
  final List<int> years;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final index = years.indexOf(value);
    final prev = index > 0 ? years[index - 1] : null;
    final next = index >= 0 && index < years.length - 1
        ? years[index + 1]
        : null;
    final textTheme = Theme.of(context).textTheme;

    Widget neighbour(int? year) => SizedBox(
      width: 56,
      child: year == null
          ? null
          : InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              onTap: () => onChanged(year),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  '$year',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Earlier year',
            onPressed: prev == null ? null : () => onChanged(prev),
            icon: const Icon(Icons.chevron_left),
            color: AppColors.ink,
          ),
          const Spacer(),
          neighbour(prev),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            label: 'A/L exam year $value',
            liveRegion: true,
            child: ExcludeSemantics(
              child: Text(
                '$value',
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          neighbour(next),
          const Spacer(),
          IconButton(
            tooltip: 'Later year',
            onPressed: next == null ? null : () => onChanged(next),
            icon: const Icon(Icons.chevron_right),
            color: AppColors.ink,
          ),
        ],
      ),
    );
  }
}
