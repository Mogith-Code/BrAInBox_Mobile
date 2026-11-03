import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/syllabus_models.dart';
import 'status_pill.dart';

/// One topic on the Unit detail screen (Figma B3): number (or ✓), orange
/// dot when weak, title, status pill, progress bar while in progress.
class TopicRow extends StatelessWidget {
  const TopicRow({super.key, required this.topic, required this.onTap});

  final TopicProgress topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final weak = topic.status == TopicStatus.weak;
    final inProgress = topic.status == TopicStatus.inProgress;

    return Semantics(
      button: true,
      label:
          'Topic ${topic.order}, ${topic.title}, ${topic.status.label}'
          '${inProgress ? ', ${Formatters.percent(topic.progress)} done' : ''}'
          '${weak ? ', flagged as weak' : ''}',
      child: ExcludeSemantics(
        child: Material(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md + 2),
              child: Row(
                children: [
                  _TopicNumber(
                    order: topic.order,
                    mastered: topic.status == TopicStatus.mastered,
                    weak: weak,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        Row(
                          children: [
                            StatusPill.topic(topic.status),
                            if (inProgress) ...[
                              const SizedBox(width: AppSpacing.sm),
                              _ProgressBar(value: topic.progress),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 32px circle with the topic number, or a green ✓ when mastered.
/// A 9px orange dot sits on its top-left corner when the topic is weak.
class _TopicNumber extends StatelessWidget {
  const _TopicNumber({
    required this.order,
    required this.mastered,
    required this.weak,
  });

  final int order;
  final bool mastered;
  final bool weak;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mastered ? AppColors.success : AppColors.primarySoft,
              ),
              child: Center(
                child: mastered
                    ? const Icon(Icons.check, size: 18, color: AppColors.white)
                    : Text(
                        '$order',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
          if (weak)
            Positioned(
              top: -1,
              left: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The small 70x5 teal bar next to "In progress".
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 5,
          backgroundColor: AppColors.border,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}
