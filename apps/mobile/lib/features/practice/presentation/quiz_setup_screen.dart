import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/practice_controller.dart';
import '../domain/practice_models.dart';

/// Quiz setup: unit, number of questions, difficulty, timed, weak areas.
///
/// Route: `/practice/setup`, or
/// `/practice/setup?topicId=...&mode=quick|weak|mistakes&conceptId=...`
/// from a topic's Practice tab, a recommendation or the mistake journal.
class QuizSetupScreen extends ConsumerStatefulWidget {
  const QuizSetupScreen({super.key, this.topicId, this.mode, this.conceptId});

  /// Practise only this topic (from Learn > topic > Practice).
  final String? topicId;

  /// `quick` = 10 MCQs, `weak` = weak areas first, `mistakes` = my mistakes.
  final String? mode;

  /// Practise only this concept (from a recommendation).
  final String? conceptId;

  @override
  ConsumerState<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends ConsumerState<QuizSetupScreen> {
  String? _unitId;
  int _count = 10;
  String _difficulty = 'mixed';
  bool _timed = false;
  late bool _focusWeak = widget.mode == 'weak';

  bool get _mistakesOnly => widget.mode == 'mistakes';
  bool get _scoped => widget.topicId != null || widget.conceptId != null;

  Future<void> _start() async {
    final quizId = await ref
        .read(quizSessionProvider.notifier)
        .start(
          QuizSetup(
            unit: _scoped || _mistakesOnly ? null : _unitId,
            topic: widget.topicId,
            conceptId: widget.conceptId,
            count: _count,
            difficulty: _difficulty,
            timed: _timed,
            focusWeak: _focusWeak,
            mistakesOnly: _mistakesOnly,
          ),
        );
    if (!mounted || quizId == null) return;
    context.pushReplacement(AppRoutes.mcqQuestionPath(quizId));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(quizSessionProvider);
    final units = ref.watch(practiceUnitsProvider);
    final theme = Theme.of(context);
    final title = _mistakesOnly
        ? 'Practice my mistakes'
        : widget.conceptId != null
        ? 'Targeted practice'
        : 'Quiz setup';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          if (session.errorMessage != null) ...[
            ErrorBanner(message: session.errorMessage!),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_mistakesOnly)
            const _Note('You will get the questions you answered wrongly.')
          else if (widget.conceptId != null)
            const _Note('Questions on the concept you are working on.')
          else if (widget.topicId != null)
            const _Note('Questions from this topic only.')
          else ...[
            Text('Unit', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            units.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => ErrorBanner(
                message: ErrorMessages.of(error),
                onRetry: () => ref.invalidate(practiceUnitsProvider),
              ),
              data: (list) => DropdownButtonFormField<String?>(
                initialValue: _unitId,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String?>(child: Text('All units')),
                  for (final unit in list)
                    DropdownMenuItem<String?>(
                      value: unit.id,
                      child: Text(
                        'Unit ${unit.number}: ${unit.title}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _unitId = value),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Number of questions', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 10, label: Text('10')),
              ButtonSegment(value: 20, label: Text('20')),
              ButtonSegment(value: 50, label: Text('50')),
            ],
            selected: {_count},
            onSelectionChanged: (value) => setState(() => _count = value.first),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Difficulty', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'mixed', label: Text('Mixed')),
              ButtonSegment(value: 'easy', label: Text('Easy')),
              ButtonSegment(value: 'medium', label: Text('Medium')),
              ButtonSegment(value: 'hard', label: Text('Hard')),
            ],
            selected: {_difficulty},
            onSelectionChanged: (value) =>
                setState(() => _difficulty = value.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Timed'),
            subtitle: Text(
              '1.5 minutes a question (${(_count * 1.5).ceil()} min)',
            ),
            value: _timed,
            onChanged: (value) => setState(() => _timed = value),
          ),
          if (!_mistakesOnly)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Focus on my weak areas'),
              subtitle: const Text('Your weakest concepts come first'),
              value: _focusWeak,
              onChanged: (value) => setState(() => _focusWeak = value),
            ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Start quiz',
            icon: Icons.play_arrow,
            isLoading: session.isLoading,
            onPressed: _start,
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
