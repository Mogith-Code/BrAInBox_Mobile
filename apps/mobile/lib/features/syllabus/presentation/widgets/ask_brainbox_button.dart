import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';

/// The brand-gradient "Ask BrAInBox" floating button (the AskFab).
///
/// Opens the AI tutor (`/ask`), about [topicId] when given.
/// [extended] = pill with a label (Notes tab); otherwise a compact 56px
/// ✦ circle (Learn home).
class AskBrainBoxButton extends StatelessWidget {
  const AskBrainBoxButton({super.key, this.topicId, this.extended = true});

  final String? topicId;
  final bool extended;

  static const label = 'Ask BrAInBox';

  @override
  Widget build(BuildContext context) {
    final shape = extended
        ? const StadiumBorder()
        : const CircleBorder() as ShapeBorder;
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Material(
          shape: shape,
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          child: Ink(
            decoration: const BoxDecoration(gradient: AppColors.brandGradient),
            child: InkWell(
              onTap: () => context.push(AppRoutes.askPath(topicId: topicId)),
              child: SizedBox(
                height: 56,
                width: extended ? null : 56,
                child: extended
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg + 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 20,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            ExcludeSemantics(
                              child: Text(
                                label,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Icon(Icons.auto_awesome, color: AppColors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
