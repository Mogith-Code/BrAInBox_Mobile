import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'mastery_ring.dart';

/// A tappable card for a syllabus topic, with an optional mastery ring.
class TopicCard extends StatelessWidget {
  const TopicCard({
    super.key,
    required this.title,
    this.subtitle,
    this.mastery,
    this.onTap,
  });

  final String title;

  /// e.g. the unit name or "12 concepts".
  final String? subtitle;

  /// 0.0 - 1.0, or null to hide the ring.
  final double? mastery;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              if (mastery != null) ...[
                MasteryRing(value: mastery!, size: 44, strokeWidth: 4),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
