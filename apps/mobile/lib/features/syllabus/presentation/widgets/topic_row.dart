import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/syllabus_models.dart';
import 'learn_widgets.dart';

/// One topic on the Unit detail screen: numbered circle (green ✓ when
/// mastered, orange dot when weak), title, status pill, mini progress bar
/// while in progress, chevron.
class TopicRow extends StatelessWidget {
  const TopicRow({super.key, required this.topic, required this.onTap});

  final TopicProgress topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final inProgress = topic.status == TopicStatus.inProgress;

    return Semantics(
      button: true,
      label:
          'Topic ${topic.order}, ${topic.title}, ${topic.status.label}'
          '${inProgress ? ', ${Formatters.percent(topic.progress)} done' : ''}'
          '${topic.isWeak ? ', flagged as weak' : ''}',
      child: ExcludeSemantics(
        child: LearnCard(
          onTap: onTap,
          child: Row(
            children: [
              TopicNumber(
                order: topic.order,
                mastered: topic.status == TopicStatus.mastered,
                weak: topic.isWeak,
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
                        color: context.learnInk,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Row(
                      children: [
                        Flexible(child: StatusPill.topic(topic.status)),
                        if (inProgress) ...[
                          const SizedBox(width: AppSpacing.sm),
                          ProgressBar(value: topic.progress),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right, color: context.learnMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// 32px circle with the topic number, or a green ✓ when mastered.
/// A 10px orange dot sits on its top-right corner when the topic is weak.
class TopicNumber extends StatelessWidget {
  const TopicNumber({
    super.key,
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
              top: -2,
              right: -2,
              child: Container(
                key: const ValueKey('weak-dot'),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.learnSurface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
