import 'package:brainbox_core/brainbox_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../syllabus/application/syllabus_controller.dart';
import '../../syllabus/application/unit_detail_controller.dart';
import '../../syllabus/domain/learn_models.dart';
import '../../syllabus/presentation/widgets/learn_widgets.dart';
import '../application/uploads_controller.dart';

/// Picks a file (or opens the camera). Swappable in tests.
typedef UploadFilePicker =
    Future<PickedUploadFile?> Function({required bool camera});

/// The real picker: PDF / DOCX / TXT / JPG / PNG via file_picker, or a
/// photo via image_picker.
Future<PickedUploadFile?> pickUploadFile({required bool camera}) async {
  if (camera) {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo == null) return null;
    return PickedUploadFile(
      name: photo.name,
      path: photo.path.isEmpty ? null : photo.path,
      bytes: photo.path.isEmpty ? await photo.readAsBytes() : null,
      size: await photo.length(),
    );
  }
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: PickedUploadFile.allowedExtensions,
  );
  if (files.isEmpty) return null;
  final file = files.first;
  final path = file.path;
  return PickedUploadFile(
    name: file.name,
    path: path,
    bytes: path == null ? await file.readAsBytes() : null,
    size: await file.length() ?? 0,
  );
}

/// Opens the "Upload notes" sheet. Returns true when an upload started.
Future<bool> showUploadSheet(
  BuildContext context, {
  UploadFilePicker picker = pickUploadFile,
}) async {
  final started = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.learnSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (_) => UploadSheet(picker: picker),
  );
  return started == true;
}

/// Pick a file, optionally link a unit/topic, choose the summary length,
/// then Upload. Progress and processing show in the uploads list.
class UploadSheet extends ConsumerStatefulWidget {
  const UploadSheet({super.key, this.picker = pickUploadFile});

  final UploadFilePicker picker;

  @override
  ConsumerState<UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends ConsumerState<UploadSheet> {
  PickedUploadFile? _file;
  String? _unitId;
  String? _topicId;
  SummaryLength _length = SummaryLength.medium;
  String? _error;

  Future<void> _pick({required bool camera}) async {
    try {
      final file = await widget.picker(camera: camera);
      if (!mounted || file == null) return;
      if (!PickedUploadFile.allowedExtensions.contains(file.extension)) {
        setState(() => _error = 'Use a PDF, DOCX, TXT, JPG or PNG file.');
        return;
      }
      setState(() {
        _file = file;
        _error = null;
      });
    } catch (_) {
      if (mounted)
        setState(() => _error = "Couldn't open that file. Try another one.");
    }
  }

  void _upload() {
    final file = _file;
    if (file == null) return;
    final topics = _unitId == null
        ? null
        : ref.read(unitDetailControllerProvider(_unitId!)).value?.topics;
    final topicTitle = topics
        ?.where((t) => t.id == _topicId)
        .firstOrNull
        ?.title;
    // Fire and forget: the list shows progress, processing and the result.
    ref
        .read(uploadsControllerProvider.notifier)
        .startUpload(
          file,
          topicId: _topicId,
          topicTitle: topicTitle,
          summaryLength: _length,
        );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final units = ref.watch(syllabusControllerProvider).value ?? const [];
    final topics = _unitId == null
        ? null
        : ref.watch(unitDetailControllerProvider(_unitId!)).value?.topics;
    Text label(String text) => Text(
      text,
      style: textTheme.labelLarge?.copyWith(color: context.learnInk),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Upload notes',
                style: textTheme.titleLarge?.copyWith(color: context.learnInk),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'PDF, DOCX, TXT, JPG or PNG. BrAInBox summarises it for you.',
              style: textTheme.bodySmall?.copyWith(color: context.learnMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_file == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pick(camera: false),
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Choose file'),
                      style: _outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pick(camera: true),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Take photo'),
                      style: _outlined,
                    ),
                  ),
                ],
              )
            else
              LearnCard(
                child: Row(
                  children: [
                    Icon(_fileIcon(_file!.extension), color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _file!.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: context.learnInk,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove file',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _file = null),
                    ),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
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
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.errorDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            label('Link to a topic (optional)'),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String?>(
              initialValue: _unitId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Unit'),
              items: [
                const DropdownMenuItem(value: null, child: Text('No unit')),
                for (final u in units)
                  DropdownMenuItem(
                    value: u.id,
                    child: Text(
                      'Unit ${u.order} · ${u.title}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() {
                _unitId = v;
                _topicId = null;
              }),
            ),
            if (_unitId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String?>(
                key: ValueKey(_unitId),
                initialValue: _topicId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Topic'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Whole unit'),
                  ),
                  for (final t in topics ?? const [])
                    DropdownMenuItem(
                      value: t.id,
                      child: Text(t.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: topics == null
                    ? null
                    : (v) => setState(() => _topicId = v),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            label('Summary length'),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<SummaryLength>(
              segments: [
                for (final l in SummaryLength.values)
                  ButtonSegment(value: l, label: Text(l.label)),
              ],
              selected: {_length},
              onSelectionChanged: (s) => setState(() => _length = s.first),
            ),
            const SizedBox(height: AppSpacing.xl),
            GradientButton(
              label: 'Upload and summarise',
              icon: Icons.cloud_upload_outlined,
              onPressed: _file == null ? null : _upload,
            ),
          ],
        ),
      ),
    );
  }

  static final _outlined = OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LearnStyle.buttonRadius),
    ),
  );
}

IconData _fileIcon(String ext) => switch (ext) {
  'pdf' => Icons.picture_as_pdf_outlined,
  'jpg' || 'jpeg' || 'png' => Icons.image_outlined,
  'docx' => Icons.description_outlined,
  _ => Icons.text_snippet_outlined,
};

/// File icon by name, for lists.
IconData uploadFileIcon(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return _fileIcon(dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase());
}
