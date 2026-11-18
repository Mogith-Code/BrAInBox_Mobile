import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/admin_page.dart';
import '../../../widgets/pick_upload.dart';
import '../application/rag_sources_controller.dart';
import '../domain/rag_sources_models.dart';

/// RAG sources: the approved documents the AI answers from, with their
/// ingestion status and chunk count; upload a new one or re-index.
///
/// Route: `/rag-sources`. Data: `GET /admin/rag/sources`,
/// `POST /admin/rag/sources` (multipart), `POST /admin/rag/reindex`.
class RagSourcesScreen extends ConsumerWidget {
  const RagSourcesScreen({super.key});

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(RagUpload, PickedUpload)>(
      context: context,
      builder: (_) => const UploadSourceDialog(),
    );
    if (result == null || !context.mounted) return;
    final (form, file) = result;
    final error = await ref
        .read(ragSourcesProvider.notifier)
        .upload(form, fileName: file.name, bytes: file.bytes);
    if (!context.mounted) return;
    showAdminSnack(
      context,
      error ?? '${file.name} uploaded. It is being chunked and embedded.',
    );
  }

  Future<void> _reindexAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-index every document?'),
        content: const Text(
          'Every source is chunked and embedded again. The AI keeps using '
          'the current index until that has finished.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Re-index all'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error = await ref.read(ragSourcesProvider.notifier).reindex();
    if (!context.mounted) return;
    showAdminSnack(context, error ?? 'Re-indexing every document.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ragSourcesProvider);
    final rows = state.value;
    final ready = rows?.where((r) => r.status == RagSourceStatus.ready);
    final chunks = ready?.fold<int>(0, (sum, r) => sum + r.chunkCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          eyebrow: rows == null
              ? 'Documents the AI answers from'
              : '${rows.length} documents · '
                    '${Formatters.thousands(chunks ?? 0)} chunks ready',
          title: 'RAG sources',
          actions: [
            OutlinedButton.icon(
              onPressed: rows == null || rows.isEmpty
                  ? null
                  : () => _reindexAll(context, ref),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Re-index all'),
            ),
            FilledButton.icon(
              onPressed: () => _upload(context, ref),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Upload source'),
            ),
          ],
        ),
        Expanded(
          child: switch (state) {
            AsyncError(:final error) when rows == null => AdminLoadError(
              error: error,
              onRetry: () => ref.invalidate(ragSourcesProvider),
            ),
            _ when rows == null => const Center(
              child: CircularProgressIndicator(),
            ),
            _ when rows.isEmpty => const EmptyState(
              icon: Icons.library_books_outlined,
              title: 'No source documents yet',
              message:
                  'Upload the NIE syllabus, teacher guides or approved notes. '
                  'The AI only answers from documents listed here.',
            ),
            _ => SingleChildScrollView(
              child: AdminPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HeaderRow(),
                    const Divider(height: 1),
                    for (final r in rows) ...[
                      RagSourceRow(source: r),
                      const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ),
          },
        ),
      ],
    );
  }
}

const _statusWidth = 150.0;
const _numberWidth = 80.0;
const _dateWidth = 110.0;
const _actionWidth = 130.0;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(child: TableHeading('Document')),
        SizedBox(width: _statusWidth, child: TableHeading('Status')),
        SizedBox(width: _numberWidth, child: TableHeading('Chunks')),
        SizedBox(width: _numberWidth, child: TableHeading('Pages')),
        SizedBox(width: _dateWidth, child: TableHeading('Indexed')),
        SizedBox(width: _actionWidth),
      ],
    ),
  );
}

/// One source document.
class RagSourceRow extends ConsumerStatefulWidget {
  const RagSourceRow({super.key, required this.source});

  final RagSource source;

  @override
  ConsumerState<RagSourceRow> createState() => _RagSourceRowState();
}

class _RagSourceRowState extends ConsumerState<RagSourceRow> {
  bool _busy = false;

  Future<void> _reindex() async {
    setState(() => _busy = true);
    final error = await ref
        .read(ragSourcesProvider.notifier)
        .reindex(documentId: widget.source.id);
    if (!mounted) return;
    setState(() => _busy = false);
    showAdminSnack(context, error ?? 'Re-indexing "${widget.source.title}".');
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.source;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.muted);
    final details = [
      RagSourceType.labelOf(s.sourceType),
      if (s.unitNumber != null) 'Unit ${s.unitNumber}',
      if (s.year != null) '${s.year}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(details, style: muted),
                if (s.status == RagSourceStatus.failed &&
                    (s.errorMessage ?? '').isNotEmpty)
                  Text(
                    s.errorMessage!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: _statusWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusBadge(status: s.status),
            ),
          ),
          SizedBox(
            width: _numberWidth,
            child: Text(
              s.status == RagSourceStatus.ready
                  ? Formatters.thousands(s.chunkCount)
                  : '—',
            ),
          ),
          SizedBox(
            width: _numberWidth,
            child: Text(s.pageCount == null ? '—' : '${s.pageCount}'),
          ),
          SizedBox(
            width: _dateWidth,
            child: Text(
              s.indexedAt == null
                  ? 'Not yet'
                  : Formatters.shortDate(s.indexedAt!),
              style: muted,
            ),
          ),
          SizedBox(
            width: _actionWidth,
            height: 48,
            child: TextButton.icon(
              onPressed: _busy || s.status.isWorking ? null : _reindex,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                s.status == RagSourceStatus.failed ? 'Retry' : 'Re-index',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final RagSourceStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
    decoration: BoxDecoration(
      color: status.tone.background,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status.icon, size: 12, color: status.tone.foreground),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            status.label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: status.tone.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Title, type, unit / year and the file. Pops `(form, file)`.
class UploadSourceDialog extends ConsumerStatefulWidget {
  const UploadSourceDialog({super.key});

  /// What the backend accepts (PDF, DOCX, TXT, Markdown; max 40 MB).
  static const extensions = ['pdf', 'docx', 'txt', 'md'];

  @override
  ConsumerState<UploadSourceDialog> createState() => _UploadSourceDialogState();
}

class _UploadSourceDialogState extends ConsumerState<UploadSourceDialog> {
  final _title = TextEditingController();
  final _year = TextEditingController();
  RagSourceType _type = RagSourceType.syllabus;
  int? _unit;
  PickedUpload? _file;
  String? _error;

  static const _maxBytes = 40 * 1024 * 1024;

  @override
  void dispose() {
    _title.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ref.read(pickUploadProvider)(
      UploadSourceDialog.extensions,
    );
    if (file == null || !mounted) return;
    setState(() {
      _file = file;
      _error = file.bytes.length > _maxBytes
          ? 'The file is larger than 40 MB.'
          : null;
      if (_title.text.trim().isEmpty) {
        _title.text = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      }
    });
  }

  void _submit() {
    final title = _title.text.trim();
    final yearText = _year.text.trim();
    final year = yearText.isEmpty ? null : int.tryParse(yearText);
    final error = switch (()) {
      _ when _file == null => 'Choose a file to upload.',
      _ when _file!.bytes.length > _maxBytes =>
        'The file is larger than 40 MB.',
      _ when title.length < 2 => 'Give the document a title.',
      _
          when yearText.isNotEmpty &&
              (year == null || year < 1990 || year > 2100) =>
        'Enter a year between 1990 and 2100.',
      _ => null,
    };
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, (
      RagUpload(title: title, type: _type, unitNumber: _unit, year: year),
      _file!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload a source document'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _pick,
                icon: const Icon(Icons.attach_file),
                label: Text(_file?.name ?? 'Choose file (PDF, DOCX, TXT, MD)'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<RagSourceType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final t in RagSourceType.values)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (t) => setState(() => _type = t ?? _type),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Unit (optional)',
                      ),
                      items: [
                        const DropdownMenuItem(child: Text('All units')),
                        for (var u = 1; u <= 10; u++)
                          DropdownMenuItem(value: u, child: Text('Unit $u')),
                      ],
                      onChanged: (u) => setState(() => _unit = u),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _year,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Year (optional)',
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Upload')),
      ],
    );
  }
}
