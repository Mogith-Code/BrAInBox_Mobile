import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/exams_controller.dart';
import '../domain/paper_models.dart';

/// Answer letters, "A" = first option.
const List<String> kOptionLetters = ['A', 'B', 'C', 'D', 'E'];

/// Status of one question in the palette.
enum QuestionStatus {
  answered('Answered', Icons.check_circle, AppColors.successDark),
  unanswered('Unanswered', Icons.radio_button_unchecked, AppColors.muted),
  flagged('Flagged', Icons.flag, AppColors.warningDark);

  const QuestionStatus(this.word, this.icon, this.color);

  final String word;
  final IconData icon;
  final Color color;
}

/// Exam mode: Part I MCQ / Part II structured / essay tabs, a question
/// palette and a submit confirmation.
///
/// Route: `/exams/attempt/:paperId?hide_outdated=true`
class ExamAttemptScreen extends ConsumerWidget {
  const ExamAttemptScreen({
    super.key,
    required this.paperId,
    this.hideOutdated = false,
  });

  final String paperId;
  final bool hideOutdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = (id: paperId, hideOutdated: hideOutdated);
    final paper = ref.watch(paperDetailProvider(arg));
    return paper.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Exam mode')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Exam mode')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ErrorBanner(
            message: ErrorMessages.of(e),
            onRetry: () => ref.invalidate(paperDetailProvider(arg)),
          ),
        ),
      ),
      data: (p) => p.questions.isEmpty
          ? Scaffold(
              appBar: AppBar(title: Text(p.title)),
              body: EmptyState(
                icon: Icons.description_outlined,
                title: 'No questions in this paper',
                message: p.hiddenOutdated > 0
                    ? '${p.hiddenOutdated} outdated questions are hidden.'
                    : null,
                actionLabel: 'Back to papers',
                onAction: () => context.go(AppRoutes.pastPapers),
              ),
            )
          : _ExamView(paper: p),
    );
  }
}

class _ExamView extends ConsumerStatefulWidget {
  const _ExamView({required this.paper});

  final PaperDetail paper;

  @override
  ConsumerState<_ExamView> createState() => _ExamViewState();
}

class _ExamViewState extends ConsumerState<_ExamView>
    with TickerProviderStateMixin {
  late final List<PaperQuestionType> _types = [
    for (final t in PaperQuestionType.values)
      if (widget.paper.ofType(t).isNotEmpty) t,
  ];
  late final TabController _tabs = TabController(
    length: _types.length,
    vsync: this,
  );
  final Map<String, GlobalKey> _keys = {};
  Timer? _timer;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  QuestionStatus _status(ExamAttemptState s, String id) {
    if (s.flagged.contains(id)) return QuestionStatus.flagged;
    return s.isAnswered(id)
        ? QuestionStatus.answered
        : QuestionStatus.unanswered;
  }

  String get _clock {
    final limit = widget.paper.durationMinutes;
    final secs = limit == null ? _elapsed : limit * 60 - _elapsed;
    final s = secs.abs();
    final text =
        '${s ~/ 3600}:${(s ~/ 60 % 60).toString().padLeft(2, '0')}:'
        '${(s % 60).toString().padLeft(2, '0')}';
    if (limit == null) return text;
    return secs < 0 ? 'Over by $text' : '$text left';
  }

  Future<void> _jumpTo(PaperQuestion q) async {
    Navigator.of(context).pop();
    _tabs.animateTo(_types.indexOf(q.type));
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final ctx = _keys[q.id]?.currentContext;
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(ctx, alignment: 0.1);
    }
  }

  void _showPalette() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final s = ref.watch(examAttemptControllerProvider(widget.paper.id));
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Question palette',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _Legend(),
                  const SizedBox(height: AppSpacing.md),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final (i, q) in widget.paper.questions.indexed)
                            _PaletteCell(
                              number: i + 1,
                              status: _status(s, q.id),
                              onTap: () => _jumpTo(q),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmSubmit() async {
    final s = ref.read(examAttemptControllerProvider(widget.paper.id));
    final qs = widget.paper.questions;
    final answered = qs.where((q) => s.isAnswered(q.id)).length;
    final flagged = qs.where((q) => s.flagged.contains(q.id)).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit paper?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CountRow(QuestionStatus.answered, answered),
            _CountRow(QuestionStatus.unanswered, qs.length - answered),
            _CountRow(QuestionStatus.flagged, flagged),
            const SizedBox(height: AppSpacing.sm),
            const Text('You cannot change your answers after submitting.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep working'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final result = await ref
        .read(examAttemptControllerProvider(widget.paper.id).notifier)
        .submit(widget.paper);
    if (result != null && mounted) context.go(AppRoutes.examResult);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.paper;
    final s = ref.watch(examAttemptControllerProvider(p.id));
    final ctrl = ref.read(examAttemptControllerProvider(p.id).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(p.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Question palette',
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: _showPalette,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(76),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: AppSpacing.lg),
                  const Icon(Icons.timer_outlined, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(_clock),
                  const Spacer(),
                  if (p.isAiGenerated) const AiBadge(),
                  const SizedBox(width: AppSpacing.lg),
                ],
              ),
              TabBar(
                controller: _tabs,
                isScrollable: _types.length > 2,
                tabs: [for (final t in _types) Tab(text: t.label)],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          for (final t in _types)
            ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final q in p.ofType(t))
                  _QuestionCard(
                    key: _keys.putIfAbsent(q.id, GlobalKey.new),
                    number: p.questions.indexOf(q) + 1,
                    question: q,
                    status: _status(s, q.id),
                    selected: s.mcq[q.id],
                    text: s.written[q.id] ?? '',
                    onSelect: (l) => ctrl.selectOption(q.id, l),
                    onText: (v) => ctrl.setWritten(q.id, v),
                    onFlag: () => ctrl.toggleFlag(q.id),
                  ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.error != null) ...[
                ErrorBanner(message: s.error!),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppButton(
                label: 'Submit paper',
                icon: Icons.send_rounded,
                isLoading: s.submitting,
                onPressed: s.submitting ? null : _confirmSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.number,
    required this.question,
    required this.status,
    required this.selected,
    required this.text,
    required this.onSelect,
    required this.onText,
    required this.onFlag,
  });

  final int number;
  final PaperQuestion question;
  final QuestionStatus status;
  final String? selected;
  final String text;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onText;
  final VoidCallback onFlag;

  @override
  Widget build(BuildContext context) {
    final q = question;
    final flagged = status == QuestionStatus.flagged;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: flagged ? status.color : AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Q$number',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${q.topic.isEmpty ? '' : '${q.topic} · '}'
                    '${q.marks} mark${q.marks == 1 ? '' : 's'}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
                _StatusLabel(status),
                IconButton(
                  tooltip: flagged ? 'Remove flag' : 'Flag for review',
                  icon: Icon(
                    flagged ? Icons.flag : Icons.outlined_flag,
                    color: flagged ? status.color : AppColors.muted,
                  ),
                  onPressed: onFlag,
                ),
              ],
            ),
            if (q.isOutdated)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppChip(
                  label: 'Outdated syllabus',
                  icon: Icons.history_toggle_off,
                  tone: AppChipTone.streak,
                ),
              ),
            Text(q.stem, style: const TextStyle(color: AppColors.ink)),
            const SizedBox(height: AppSpacing.md),
            if (q.type == PaperQuestionType.mcq)
              for (final (i, o) in q.options.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: McqOptionTile(
                    letter: o.label.isEmpty ? kOptionLetters[i] : o.label,
                    text: o.text,
                    state:
                        selected ==
                            (o.label.isEmpty ? kOptionLetters[i] : o.label)
                        ? McqOptionState.selected
                        : McqOptionState.normal,
                    onTap: () =>
                        onSelect(o.label.isEmpty ? kOptionLetters[i] : o.label),
                  ),
                )
            else
              TextFormField(
                initialValue: text,
                minLines: q.type == PaperQuestionType.essay ? 8 : 4,
                maxLines: null,
                maxLength: 20000,
                decoration: const InputDecoration(
                  hintText: 'Write your answer',
                  border: OutlineInputBorder(),
                ),
                onChanged: onText,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel(this.status);

  final QuestionStatus status;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(status.icon, size: 16, color: status.color),
      const SizedBox(width: AppSpacing.xs),
      Text(status.word, style: TextStyle(color: status.color, fontSize: 12)),
    ],
  );
}

class _PaletteCell extends StatelessWidget {
  const _PaletteCell({
    required this.number,
    required this.status,
    required this.onTap,
  });

  final int number;
  final QuestionStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    excludeSemantics: true,
    label: 'Question $number, ${status.word}',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: status.color, width: 1.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$number',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: status.color,
              ),
            ),
            Icon(status.icon, size: 14, color: status.color),
          ],
        ),
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.lg,
    children: [for (final s in QuestionStatus.values) _StatusLabel(s)],
  );
}

class _CountRow extends StatelessWidget {
  const _CountRow(this.status, this.count);

  final QuestionStatus status;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Icon(status.icon, size: 18, color: status.color),
        const SizedBox(width: AppSpacing.sm),
        Text('${status.word}: $count'),
      ],
    ),
  );
}
