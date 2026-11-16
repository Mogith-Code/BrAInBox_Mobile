import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../syllabus/domain/learn_models.dart';
import '../../syllabus/presentation/unit_detail_screen.dart'
    show LearnBackButton;
import '../../syllabus/presentation/widgets/learn_widgets.dart';
import '../application/uploads_controller.dart';
import 'upload_sheet.dart';

/// My uploaded notes: upload tuition notes and get an AI summary.
///
/// Route: `/learn/uploads` (inside the Learn tab).
class UploadsScreen extends ConsumerWidget {
  const UploadsScreen({super.key, this.picker = pickUploadFile});

  /// Swappable file picker (tests).
  final UploadFilePicker picker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uploadsControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
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
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  const LearnBackButton(onDark: false),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'My uploaded notes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          color: context.learnInk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: GradientButton(
                label: 'Upload notes',
                icon: Icons.upload_file_outlined,
                onPressed: () => showUploadSheet(context, picker: picker),
              ),
            ),
            Expanded(
              child: switch (state) {
                AsyncValue(:final value?) => RefreshIndicator(
                  onRefresh: ref
                      .read(uploadsControllerProvider.notifier)
                      .refresh,
                  child: value.isEmpty
                      ? LayoutBuilder(
                          builder: (context, c) => ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: c.maxHeight,
                                child: const LearnEmptyState(
                                  icon: Icons.upload_file_outlined,
                                  title: 'No uploads yet',
                                  message:
                                      'Upload your tuition notes and BrAInBox will '
                                      'summarise them, matched to the syllabus.',
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xl,
                          ),
                          itemCount: value.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) =>
                              UploadTile(upload: value[i]),
                        ),
                ),
                AsyncError(:final error) => ErrorCard(
                  error: error,
                  onRetry: () => ref.invalidate(uploadsControllerProvider),
                ),
                _ => const SkeletonList(label: 'Loading uploads', height: 72),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// One upload: icon, file name, date, status chip, linked topic tag, and a
/// progress bar while sending.
class UploadTile extends ConsumerWidget {
  const UploadTile({super.key, required this.upload});

  final Upload upload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final local = upload.id.startsWith('local-');
    final date = upload.createdAt == null
        ? null
        : Formatters.shortDate(upload.createdAt!);

    return LearnCard(
      onTap: local
          ? null
          : () => context.push(AppRoutes.uploadDetailPath(upload.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(uploadFileIcon(upload.fileName), color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upload.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: context.learnInk,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        UploadStatusChip(status: upload.status),
                        if (date != null)
                          Text(
                            date,
                            style: textTheme.bodySmall?.copyWith(
                              color: context.learnMuted,
                            ),
                          ),
                        if (upload.topic != null &&
                            upload.topic!.title.isNotEmpty)
                          SyllabusTag(text: upload.topic!.title),
                      ],
                    ),
                  ],
                ),
              ),
              if (upload.status == UploadStatus.failed && local)
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close),
                  onPressed: () => ref
                      .read(uploadsControllerProvider.notifier)
                      .delete(upload.id),
                )
              else if (!local)
                Icon(Icons.chevron_right, color: context.learnMuted),
            ],
          ),
          if (upload.status == UploadStatus.uploading) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: 'Uploading, ${Formatters.percent(upload.sendProgress)}',
              child: ProgressBar(
                value: upload.sendProgress,
                width: null,
                color: AppColors.primary,
              ),
            ),
          ] else if (upload.status.isBusy) ...[
            const SizedBox(height: AppSpacing.md),
            const ClipRRect(
              borderRadius: BorderRadius.all(
                Radius.circular(AppSpacing.radiusPill),
              ),
              child: LinearProgressIndicator(
                minHeight: 5,
                color: AppColors.secondary,
              ),
            ),
          ],
          if (upload.status == UploadStatus.failed && upload.error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              upload.error!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.errorDark),
            ),
          ],
        ],
      ),
    );
  }
}

/// Uploading / Processing / Ready / Failed (colour + icon + label).
class UploadStatusChip extends StatelessWidget {
  const UploadStatusChip({super.key, required this.status});

  final UploadStatus status;

  @override
  Widget build(BuildContext context) {
    final style = switch (status) {
      UploadStatus.uploading => const StatusStyle(
        'Uploading',
        Icons.cloud_upload_outlined,
        AppColors.primarySoft,
        AppColors.primaryDark,
      ),
      UploadStatus.queued || UploadStatus.processing => const StatusStyle(
        'Processing',
        Icons.hourglass_top,
        AppColors.streakSoft,
        AppColors.streakDark,
      ),
      UploadStatus.done => const StatusStyle(
        'Ready',
        Icons.check_circle_outline,
        AppColors.successSoft,
        AppColors.successDark,
      ),
      UploadStatus.failed => const StatusStyle(
        'Failed',
        Icons.error_outline,
        AppColors.errorSoft,
        AppColors.errorDark,
      ),
    };
    return StatusPill(style: style);
  }
}
