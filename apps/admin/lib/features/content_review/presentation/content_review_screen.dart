import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/admin_page.dart';
import '../application/content_review_controller.dart';
import '../domain/content_review_models.dart';

/// Content library: notes, short notes and diagrams with their review
/// status, and a preview panel to Approve, Edit or Reject.
///
/// Route: `/content-review`. Data: `/admin/content`.
class ContentReviewScreen extends ConsumerStatefulWidget {
  const ContentReviewScreen({super.key});

  @override
  ConsumerState<ContentReviewScreen> createState() =>
      _ContentReviewScreenState();
}

class _ContentReviewScreenState extends ConsumerState<ContentReviewScreen> {
  String? _selectedId;

  static const _statuses = [
    null,
    'pending_review',
    'approved',
    'rejected',
    'draft',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contentReviewControllerProvider);
    final filter = ref.watch(contentFilterControllerProvider);
    final setFilter = ref.read(contentFilterControllerProvider.notifier).set;
    final items = state.value ?? const <ContentItem>[];
    final selected =
        items.where((i) => i.id == _selectedId).firstOrNull ??
        items.firstOrNull;

    final table = AdminPanel(
      padding: EdgeInsets.zero,
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final type in [null, ...ContentType.values])
                    ChoiceChip(
                      label: Text(type?.label ?? 'All'),
                      selected: filter.type == type,
                      onSelected: (_) => setFilter(filter.copyWith(type: type)),
                    ),
                  const SizedBox(width: AppSpacing.md),
                  FilterDropdown<String?>(
                    label: 'Status',
                    value: filter.status,
                    options: _statuses,
                    labelOf: (s) => s == null
                        ? 'Any'
                        : reviewBadge(ReviewStatus.fromApi(s)).label,
                    onChanged: (s) => setFilter(filter.copyWith(status: s)),
                  ),
                  FilterDropdown<int?>(
                    label: 'Unit',
                    value: filter.unit,
                    options: [null, for (var u = 1; u <= 10; u++) u],
                    labelOf: (u) => u?.toString() ?? 'All',
                    onChanged: (u) => setFilter(filter.copyWith(unit: u)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: switch (state) {
                AsyncData(:final value) when value.isEmpty => const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Nothing here',
                  message: 'No content matches these filters.',
                ),
                AsyncData(:final value) => ListView.separated(
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _ContentRow(
                    item: value[i],
                    selected: value[i].id == selected?.id,
                    onTap: () => setState(() => _selectedId = value[i].id),
                  ),
                ),
                AsyncError(:final error) => AdminLoadError(
                  error: error,
                  onRetry: () =>
                      ref.invalidate(contentReviewControllerProvider),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
    final preview = selected == null
        ? const AdminPanel(
            child: EmptyState(
              icon: Icons.preview_outlined,
              title: 'Nothing selected',
              message: 'Pick a row to preview and review it.',
            ),
          )
        : _Preview(key: ValueKey(selected.id), item: selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          eyebrow: state.hasValue
              ? 'Notes, short notes & diagrams · ${Formatters.thousands(items.length)} items'
              : 'Notes, short notes & diagrams',
          title: 'Content library',
          actions: [
            FilledButton.icon(
              onPressed: () => showAdminSnack(
                context,
                'AI notes are generated per topic (POST /admin/content/generate).',
              ),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate'),
            ),
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => box.maxWidth >= 1000
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: table),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(flex: 2, child: preview),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: table),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(child: preview),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _ContentRow extends StatelessWidget {
  const _ContentRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ContentItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.muted);
    return Material(
      color: selected ? AppColors.primarySoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                item.type == ContentType.diagram
                    ? Icons.biotech_outlined
                    : Icons.description_outlined,
                color: item.type == ContentType.diagram
                    ? AppColors.secondary
                    : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 4,
                child: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(flex: 2, child: Text(item.type.rowLabel, style: muted)),
              Expanded(
                flex: 2,
                child: Text(
                  item.unitNumber == null
                      ? '—'
                      : 'Unit ${item.unitNumber} · ${item.syllabusCode ?? ''}',
                  style: muted,
                ),
              ),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: reviewBadge(
                    ReviewStatus.fromApi(item.status),
                    aiGenerated: item.isAiGenerated,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item.updatedAt == null
                      ? ''
                      : Formatters.relativeTime(item.updatedAt!),
                  style: muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends ConsumerStatefulWidget {
  const _Preview({super.key, required this.item});

  final ContentItem item;

  @override
  ConsumerState<_Preview> createState() => _PreviewState();
}

class _PreviewState extends ConsumerState<_Preview> {
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _review(bool approve) async {
    setState(() => _busy = true);
    final saved = await ref
        .read(contentReviewControllerProvider.notifier)
        .review(widget.item.id, approve: approve, note: _note.text);
    if (!mounted) return;
    setState(() => _busy = false);
    showAdminSnack(
      context,
      saved == null
          ? "Couldn't save the review. Try again."
          : approve
          ? 'Approved. Students can see it now.'
          : 'Rejected.',
    );
  }

  Future<void> _edit() async {
    final body = await showDialog<String>(
      context: context,
      builder: (_) => _EditDialog(initial: widget.item.bodyMarkdown ?? ''),
    );
    if (body == null || !mounted) return;
    final saved = await ref
        .read(contentReviewControllerProvider.notifier)
        .edit(widget.item.id, body);
    if (mounted) {
      showAdminSnack(context, saved == null ? "Couldn't save." : 'Saved.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final textTheme = Theme.of(context).textTheme;
    final status = ReviewStatus.fromApi(item.status);
    return AdminPanel(
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PREVIEW',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                reviewBadge(status, aiGenerated: item.isAiGenerated),
                if (item.unitNumber != null)
                  StatusBadge(
                    label:
                        'Unit ${item.unitNumber} · ${item.syllabusCode ?? ''}',
                    tone: BadgeTone.info,
                    showIcon: false,
                  ),
                if (item.model != null)
                  StatusBadge(
                    label:
                        'Model: ${item.model}'
                        '${item.promptVersion == null ? '' : ' · ${item.promptVersion}'}',
                    tone: BadgeTone.neutral,
                    showIcon: false,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: item.type == ContentType.diagram
                    ? (item.imageUrl == null
                          ? const Center(child: Text('No image'))
                          : Image.network(item.imageUrl!, fit: BoxFit.contain))
                    : Markdown(
                        data: item.bodyMarkdown ?? '',
                        padding: EdgeInsets.zero,
                      ),
              ),
            ),
            if (item.autoCheck != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  border: Border.all(color: AppColors.warningBorder),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text.rich(
                  TextSpan(
                    text: 'Auto-check: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(
                        text: item.autoCheck,
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.warningDark,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Reviewer note',
              hint: 'Optional — visible to content team',
              controller: _note,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    onPressed: _busy ? null : () => _review(false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy || item.type == ContentType.diagram
                        ? null
                        : _edit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.successDark,
                    ),
                    onPressed: _busy ? null : () => _review(true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.initial});

  final String initial;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _body = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit notes'),
      content: SizedBox(
        width: 600,
        child: TextField(
          controller: _body,
          maxLines: 14,
          decoration: const InputDecoration(helperText: 'Markdown'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_body.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
