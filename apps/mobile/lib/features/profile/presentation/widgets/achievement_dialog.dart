import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/profile_overview_models.dart';

/// "Achievement unlocked" (Figma F8). Share copies a short message;
/// Keep going closes it.
Future<void> showAchievementUnlocked(
  BuildContext context,
  Achievement achievement,
) => showDialog<void>(
  context: context,
  builder: (_) => _AchievementDialog(achievement: achievement),
);

class _AchievementDialog extends StatelessWidget {
  const _AchievementDialog({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.amber, AppColors.primaryLight],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.5),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Text(a.emoji, style: const TextStyle(fontSize: 44)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'ACHIEVEMENT UNLOCKED',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.warningDark,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              a.title,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (a.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                a.description,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
            if (a.badgeLabel != null || a.xp != null) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  if (a.badgeLabel != null)
                    AppChip(
                      label: a.badgeLabel!,
                      icon: Icons.check,
                      tone: AppChipTone.success,
                    ),
                  if (a.xp != null)
                    AppChip(label: '+${a.xp} XP', tone: AppChipTone.streak),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(
                        ClipboardData(
                          text:
                              'I just unlocked "${a.title}" on BrAInBox! '
                              '${a.description}',
                        ),
                      );
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Copied - paste it anywhere to share.'),
                        ),
                      );
                    },
                    child: const Text('Share'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Keep going',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
