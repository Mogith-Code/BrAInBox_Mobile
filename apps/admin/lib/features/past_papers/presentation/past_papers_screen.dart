import 'package:brainbox_core/brainbox_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/admin_page.dart';
import '../application/past_papers_controller.dart';
import '../domain/past_papers_models.dart';
import 'widgets/answer_key_editor.dart';

/// Past papers & marking schemes: upload a paper PDF, follow its question
/// extraction, and check each question's model answer and marking keywords.
///
/// Route: `/past-papers`. Data: `/admin/questions/past-papers`.
class PastPapersScreen extends ConsumerStatefulWidget {
  const PastPapersScreen({super.key});

  @override
  ConsumerState<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends ConsumerState<PastPapersScreen> {
  int _year = 2024;
  PaperType _type = PaperType.paper2Structured;
  String? _openId;
  bool _uploading = false;

  Future<void> _upload() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    final ok = await ref
        .read(pastPapersControllerProvider.notifier)
        .upload(
          bytes: await file.readAsBytes(),
          fileName: file.name,
          year: _year,
          type: _type,
        );
    if (!mounted) return;
    setState(() => _uploading = false);
    showAdminSnack(
      context,
      ok
          ? '${file.name} uploaded. Extracting questions...'
          : 'Upload failed. Try again.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pastPapersControllerProvider);
    final papers = state.value ?? const <PastPaper>[];
    final open = papers.where((p) => p.id == _openId).firstOrNull;

    final left = ListView(
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            SizedBox(
              width: 340,
              child: _DropZone(onTap: _uploading ? null : _upload),
            ),
            SizedBox(
              width: 280,
              child: AdminPanel(
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: _year,
                      decoration: const InputDecoration(labelText: 'Year'),
                      items: [
                        for (var y = 2024; y >= 2011; y--)
                          DropdownMenuItem(value: y, child: Text('$y')),
                      ],
                      onChanged: (y) => setState(() => _year = y ?? _year),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<PaperType>(
                      initialValue: _type,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Paper type',
                      ),
                      items: [
                        for (final t in PaperType.values)
                          DropdownMenuItem(value: t, child: Text(t.label)),
                      ],
                      onChanged: (t) => setState(() => _type = t ?? _type),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AdminPanel(
          padding: EdgeInsets.zero,
          child: switch (state) {
            AsyncData() when papers.isEmpty => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text('No papers yet. Upload the first one above.'),
            ),
            AsyncData() => Column(
              children: [
                const _PaperRow(
                  cells: [
                    TableHeading('Year'),
                    TableHeading('Paper'),
                    TableHeading('Marking scheme'),
                    TableHeading('Extraction'),
                    SizedBox(),
                  ],
                ),
                for (final p in papers) ...[
                  const Divider(height: 1),
                  _PaperRow(
                    selected: p.id == _openId,
                    cells: [
                      Text(
                        '${p.year}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(p.paperType.label),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: p.outdatedSyllabus
                            ? const StatusBadge(
                                label: 'Outdated syllabus',
                                tone: BadgeTone.warning,
                              )
                            : p.schemeLinked
                            ? const StatusBadge(
                                label: 'Linked',
                                tone: BadgeTone.success,
                                showIcon: false,
                              )
                            : const StatusBadge(
                                label: '+ Link scheme',
                                tone: BadgeTone.warning,
                                showIcon: false,
                              ),
                      ),
                      _Extraction(paper: p),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() => _openId = p.id),
                          child: const Text('Open'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            AsyncError(:final error) => SizedBox(
              height: 300,
              child: AdminLoadError(
                error: error,
                onRetry: () => ref.invalidate(pastPapersControllerProvider),
              ),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ),
      ],
    );

    final right = open == null
        ? const AdminPanel(
            child: EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'Open a paper',
              message:
                  'Check each question\'s model answer and marking keywords.',
            ),
          )
        : AnswerKeyEditor(key: ValueKey(open.id), paper: open);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          eyebrow: 'Department of Examinations · 2011–2024',
          title: 'Past papers & marking schemes',
          actions: [
            FilledButton.icon(
              onPressed: _uploading ? null : _upload,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: Text(_uploading ? 'Uploading...' : 'Upload paper'),
            ),
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => box.maxWidth >= 1100
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: left),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(flex: 2, child: right),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: left),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(child: right),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.primarySoft.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.primaryLight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upload_file, color: AppColors.primary, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choose a paper PDF',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'max 40 MB · Sinhala / Tamil / English',
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperRow extends StatelessWidget {
  const _PaperRow({required this.cells, this.selected = false});

  final List<Widget> cells;
  final bool selected;

  static const _flex = [1, 3, 2, 3, 1];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: selected ? AppColors.primarySoft : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(flex: _flex[i], child: cells[i]),
        ],
      ),
    );
  }
}

class _Extraction extends StatelessWidget {
  const _Extraction({required this.paper});

  final PastPaper paper;

  @override
  Widget build(BuildContext context) {
    final p = paper;
    return switch (p.extraction) {
      ExtractionStatus.done => Text(
        '✓ ${p.questionsExtracted} questions extracted',
        style: const TextStyle(color: AppColors.successDark),
      ),
      ExtractionStatus.running => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extracting · ${Formatters.percent(p.progress)}',
            style: const TextStyle(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: p.progress,
            minHeight: 4,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        ],
      ),
      ExtractionStatus.lowConfidence => Text(
        '⚠ ${p.lowConfidence} low-confidence',
        style: const TextStyle(color: AppColors.warningDark),
      ),
      ExtractionStatus.failed => const Text(
        'Extraction failed',
        style: TextStyle(color: AppColors.error),
      ),
    };
  }
}
