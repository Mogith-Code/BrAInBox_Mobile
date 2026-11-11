import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/syllabus_manager_controller.dart';
import '../../domain/syllabus_manager_models.dart';

/// The "Edit node" form: name, syllabus code, learning outcome (concepts)
/// or description (units / topics), and "Flag as outdated".
class NodeEditor extends ConsumerStatefulWidget {
  const NodeEditor({
    super.key,
    required this.node,
    required this.onSaved,
    required this.onCancel,
  });

  final SelectedNode node;
  final ValueChanged<SelectedNode> onSaved;
  final VoidCallback onCancel;

  @override
  ConsumerState<NodeEditor> createState() => _NodeEditorState();
}

class _NodeEditorState extends ConsumerState<NodeEditor> {
  late final _name = TextEditingController(text: widget.node.name);
  late final _code = TextEditingController(text: widget.node.code ?? '');
  late final _text = TextEditingController(text: widget.node.text ?? '');
  late bool _outdated = widget.node.isOutdated;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final ok = await ref
        .read(syllabusEditorProvider.notifier)
        .save(
          widget.node,
          name: _name.text,
          code: _code.text,
          text: _text.text,
          isOutdated: _outdated,
        );
    if (ok && mounted) {
      widget.onSaved(
        widget.node.copyWith(
          name: _name.text.trim(),
          code: _code.text.trim(),
          text: _text.text.trim(),
          isOutdated: _outdated,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final state = ref.watch(syllabusEditorProvider);
    final textTheme = Theme.of(context).textTheme;
    final isConcept = node.kind == NodeKind.concept;
    final label = switch (node.kind) {
      NodeKind.unit => 'Unit',
      NodeKind.topic => 'Topic',
      NodeKind.concept => 'Concept',
    };

    return ListView(
      children: [
        Text(
          node.breadcrumb,
          style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(label: '$label name', controller: _name),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: node.kind == NodeKind.unit ? 'Unit number' : 'Syllabus code',
          controller: _code,
          enabled: node.kind != NodeKind.unit, // units keep their number
          hint: isConcept ? 'e.g. 6.2.4' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: isConcept ? 'Learning outcome' : 'Description',
          controller: _text,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            border: Border.all(color: AppColors.warningBorder),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _outdated,
              onChanged: (v) => setState(() => _outdated = v),
              activeThumbColor: AppColors.white,
              activeTrackColor: AppColors.warning,
              secondary: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warningDark,
              ),
              title: const Text('Flag as outdated'),
              subtitle: const Text(
                'Hidden from new plans; past papers keep a warning tag.',
              ),
            ),
          ),
        ),
        if (state.hasError) ...[
          const SizedBox(height: AppSpacing.md),
          ErrorBanner(message: ErrorMessages.of(state.error)),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Save changes',
                isLoading: state.isLoading,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Asks for the name and code of a new unit / topic / concept.
/// Pops `(name, code)` or null.
class AddNodeDialog extends StatefulWidget {
  const AddNodeDialog({super.key, required this.kind});

  final NodeKind kind;

  @override
  State<AddNodeDialog> createState() => _AddNodeDialogState();
}

class _AddNodeDialogState extends State<AddNodeDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final what = kind.name[0].toUpperCase() + kind.name.substring(1);
    return AlertDialog(
      title: Text('Add $what'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: '$what name',
              controller: _name,
              validator: (v) => Validators.requiredField(v, field: 'Name'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: switch (kind) {
                NodeKind.unit => 'Unit number (1-99)',
                NodeKind.topic => 'Topic number (e.g. 6.4)',
                NodeKind.concept => 'Syllabus code (optional)',
              },
              controller: _code,
              keyboardType: kind == NodeKind.unit
                  ? TextInputType.number
                  : TextInputType.text,
              validator: (v) {
                final value = (v ?? '').trim();
                if (kind == NodeKind.concept) return null;
                if (value.isEmpty) return 'Required';
                if (kind == NodeKind.unit) {
                  final n = int.tryParse(value);
                  if (n == null || n < 1 || n > 99) return 'Use 1 to 99';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_form.currentState?.validate() ?? false) {
              Navigator.of(context).pop((_name.text, _code.text));
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
