import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/insights_models.dart';
import 'insights_style.dart';

/// A rounded chip showing a topic status with colour, icon and label.
///
/// With [count], it reads "3 Strong" (used in the status summary).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.count});

  final TopicStatus status;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(status);
    final text = count == null ? style.label : '$count ${style.label}';
    return Semantics(
      container: true,
      label: count == null
          ? 'Status: ${style.label}'
          : '$count ${count == 1 ? 'topic' : 'topics'} ${style.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: style.fill(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: style.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusIcon(status: status, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: style.text(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The status icon on a solid status-coloured dot (ink icon, so it is
/// readable on every status colour in both themes). Neutral states get an
/// outlined dot instead.
class StatusIcon extends StatelessWidget {
  const StatusIcon({super.key, required this.status, this.size = 24});

  final TopicStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(status);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: style.neutral ? null : style.accent,
        border: style.neutral
            ? Border.all(color: InsightsColors.mutedText(context))
            : null,
      ),
      child: Icon(
        style.icon,
        size: size * 0.66,
        color: style.neutral
            ? InsightsColors.mutedText(context)
            : AppColors.ink,
      ),
    );
  }
}
