import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/admin_page.dart';
import '../application/syllabus_manager_controller.dart';
import '../domain/syllabus_manager_models.dart';
import 'widgets/node_editor.dart';

/// Syllabus manager: the curriculum tree (stream > subject > unit > topic >
/// concept) and an edit panel for the selected node, including "Flag as
/// outdated".
///
/// Route: `/syllabus`. Data: `/admin/syllabus/*` (built on the backend).
class SyllabusManagerScreen extends ConsumerStatefulWidget {
  const SyllabusManagerScreen({super.key});

  @override
  ConsumerState<SyllabusManagerScreen> createState() =>
      _SyllabusManagerScreenState();
}

class _SyllabusManagerScreenState extends ConsumerState<SyllabusManagerScreen> {
  final _openUnits = <String>{};
  final _openTopics = <String>{};
  SelectedNode? _selected;

  void _select(SelectedNode node) => setState(() => _selected = node);

  Future<void> _addNode() async {
    final selected = _selected;
    // Add under the selection: unit -> topic, topic/concept -> concept.
    final (kind, parentId) = switch (selected?.kind) {
      NodeKind.unit => (NodeKind.topic, selected!.id),
      NodeKind.topic => (NodeKind.concept, selected!.id),
      NodeKind.concept => (NodeKind.concept, selected!.parentId),
      null => (NodeKind.unit, ''),
    };
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => AddNodeDialog(kind: kind),
    );
    if (result == null || !mounted) return;
    final ok = await ref
        .read(syllabusEditorProvider.notifier)
        .add(kind, parentId: parentId, name: result.$1, code: result.$2);
    if (ok && kind != NodeKind.unit) {
      setState(
        () => (kind == NodeKind.topic ? _openUnits : _openTopics).add(parentId),
      );
    }
    if (mounted) {
      showAdminSnack(context, ok ? 'Added.' : "Couldn't add it. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(syllabusUnitsProvider);
    final list = units.value;
    final eyebrow = list == null
        ? 'NIE syllabus 2025 · implemented from 2027 A/L'
        : 'NIE syllabus 2025 · ${list.length} units · '
              '${list.fold<int>(0, (n, u) => n + u.topicCount)} topics';

    final tree = AdminPanel(
      title: 'Curriculum tree',
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Expanded(
        child: switch (units) {
          AsyncData(:final value) => ListView(
            children: [
              const _LevelChips(),
              const SizedBox(height: AppSpacing.sm),
              const _Row(
                depth: 0,
                tag: 'STREAM',
                label: 'Biological Science',
                expanded: true,
              ),
              const _Row(
                depth: 1,
                tag: 'SUBJECT',
                label: 'Biology',
                expanded: true,
              ),
              for (final unit in value)
                _UnitBranch(
                  unit: unit,
                  open: _openUnits.contains(unit.id),
                  openTopics: _openTopics,
                  selectedId: _selected?.id,
                  onToggleUnit: () => setState(
                    () => _openUnits.contains(unit.id)
                        ? _openUnits.remove(unit.id)
                        : _openUnits.add(unit.id),
                  ),
                  onToggleTopic: (id) => setState(
                    () => _openTopics.contains(id)
                        ? _openTopics.remove(id)
                        : _openTopics.add(id),
                  ),
                  onSelect: _select,
                ),
              const _Row(
                depth: 1,
                tag: 'SUBJECT',
                label: 'Chemistry',
                note: 'Coming soon',
              ),
              const _Row(
                depth: 1,
                tag: 'SUBJECT',
                label: 'Physics',
                note: 'Coming soon',
              ),
            ],
          ),
          AsyncError(:final error) => AdminLoadError(
            error: error,
            onRetry: () => ref.invalidate(syllabusUnitsProvider),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );

    final editor = AdminPanel(
      title: 'Edit node',
      child: Expanded(
        child: _selected == null
            ? const EmptyState(
                icon: Icons.account_tree_outlined,
                title: 'Pick a node',
                message: 'Select a unit, topic or concept to edit it.',
              )
            : NodeEditor(
                key: ValueKey(_selected!.id),
                node: _selected!,
                onSaved: (saved) {
                  setState(() => _selected = saved);
                  showAdminSnack(context, 'Saved.');
                },
                onCancel: () => setState(() => _selected = null),
              ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          eyebrow: eyebrow,
          title: 'Syllabus manager',
          actions: [
            FilledButton.icon(
              onPressed: units.hasValue ? _addNode : null,
              icon: const Icon(Icons.add, size: 18),
              label: Text(switch (_selected?.kind) {
                NodeKind.unit => 'Add topic',
                NodeKind.topic || NodeKind.concept => 'Add concept',
                null => 'Add unit',
              }),
            ),
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => box.maxWidth >= 1000
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: tree),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(flex: 2, child: editor),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: tree),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(flex: 2, child: editor),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// "STREAM > SUBJECT > UNIT > TOPIC > CONCEPT"
class _LevelChips extends StatelessWidget {
  const _LevelChips();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, tag) in const [
          'STREAM',
          'SUBJECT',
          'UNIT',
          'TOPIC',
          'CONCEPT',
        ].indexed) ...[
          if (i > 0)
            const Icon(Icons.chevron_right, size: 14, color: AppColors.muted),
          _Tag(tag),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (text) {
      'STREAM' => (AppColors.ink, AppColors.white),
      'SUBJECT' => (AppColors.primary, AppColors.white),
      'UNIT' => (AppColors.primarySoft, AppColors.primary),
      'TOPIC' => (AppColors.successSoft, AppColors.successDark),
      _ => (AppColors.surfaceMuted, AppColors.ink),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// One line of the tree.
class _Row extends StatelessWidget {
  const _Row({
    required this.depth,
    required this.tag,
    required this.label,
    this.expanded,
    this.outdated = false,
    this.selected = false,
    this.note,
    this.onToggle,
    this.onTap,
  });

  final int depth;
  final String tag;
  final String label;

  /// null = a leaf (no arrow).
  final bool? expanded;
  final bool outdated;
  final bool selected;
  final String? note;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: selected ? AppColors.primarySoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(
            left: depth * 24.0,
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: expanded == null
                    ? null
                    : IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        tooltip: expanded! ? 'Collapse' : 'Expand',
                        onPressed: onToggle,
                        icon: Icon(
                          expanded! ? Icons.expand_more : Icons.chevron_right,
                        ),
                      ),
              ),
              _Tag(tag),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    decoration: outdated ? TextDecoration.lineThrough : null,
                    color: outdated ? AppColors.muted : AppColors.ink,
                  ),
                ),
              ),
              if (outdated) ...[
                const SizedBox(width: AppSpacing.sm),
                const StatusBadge(
                  label: 'Outdated syllabus',
                  tone: BadgeTone.warning,
                ),
              ],
              if (note != null) ...[
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(
                  label: note!,
                  tone: BadgeTone.neutral,
                  showIcon: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A unit row and, when open, its topics (and their concepts).
class _UnitBranch extends ConsumerWidget {
  const _UnitBranch({
    required this.unit,
    required this.open,
    required this.openTopics,
    required this.selectedId,
    required this.onToggleUnit,
    required this.onToggleTopic,
    required this.onSelect,
  });

  final AdminUnit unit;
  final bool open;
  final Set<String> openTopics;
  final String? selectedId;
  final VoidCallback onToggleUnit;
  final ValueChanged<String> onToggleTopic;
  final ValueChanged<SelectedNode> onSelect;

  String get _unitLabel =>
      '${unit.number.toString().padLeft(2, '0')} ${unit.title}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = <Widget>[
      _Row(
        depth: 2,
        tag: 'UNIT',
        label: _unitLabel,
        expanded: open,
        outdated: unit.isOutdated,
        selected: selectedId == unit.id,
        onToggle: onToggleUnit,
        onTap: () => onSelect(
          SelectedNode(
            kind: NodeKind.unit,
            id: unit.id,
            parentId: '',
            name: unit.title,
            code: '${unit.number}',
            text: unit.description,
            isOutdated: unit.isOutdated,
            breadcrumb: 'Biology',
          ),
        ),
      ),
    ];
    if (open) {
      final topics = ref.watch(unitTopicsProvider(unit.id));
      children.addAll(switch (topics) {
        AsyncData(:final value) => [for (final t in value) ..._topic(ref, t)],
        AsyncError() => [
          const _Row(depth: 3, tag: 'TOPIC', label: "Couldn't load topics"),
        ],
        _ => [const LinearProgressIndicator(minHeight: 2)],
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  List<Widget> _topic(WidgetRef ref, AdminTopic t) {
    final isOpen = openTopics.contains(t.id);
    final rows = <Widget>[
      _Row(
        depth: 3,
        tag: 'TOPIC',
        label: '${t.number} ${t.title}',
        expanded: isOpen,
        outdated: t.isOutdated,
        selected: selectedId == t.id,
        onToggle: () => onToggleTopic(t.id),
        onTap: () => onSelect(
          SelectedNode(
            kind: NodeKind.topic,
            id: t.id,
            parentId: unit.id,
            name: t.title,
            code: t.number,
            text: t.description,
            isOutdated: t.isOutdated,
            breadcrumb: 'Biology › $_unitLabel',
          ),
        ),
      ),
    ];
    if (isOpen) {
      final concepts = ref.watch(topicConceptsProvider(t.id));
      rows.addAll(switch (concepts) {
        AsyncData(:final value) => [
          for (final c in value)
            _Row(
              depth: 4,
              tag: 'CONCEPT',
              label: c.name,
              outdated: c.isOutdated,
              selected: selectedId == c.id,
              onTap: () => onSelect(
                SelectedNode(
                  kind: NodeKind.concept,
                  id: c.id,
                  parentId: t.id,
                  name: c.name,
                  code: c.code,
                  text: c.learningOutcome,
                  isOutdated: c.isOutdated,
                  breadcrumb: 'Biology › $_unitLabel › ${t.number} ${t.title}',
                ),
              ),
            ),
        ],
        AsyncError() => [
          const _Row(depth: 4, tag: 'CONCEPT', label: "Couldn't load concepts"),
        ],
        _ => [const LinearProgressIndicator(minHeight: 2)],
      });
    }
    return rows;
  }
}
