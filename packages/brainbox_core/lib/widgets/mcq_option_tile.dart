import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The state of one MCQ answer option.
enum McqOptionState {
  /// Default: not selected, not checked yet.
  normal,

  /// Picked by the student, answer not checked yet.
  selected,

  /// Checked: this is the right answer.
  correct,

  /// Checked: the student picked this and it is wrong.
  wrong,
}

/// One answer option in an MCQ question, e.g. "A  Mitochondria".
class McqOptionTile extends StatelessWidget {
  const McqOptionTile({
    super.key,
    required this.letter,
    required this.text,
    this.state = McqOptionState.normal,
    this.onTap,
  });

  /// "A", "B", "C"...
  final String letter;
  final String text;
  final McqOptionState state;

  /// Null after the answer is checked (tile becomes read-only).
  final VoidCallback? onTap;

  ({Color border, Color fill, IconData? icon}) get _style => switch (state) {
    McqOptionState.normal => (
      border: AppColors.border,
      fill: AppColors.white,
      icon: null,
    ),
    McqOptionState.selected => (
      border: AppColors.primary,
      fill: AppColors.primary.withValues(alpha: 0.08),
      icon: null,
    ),
    McqOptionState.correct => (
      border: AppColors.secondary,
      fill: AppColors.mint.withValues(alpha: 0.25),
      icon: Icons.check_circle,
    ),
    McqOptionState.wrong => (
      border: AppColors.error,
      fill: AppColors.error.withValues(alpha: 0.08),
      icon: Icons.cancel,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return Semantics(
      button: onTap != null,
      selected: state == McqOptionState.selected,
      child: Material(
        color: style.fill,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: style.border, width: 1.5),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: style.border,
                  foregroundColor: state == McqOptionState.normal
                      ? AppColors.ink
                      : AppColors.white,
                  child: Text(letter),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(text)),
                if (style.icon != null) Icon(style.icon, color: style.border),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
