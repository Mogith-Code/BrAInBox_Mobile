import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../syllabus/domain/learn_models.dart';
import '../../syllabus/presentation/unit_detail_screen.dart' show LearnBackButton;
import '../../syllabus/presentation/widgets/learn_widgets.dart';
import '../application/uploads_controller.dart';
import 'uploads_screen.dart' show UploadStatusChip;

/// One upload: Summary (AI) / Key points / Original text, "Save to short
/// notes" and delete.
///
/// Route: `/learn/uploads/:uploadId` (inside the Learn tab).
class UploadDetailScreen extends ConsumerStatefulWidget {
  const UploadDetailScreen({super.key, required this.uploadId});

  final String uploadId;

  /// How long the "Undo" stays before the save is sent.
  static const undoWindow = Duration(seconds: 4);

  @override
  ConsumerState<UploadDetailScreen> createState() => _UploadDetailScreenState();
}

class _UploadDetailScreenState extends ConsumerState<UploadDetailScreen> {
  bool _saving = false;
  bool _saved = false;

  /// The save is sent when the Undo window closes, so Undo needs no
  /// server call.
  Future<void> _saveToShortNotes() async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(uploadsControllerProvider.notifier);
    setState(() => _saving = true);
    var undone = false;
    messenger.hideCurrentSnackBar();
    final bar = messenger.showSnackBar(
      SnackBar(
        content: const Text('Saved to your short notes'),
        duration: UploadDetailScreen.undoWindow,
        action: SnackBarAction(label: 'Undo', onPressed: () => undone = true),
      ),
    );
    await bar.closed;
    if (undone) {
      if (mounted) setState(() => _saving = false);
      return;
    }
    try {
      await controller.saveToShortNotes(widget.uploadId);
      if (mounted) setState(() => _saved = true);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(ErrorMessages.of(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(Upload upload) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this upload?'),
        content: Text(
          '"${upload.fileName}" and its summary will be deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(uploadsControllerProvider.notifier).delete(upload.id);
      messenger.showSnackBar(const SnackBar(content: Text('Upload deleted')));
      router.canPop() ? router.pop() : router.go(AppRoutes.uploads);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(ErrorMessages.of(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = uploadDetailProvider(widget.uploadId);
    final state = ref.watch(provider);
    final textTheme = Theme.of(context).textTheme;
    final upload = state.value;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.learnBackground,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    const LearnBackButton(onDark: false),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        upload?.fileName ?? 'Upload',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(color: context.learnInk),
                      ),
                    ),
                    if (upload != null)
                      IconButton(
                        tooltip: 'Delete upload',
                        icon: const Icon(Icons.delete_outline),
                        color: AppColors.error,
                        onPressed: () => _delete(upload),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: switch (state) {
                  AsyncValue(:final value?) => _body(context, value),
                  AsyncError(:final error) => ErrorCard(
                    error: error,
                    onRetry: () => ref.invalidate(provider),
                  ),
                  _ => const SkeletonList(count: 4, label: 'Loading upload', height: 90),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Upload upload) {
    final textTheme = Theme.of(context).textTheme;
    if (upload.status.isBusy) {
      return LearnEmptyState(
        icon: Icons.hourglass_top,
        title: 'BrAInBox is reading your notes',
        message: 'This usually takes under a minute. You can leave this screen.',
        action: UploadStatusChip(status: upload.status),
      );
    }
    if (upload.status == UploadStatus.failed) {
      return LearnEmptyState(
        icon: Icons.error_outline,
        title: "We couldn't summarise this file",
        message: upload.error ?? 'Try uploading a clearer copy.',
      );
    }

    Widget scroll(List<Widget> children) => RefreshIndicator(
      onRefresh: () => ref.refresh(uploadDetailProvider(widget.uploadId).future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: children,
      ),
    );
    final body = textTheme.bodyLarge?.copyWith(
      color: context.learnInk,
      fontSize: 15,
      height: 1.55,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          labelColor: AppColors.primary,
          unselectedLabelColor: context.learnMuted,
          indicatorColor: AppColors.primary,
          dividerColor: context.learnBorder,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Key points'),
            Tab(text: 'Original text'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              scroll([
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    const AiBadge(),
                    if (upload.topic != null && upload.topic!.title.isNotEmpty)
                      SyllabusTag(text: upload.topic!.title),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(upload.summary ?? 'No summary.', style: body),
              ]),
              scroll([
                if (upload.keyPoints.isEmpty) Text('No key points.', style: body),
                for (final point in upload.keyPoints)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3, right: AppSpacing.sm),
                          child: Icon(Icons.check_circle, size: 16, color: AppColors.secondary),
                        ),
                        Expanded(child: Text(point, style: body)),
                      ],
                    ),
                  ),
              ]),
              scroll([
                SelectableText(upload.extractedText ?? 'No text.', style: body),
              ]),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _saved
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check),
                    label: const Text('Saved to short notes'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  )
                : GradientButton(
                    label: 'Save to short notes',
                    icon: Icons.bookmark_add_outlined,
                    onPressed: _saving ? null : () => unawaited(_saveToShortNotes()),
                  ),
          ),
        ),
      ],
    );
  }
}
