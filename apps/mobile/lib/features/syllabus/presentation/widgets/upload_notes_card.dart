import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import 'learn_widgets.dart';

/// The dashed "My uploaded notes" card on the Learn tab: opens the
/// Uploads screen (upload tuition notes, get an AI summary).
class UploadNotesCard extends StatelessWidget {
  const UploadNotesCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(LearnStyle.cardRadius);

    return Semantics(
      button: true,
      label: 'My uploaded notes. Upload tuition notes and get an AI summary',
      child: ExcludeSemantics(
        child: DashedBorder(
          child: Material(
            color: context.isDark
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.primarySoft,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md + 2),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: const Icon(
                        Icons.upload_file_outlined,
                        size: 22,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My uploaded notes',
                            style: textTheme.titleSmall?.copyWith(
                              color: context.learnInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Upload tuition notes · AI summary',
                            style: textTheme.bodySmall?.copyWith(
                              color: context.learnMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
