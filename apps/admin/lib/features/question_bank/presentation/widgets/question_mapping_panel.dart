import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/admin_page.dart';
import '../../../syllabus_manager/application/syllabus_manager_controller.dart';
import '../../domain/question_bank_models.dart';

/// Unit -> topic -> concept dropdowns (from the syllabus API) and the
/// difficulty buttons.
class QuestionMappingPanel extends ConsumerWidget {
  const QuestionMappingPanel({
    super.key,
    required this.question,
    required this.onChanged,
  });

  final QuestionDetail question;
  final ValueChanged<QuestionDetail> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = question;
    final units = ref.watch(syllabusUnitsProvider).value ?? const [];
    final topics = q.unitId == null
        ? const []
        : ref.watch(unitTopicsProvider(q.unitId!)).value ?? const [];
    final concepts = q.topicId == null
        ? const []
        : ref.watch(topicConceptsProvider(q.topicId!)).value ?? const [];

    DropdownButtonFormField<String> dropdown(
      String label,
      String? value,
      List<(String, String)> items,
      ValueChanged<String?> onSelect,
    ) => DropdownButtonFormField<String>(
      initialValue: items.any((i) => i.$1 == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final (id, text) in items)
          DropdownMenuItem(
            value: id,
            child: Text(text, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onSelect,
    );

    return AdminPanel(
      title: 'Mapping',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          dropdown(
            'Unit',
            q.unitId,
            [
              for (final u in units)
                (u.id, '${u.number.toString().padLeft(2, '0')} ${u.title}'),
            ],
            (id) => onChanged(
              q.copyWith(unitId: id, topicId: null, conceptId: null),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          dropdown('Topic', q.topicId, [
            for (final t in topics) (t.id, '${t.number} ${t.title}'),
          ], (id) => onChanged(q.copyWith(topicId: id, conceptId: null))),
          const SizedBox(height: AppSpacing.md),
          dropdown('Concept', q.conceptId, [
            for (final c in concepts) (c.id, c.name),
          ], (id) => onChanged(q.copyWith(conceptId: id))),
          const SizedBox(height: AppSpacing.md),
          Text('Difficulty', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<Difficulty>(
            segments: [
              for (final d in Difficulty.values)
                ButtonSegment(value: d, label: Text(d.label)),
            ],
            selected: {q.difficulty},
            onSelectionChanged: (s) =>
                onChanged(q.copyWith(difficulty: s.first)),
          ),
        ],
      ),
    );
  }
}
