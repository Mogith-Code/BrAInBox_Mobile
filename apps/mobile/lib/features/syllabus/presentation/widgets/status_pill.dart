import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/syllabus_models.dart';

/// Label and colours for each [UnitStatus] pill and ring.
extension UnitStatusStyle on UnitStatus {
  String get label => switch (this) {
    UnitStatus.mastered => 'Mastered',
    UnitStatus.strong => 'Strong',
    UnitStatus.improving => 'Improving',
    UnitStatus.weak => 'Weak',
  };

  /// Only "Improving" has an icon (↗) in Figma.
  IconData? get icon => this == UnitStatus.improving ? Icons.trending_up : null;

  Color get background => switch (this) {
    UnitStatus.mastered || UnitStatus.strong => AppColors.successSoft,
    UnitStatus.improving => AppColors.streakSoft,
    UnitStatus.weak => AppColors.errorSoft,
  };

  Color get foreground => switch (this) {
    UnitStatus.mastered || UnitStatus.strong => AppColors.successDark,
    UnitStatus.improving => AppColors.streakDark,
    UnitStatus.weak => AppColors.errorDark,
  };

  Color get ringColor => switch (this) {
    UnitStatus.mastered || UnitStatus.strong => AppColors.secondary,
    UnitStatus.improving => AppColors.warning,
    UnitStatus.weak => AppColors.error,
  };
}

/// Label and colours for each [TopicStatus] pill.
extension TopicStatusStyle on TopicStatus {
  String get label => switch (this) {
    TopicStatus.mastered => 'Mastered',
    TopicStatus.strong => 'Strong',
    TopicStatus.improving => 'Improving',
    TopicStatus.weak => 'Weak',
    TopicStatus.inProgress => 'In progress',
    TopicStatus.notStarted => 'Not started',
  };

  IconData? get icon =>
      this == TopicStatus.improving ? Icons.trending_up : null;

  Color get background => switch (this) {
    TopicStatus.mastered || TopicStatus.strong => AppColors.successSoft,
    TopicStatus.improving => AppColors.streakSoft,
    TopicStatus.weak => AppColors.errorSoft,
    TopicStatus.inProgress => AppColors.primarySoft,
    TopicStatus.notStarted => AppColors.surfaceMuted,
  };

  Color get foreground => switch (this) {
    TopicStatus.mastered || TopicStatus.strong => AppColors.successDark,
    TopicStatus.improving => AppColors.streakDark,
    TopicStatus.weak => AppColors.errorDark,
    TopicStatus.inProgress => AppColors.primaryDark,
    TopicStatus.notStarted => AppColors.muted,
  };
}

/// The small rounded status badge: "Strong", "↗ Improving", "Weak"...
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  StatusPill.unit(UnitStatus status, {Key? key})
    : this(
        key: key,
        label: status.label,
        background: status.background,
        foreground: status.foreground,
        icon: status.icon,
      );

  StatusPill.topic(TopicStatus status, {Key? key})
    : this(
        key: key,
        label: status.label,
        background: status.background,
        foreground: status.foreground,
        icon: status.icon,
      );

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
