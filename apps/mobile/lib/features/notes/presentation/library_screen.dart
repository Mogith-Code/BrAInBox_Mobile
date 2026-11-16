import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../syllabus/domain/learn_models.dart';
import '../../syllabus/presentation/unit_detail_screen.dart' show LearnBackButton;
import '../../syllabus/presentation/widgets/learn_widgets.dart';
import '../application/library_controller.dart';

/// My library: bookmarked topics and saved short notes.
///
/// Route: `/learn/library` (inside the Learn tab). Tap opens the topic (or
/// the upload a short note came from); swipe left or the bookmark icon
/// removes a topic bookmark.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, Bookmark b) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bookmarksControllerProvider.notifier).remove(b);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Removed "${b.topicTitle}"')));
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ErrorMessages.of(error))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookmarksControllerProvider);
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
                  Semantics(
                    header: true,
                    child: Text(
                      'My library',
                      style: textTheme.titleLarge?.copyWith(color: context.learnInk),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (state) {
                AsyncValue(:final value?) => RefreshIndicator(
                  onRefresh: ref.read(bookmarksControllerProvider.notifier).refresh,
                  child: value.isEmpty
                      ? const _Empty()
                      : _List(
                          bookmarks: value,
                          onRemove: (b) => _remove(context, ref, b),
                        ),
                ),
                AsyncError(:final error) => ErrorCard(
                  error: error,
                  onRetry: () => ref.invalidate(bookmarksControllerProvider),
                ),
                _ => const SkeletonList(label: 'Loading library', height: 68),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: c.maxHeight,
          child: const LearnEmptyState(
            icon: Icons.bookmark_border,
            title: 'Nothing saved yet',
            message: 'Tap the bookmark on a topic to keep it here.',
          ),
        ),
      ],
    ),
  );
}

class _List extends StatelessWidget {
  const _List({required this.bookmarks, required this.onRemove});

  final List<Bookmark> bookmarks;
  final ValueChanged<Bookmark> onRemove;

  @override
  Widget build(BuildContext context) {
    final topics = bookmarks.where((b) => b.kind == BookmarkKind.topic).toList();
    final notes = bookmarks.where((b) => b.kind == BookmarkKind.shortNote).toList();
    final textTheme = Theme.of(context).textTheme;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
      child: Text(title, style: textTheme.titleSmall?.copyWith(color: context.learnMuted)),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      children: [
        if (topics.isNotEmpty) section('Topics'),
        for (final b in topics) ...[
          Dismissible(
            key: ValueKey('bm-${b.topicId}'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => onRemove(b),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(LearnStyle.cardRadius),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_remove_outlined, color: AppColors.errorDark),
                  SizedBox(width: AppSpacing.xs),
                  Text('Remove', style: TextStyle(color: AppColors.errorDark)),
                ],
              ),
            ),
            child: LearnCard(
              onTap: () => context.push(AppRoutes.topicPath(b.topicId)),
              child: Row(
                children: [
                  const Icon(Icons.bookmark, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.topicTitle,
                          style: textTheme.titleSmall?.copyWith(color: context.learnInk),
                        ),
                        if (b.unitTitle.isNotEmpty)
                          Text(
                            'Unit ${b.unitOrder} · ${b.unitTitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(color: context.learnMuted),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove bookmark',
                    icon: const Icon(Icons.bookmark_remove_outlined),
                    color: context.learnMuted,
                    onPressed: () => onRemove(b),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (notes.isNotEmpty) section('Saved short notes'),
        for (final b in notes) ...[
          LearnCard(
            onTap: b.uploadId != null
                ? () => context.push(AppRoutes.uploadDetailPath(b.uploadId!))
                : b.topicId.isNotEmpty
                ? () => context.push(AppRoutes.topicPath(b.topicId))
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sticky_note_2_outlined, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.title ?? b.topicTitle,
                        style: textTheme.titleSmall?.copyWith(color: context.learnInk),
                      ),
                      if (b.preview != null)
                        Text(
                          b.preview!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(color: context.learnMuted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
