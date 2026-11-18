import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/admin_page.dart';
import '../../application/evaluations_controller.dart';
import '../../domain/evaluation_models.dart';

/// "Evaluation accuracy": how close the AI's marks are to a teacher's.
class EvaluationAccuracyPanel extends ConsumerWidget {
  const EvaluationAccuracyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(evaluationAccuracyProvider);
    return AdminPanel(
      title: 'Evaluation accuracy · AI vs teacher marks',
      trailing: const AiBadge(label: 'AI marking'),
      child: switch (state) {
        AsyncData(:final value) => _Report(report: value),
        AsyncError(:final error) => _InlineError(
          error: error,
          onRetry: () => ref.invalidate(evaluationAccuracyProvider),
        ),
        _ => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      },
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.report});

  final AccuracyReport report;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.muted);
    if (report.samples == 0) {
      return const EmptyState(
        icon: Icons.fact_check_outlined,
        title: 'No teacher marks yet',
        message:
            'Enter a teacher\'s marks for a few answers below to see how '
            'close the AI marking is.',
      );
    }
    final within = report.withinOneMark;
    final mae = report.meanAbsoluteError;
    final r = report.correlation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          children: [
            _Figure(
              label: 'Within 1 mark',
              value: within == null ? '—' : Formatters.percent(within),
            ),
            _Figure(
              label: 'Average gap',
              value: mae == null ? '—' : '${mae.toStringAsFixed(1)} marks',
            ),
            _Figure(
              label: 'Correlation',
              value: r == null ? '—' : r.toStringAsFixed(2),
            ),
            _Figure(
              label: 'Answers compared',
              value: Formatters.thousands(report.samples),
            ),
          ],
        ),
        if (within != null) ...[
          const SizedBox(height: AppSpacing.md),
          _AccuracyVerdict(withinOneMark: within),
        ],
        if (report.note.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(report.note, style: muted),
        ],
      ],
    );
  }
}

/// Icon + word + colour for the headline number.
class _AccuracyVerdict extends StatelessWidget {
  const _AccuracyVerdict({required this.withinOneMark});

  final double withinOneMark;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = withinOneMark >= 0.8
        ? ('Good · the AI is usually within a mark', BadgeTone.success)
        : withinOneMark >= 0.6
        ? ('Fair · check the bigger gaps', BadgeTone.warning)
        : ('Poor · AI marks need review', BadgeTone.danger);
    return Align(
      alignment: Alignment.centerLeft,
      child: StatusBadge(label: label, tone: tone),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// "Evaluations": each AI-marked answer, with a box for the teacher's marks.
class EvaluationsPanel extends ConsumerWidget {
  const EvaluationsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(evaluationQueryProvider);
    final state = ref.watch(evaluationsProvider);
    final page = state.value;

    return AdminPanel(
      title: 'Evaluations',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Only teacher-marked',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Switch(
            value: query.onlyManual,
            onChanged: (v) =>
                ref.read(evaluationQueryProvider.notifier).onlyManual(v),
          ),
        ],
      ),
      child: switch (state) {
        AsyncError(:final error) when page == null => _InlineError(
          error: error,
          onRetry: () => ref.invalidate(evaluationsProvider),
        ),
        _ when page == null => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
        _ when page.items.isEmpty => EmptyState(
          icon: Icons.assignment_outlined,
          title: query.onlyManual
              ? 'No teacher-marked answers'
              : 'No marked answers yet',
          message: query.onlyManual
              ? 'Turn off the switch to see every AI-marked answer.'
              : 'Answers appear here once students check written answers.',
        ),
        _ => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _HeaderRow(),
            const Divider(height: 1),
            for (final e in page.items) ...[
              EvaluationRow(key: ValueKey(e.id), evaluation: e),
              const Divider(height: 1),
            ],
            if (page.pages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Page ${page.page} of ${page.pages}'),
                  IconButton(
                    tooltip: 'Previous page',
                    onPressed: page.page > 1
                        ? () => ref
                              .read(evaluationQueryProvider.notifier)
                              .page(page.page - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: 'Next page',
                    onPressed: page.page < page.pages
                        ? () => ref
                              .read(evaluationQueryProvider.notifier)
                              .page(page.page + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
          ],
        ),
      },
    );
  }
}

const _dateWidth = 90.0;
const _aiWidth = 90.0;
const _teacherWidth = 190.0;
const _gapWidth = 150.0;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(child: TableHeading('Question & answer')),
        SizedBox(width: _dateWidth, child: TableHeading('Date')),
        SizedBox(width: _aiWidth, child: TableHeading('AI marks')),
        SizedBox(width: _teacherWidth, child: TableHeading('Teacher marks')),
        SizedBox(width: _gapWidth, child: TableHeading('Difference')),
      ],
    ),
  );
}

String _marks(double? v) => v == null
    ? '—'
    : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1));

/// One evaluation with an editable teacher-marks box.
class EvaluationRow extends ConsumerStatefulWidget {
  const EvaluationRow({super.key, required this.evaluation});

  final AdminEvaluation evaluation;

  @override
  ConsumerState<EvaluationRow> createState() => _EvaluationRowState();
}

class _EvaluationRowState extends ConsumerState<EvaluationRow> {
  late final _marksField = TextEditingController(
    text: widget.evaluation.manualMarks == null
        ? ''
        : _marks(widget.evaluation.manualMarks),
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _marksField.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final e = widget.evaluation;
    final value = double.tryParse(_marksField.text.trim());
    if (value == null || value < 0 || value > e.markLimit) {
      setState(() => _error = 'Enter 0 to ${_marks(e.markLimit)}.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await ref
        .read(evaluationsProvider.notifier)
        .setManualMarks(e.id, value);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) showAdminSnack(context, 'Teacher marks saved.');
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.evaluation;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.muted);
    final gap = MarkGap.of(e.difference);
    final outOf = e.maxMarks == null ? '' : ' / ${_marks(e.maxMarks)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if ((e.answerText ?? '').isNotEmpty)
                  Text(
                    e.answerText!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: _dateWidth,
            child: Text(Formatters.shortDate(e.createdAt), style: muted),
          ),
          SizedBox(
            width: _aiWidth,
            child: Text('${_marks(e.estimatedMarks)}$outOf'),
          ),
          SizedBox(
            width: _teacherWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 48,
                      child: Semantics(
                        label: 'Teacher marks for ${e.question}',
                        child: TextField(
                          controller: _marksField,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: '—',
                            suffixText: outOf.isEmpty ? null : outOf.trim(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _save(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: _gapWidth,
            child: gap == null
                ? Text('Not compared', style: muted)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(
                      label: gap == MarkGap.close
                          ? gap.label
                          : '${gap.label} by ${_marks(e.difference!.abs())}',
                      tone: gap == MarkGap.close
                          ? BadgeTone.success
                          : BadgeTone.warning,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => isEndpointMissing(error)
      ? const EmptyState(
          icon: Icons.construction_outlined,
          title: 'Not connected yet',
          message: 'The server does not have this report yet.',
        )
      : ErrorBanner(message: ErrorMessages.of(error), onRetry: onRetry);
}
