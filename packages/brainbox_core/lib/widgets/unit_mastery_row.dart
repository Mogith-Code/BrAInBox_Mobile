import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// How a unit is going, for the colour of its bar and icon.
enum MasteryStatus { strong, ok, needsWork }

/// One row of "Mastery by unit": number, title, bar, "82%" and an icon
/// (✓ strong, ⚠ needs work).
class UnitMasteryRow extends StatelessWidget {
  const UnitMasteryRow({
    super.key,
    required this.index,
    required this.title,
    required this.mastery,
    required this.status,
    this.emphasised,
  });

  /// 1-based row number.
  final int index;
  final String title;

  /// 0.0 - 1.0
  final double mastery;
  final MasteryStatus status;

  /// Bold title (e.g. the strongest / needs-work units). Defaults to any
  /// unit that isn't "ok".
  final bool? emphasised;

  static Color colorFor(MasteryStatus status) => switch (status) {
    MasteryStatus.strong => AppColors.success,
    MasteryStatus.ok => AppColors.secondary,
    MasteryStatus.needsWork => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = mastery.clamp(0.0, 1.0);
    final percent = '${(value * 100).round()}%';
    final emphasise = emphasised ?? status != MasteryStatus.ok;
    final statusText = switch (status) {
      MasteryStatus.strong => 'strong',
      MasteryStatus.ok => '',
      MasteryStatus.needsWork => 'needs work',
    };

    return Semantics(
      label:
          'Unit $index, $title, $percent ${statusText.isEmpty ? '' : ', $statusText'}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$index',
                  style: textTheme.labelLarge?.copyWith(color: AppColors.muted),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.ink,
                              fontWeight: emphasise
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        Text(
                          percent,
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs + 1),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 7,
                        color: colorFor(status),
                        backgroundColor: AppColors.border,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 32,
                child: switch (status) {
                  MasteryStatus.strong => const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppColors.successDark,
                  ),
                  MasteryStatus.needsWork => const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Color(0xFFEA580C), // orange-600, as in Figma
                  ),
                  MasteryStatus.ok => null,
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
