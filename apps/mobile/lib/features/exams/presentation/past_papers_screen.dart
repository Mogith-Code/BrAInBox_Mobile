import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/exams_controller.dart';
import '../domain/exams_models.dart';

/// Past papers and AI Model Papers hub screen.
///
/// Route: `/exams`
class PastPapersScreen extends ConsumerWidget {
  const PastPapersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(examsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Papers & Exams'),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: ErrorBanner(
            message: '$err',
            onRetry: () => ref.invalidate(examsControllerProvider),
          ),
        ),
        data: (summary) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Prominent Hero Card for AI Model Paper Generator
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              color: AppColors.primarySoft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Model Paper Generator',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                'Customized by Biology syllabus units',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Practise with model questions generated and verified against approved A/L Biology resource books. Choose units, set your question count, and receive instant AI marking with step-by-step explanations.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.ink,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Create Model Paper',
                      onPressed: () => context.push(AppRoutes.generatePaper),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Curriculum Units (Units 1 - 10)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Tap any unit to quickly generate a targeted practice paper:',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in kBiologyUnits.entries)
                  ActionChip(
                    backgroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.border),
                    label: Text('Unit ${entry.key}: ${entry.value}'),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                    onPressed: () {
                      context.push(
                        AppRoutes.generatePaper,
                        extra: [entry.key],
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'A/L Biology Past Papers',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              summary.message,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.surfaceMuted,
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: AppColors.muted),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Past paper archives (2018 - 2024) are being prepared. Use the AI Model Paper Generator above for exam practice.',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
