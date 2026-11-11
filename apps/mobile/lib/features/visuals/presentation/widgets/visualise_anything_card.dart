import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';

/// Ideas students can tap to start a visual. They cover different units,
/// so it is clear any Biology idea works, not only the current topic.
const visualIdeas = [
  'Structure of a nephron',
  'Stages of mitosis',
  'Light and dark reactions of photosynthesis',
  'Blood flow through the human heart',
  'Krebs cycle step by step',
];

/// "Visualise anything" (Home and My visuals): a short pitch, idea chips
/// that open the generator with the idea filled in, and a button.
///
/// [onOpen] defaults to opening "My visuals"; My visuals itself passes a
/// callback that goes straight to the generator.
class VisualiseAnythingCard extends StatelessWidget {
  const VisualiseAnythingCard({super.key, this.onOpen, this.buttonLabel});

  final VoidCallback? onOpen;
  final String? buttonLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visualise anything',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Turn any Biology idea into a labelled diagram.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const AiBadge(label: 'AI'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final idea in visualIdeas.take(3))
                ActionChip(
                  label: Text(idea),
                  avatar: const Icon(Icons.lightbulb_outline, size: 16),
                  labelStyle: textTheme.labelMedium?.copyWith(
                    color: AppColors.ink,
                  ),
                  backgroundColor: AppColors.primarySoft,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onPressed: () =>
                      context.push(AppRoutes.generateVisualPath(prompt: idea)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: buttonLabel ?? 'Draw something',
            icon: Icons.auto_awesome,
            variant: AppButtonVariant.gradient,
            onPressed: onOpen ?? () => context.push(AppRoutes.myVisuals),
          ),
        ],
      ),
    );
  }
}
