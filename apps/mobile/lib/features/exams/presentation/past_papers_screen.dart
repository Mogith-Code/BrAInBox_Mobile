import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/exams_controller.dart';
import '../domain/paper_models.dart';

/// Approved past papers with year / type filters, plus the model paper
/// generator entry.
///
/// Route: `/exams`
class PastPapersScreen extends ConsumerStatefulWidget {
  const PastPapersScreen({super.key});

  @override
  ConsumerState<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends ConsumerState<PastPapersScreen> {
  int? _year;
  PaperQuestionType? _type;
  bool _hideOutdated = false;

  static final _years = [for (var y = DateTime.now().year; y >= 2011; y--) y];

  PapersQuery get _query => (year: _year, type: _type);

  void _open(PaperSummary p) => context.push(
    AppRoutes.examAttemptPath(p.id, hideOutdated: _hideOutdated),
  );

  @override
  Widget build(BuildContext context) {
    final papers = ref.watch(pastPapersProvider(_query));

    return Scaffold(
      appBar: AppBar(title: const Text('Past papers & exams')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pastPapersProvider(_query).future),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _GenerateCard(onTap: () => context.push(AppRoutes.generatePaper)),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _year,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: [
                      const DropdownMenuItem(child: Text('All years')),
                      for (final y in _years)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (v) => setState(() => _year = v),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<PaperQuestionType?>(
                    initialValue: _type,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: [
                      const DropdownMenuItem(child: Text('All types')),
                      for (final t in PaperQuestionType.values)
                        DropdownMenuItem(value: t, child: Text(t.label)),
                    ],
                    onChanged: (v) => setState(() => _type = v),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hide outdated questions'),
              subtitle: const Text('Leave out parts no longer in the syllabus'),
              value: _hideOutdated,
              onChanged: (v) => setState(() => _hideOutdated = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...papers.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                ErrorBanner(
                  message: ErrorMessages.of(e),
                  onRetry: () => ref.invalidate(pastPapersProvider(_query)),
                ),
              ],
              data: (list) => list.isEmpty
                  ? [
                      const EmptyState(
                        icon: Icons.description_outlined,
                        title: 'No past papers',
                        message: 'Try another year or type.',
                      ),
                    ]
                  : [
                      for (final p in list)
                        _PaperTile(
                          paper: p,
                          hideOutdated: _hideOutdated,
                          onTap: () => _open(p),
                        ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerateCard extends StatelessWidget {
  const _GenerateCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.primarySoft,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.primaryLight),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Model paper generator',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                AiBadge(),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Pick units and the mix of MCQ, structured and essay questions.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Generate model paper',
              icon: Icons.add,
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperTile extends StatelessWidget {
  const _PaperTile({
    required this.paper,
    required this.hideOutdated,
    required this.onTap,
  });

  final PaperSummary paper;
  final bool hideOutdated;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = hideOutdated
        ? paper.questionCount - paper.outdatedCount
        : paper.questionCount;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      paper.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (paper.year != null)
                    AppChip(label: '${paper.year}', tone: AppChipTone.neutral),
                  for (final t in paper.questionTypes)
                    AppChip(label: t.label, tone: AppChipTone.info),
                  AppChip(label: '$count questions', tone: AppChipTone.neutral),
                  if (paper.durationMinutes != null)
                    AppChip(
                      label: '${paper.durationMinutes} min',
                      icon: Icons.timer_outlined,
                      tone: AppChipTone.neutral,
                    ),
                  if (paper.outdatedCount > 0)
                    AppChip(
                      label: hideOutdated
                          ? '${paper.outdatedCount} outdated hidden'
                          : '${paper.outdatedCount} outdated',
                      icon: Icons.history_toggle_off,
                      tone: AppChipTone.streak,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
