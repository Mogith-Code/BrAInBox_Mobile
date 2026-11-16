import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/syllabus_models.dart';

/// Colour + icon + label for a status. Never colour alone.
class StatusStyle {
  const StatusStyle(this.label, this.icon, this.background, this.foreground);

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
}

extension MasteryLevelStyle on MasteryLevel {
  StatusStyle get style => switch (this) {
    MasteryLevel.weak => const StatusStyle(
      'Weak',
      Icons.warning_amber_rounded,
      AppColors.errorSoft,
      AppColors.errorDark,
    ),
    MasteryLevel.improving => const StatusStyle(
      'Improving',
      Icons.trending_up,
      AppColors.streakSoft,
      AppColors.streakDark,
    ),
    MasteryLevel.strong => const StatusStyle(
      'Strong',
      Icons.check,
      AppColors.secondarySoft,
      AppColors.secondaryDark,
    ),
    MasteryLevel.mastered => const StatusStyle(
      'Mastered',
      Icons.eco,
      AppColors.successSoft,
      AppColors.successDark,
    ),
  };

  String get label => style.label;
}

extension TopicStatusStyle on TopicStatus {
  StatusStyle get style => switch (this) {
    TopicStatus.notStarted => const StatusStyle(
      'Not started',
      Icons.radio_button_unchecked,
      AppColors.surfaceMuted,
      Color(0xFF475569), // slate-600: 4.5:1 on slate-100
    ),
    TopicStatus.inProgress => const StatusStyle(
      'In progress',
      Icons.timelapse,
      AppColors.primarySoft,
      AppColors.primaryDark,
    ),
    TopicStatus.mastered => const StatusStyle(
      'Mastered',
      Icons.check_circle_outline,
      AppColors.successSoft,
      AppColors.successDark,
    ),
  };

  String get label => style.label;
}

/// A small fully rounded chip: icon + label on a tint.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.style});

  StatusPill.topic(TopicStatus status, {Key? key})
    : this(key: key, style: status.style);

  final StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 12, color: style.foreground),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: style.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Weak / Improving / Strong / Mastered.
class MasteryChip extends StatelessWidget {
  const MasteryChip({super.key, required this.level});

  final MasteryLevel level;

  @override
  Widget build(BuildContext context) =>
      Semantics(label: 'Mastery: ${level.label}', child: ExcludeSemantics(child: StatusPill(style: level.style)));
}
