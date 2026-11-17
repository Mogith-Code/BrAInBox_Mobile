import 'dart:typed_data';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes.dart';
import '../application/evaluation_controller.dart';
import '../data/evaluation_repository.dart';
import 'widgets/question_header.dart';

/// Photograph the pages of a handwritten answer (up to 6) and send them to
/// be read.
///
/// Route: `/evaluation/handwritten/:questionId`
class HandwrittenUploadScreen extends ConsumerStatefulWidget {
  const HandwrittenUploadScreen({super.key, required this.questionId});

  final String questionId;

  @override
  ConsumerState<HandwrittenUploadScreen> createState() =>
      _HandwrittenUploadScreenState();
}

class _HandwrittenUploadScreenState
    extends ConsumerState<HandwrittenUploadScreen> {
  static const _maxPages = 6;

  final _picker = ImagePicker();
  final List<({Uint8List bytes, String name})> _pages = [];
  String? _pickError;

  Future<void> _add(ImageSource source) async {
    setState(() => _pickError = null);
    try {
      // imageQuality / maxWidth keep each photo well under the 8 MB limit.
      final picked = source == ImageSource.camera
          ? [
              await _picker.pickImage(
                source: source,
                imageQuality: 85,
                maxWidth: 2200,
              ),
            ].nonNulls.toList()
          : await _picker.pickMultiImage(imageQuality: 85, maxWidth: 2200);
      for (final file in picked) {
        if (_pages.length >= _maxPages) break;
        _pages.add((bytes: await file.readAsBytes(), name: file.name));
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(
          () => _pickError =
              'Could not open the camera or gallery. Check the app '
              'permissions and try again.',
        );
      }
    }
  }

  String _mime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _read() async {
    final pages = <AnswerPage>[
      for (final (index, page) in _pages.indexed)
        (
          bytes: page.bytes,
          name: 'page-${index + 1}.${page.name.split('.').last}',
          mimeType: _mime(page.name),
        ),
    ];
    final id = await ref
        .read(evaluationSubmitProvider.notifier)
        .readHandwriting(questionId: widget.questionId, pages: pages);
    if (!mounted || id == null) return;
    context.pushReplacement(AppRoutes.ocrPreviewPath(id));
  }

  @override
  Widget build(BuildContext context) {
    final submit = ref.watch(evaluationSubmitProvider);
    if (submit.isBusy) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reading your answer')),
        body: Center(
          child: AiGeneratingLoader(message: submit.message ?? 'Working...'),
        ),
      );
    }
    final theme = Theme.of(context);
    final full = _pages.length >= _maxPages;
    return Scaffold(
      appBar: AppBar(title: const Text('Handwritten answer')),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          QuestionHeader(questionId: widget.questionId),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Photograph each page flat, in good light, with the whole page '
            'in the picture.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (submit.errorMessage != null || _pickError != null) ...[
            ErrorBanner(message: submit.errorMessage ?? _pickError!),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_pages.isNotEmpty)
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 3 / 4,
              children: [
                for (final (index, page) in _pages.indexed)
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        child: Image.memory(
                          page.bytes,
                          fit: BoxFit.cover,
                          semanticLabel: 'Page ${index + 1}',
                        ),
                      ),
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: CircleAvatar(
                          radius: 12,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton.filledTonal(
                          tooltip: 'Remove page ${index + 1}',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () =>
                              setState(() => _pages.removeAt(index)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: full ? null : () => _add(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Take a photo'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: full ? null : () => _add(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('From gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${_pages.length} of $_maxPages pages',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Read my answer',
            icon: Icons.document_scanner_outlined,
            onPressed: _pages.isEmpty ? null : _read,
          ),
        ],
      ),
    );
  }
}
