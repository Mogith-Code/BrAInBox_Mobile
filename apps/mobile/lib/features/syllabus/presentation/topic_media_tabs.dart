import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../application/topic_media_controller.dart';
import '../domain/learn_models.dart';
import '../domain/syllabus_models.dart';
import 'widgets/learn_widgets.dart';
import 'widgets/media_cards.dart';
import 'zoom_image_screen.dart';

/// Grid of stored diagrams. Tap = full-screen zoom.
class DiagramsTab extends ConsumerWidget {
  const DiagramsTab({super.key, required this.detail});

  final TopicDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = topicDiagramsProvider(detail.topic.id);
    return _AsyncTab<List<Diagram>>(
      value: ref.watch(provider),
      onRefresh: () => ref.refresh(provider.future),
      onRetry: () => ref.invalidate(provider),
      skeleton: const _GridSkeleton(),
      builder: (diagrams) {
        if (diagrams.isEmpty) {
          return const LearnEmptyState(
            icon: Icons.image_outlined,
            title: 'No diagrams yet',
            message: 'Diagrams for this topic will show up here.',
          );
        }
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.8,
          ),
          itemCount: diagrams.length,
          itemBuilder: (context, i) {
            final d = diagrams[i];
            return DiagramTile(
              diagram: d,
              onTap: () => ZoomImageScreen.open(
                context,
                url: d.imageUrl,
                caption: d.caption,
                heroTag: 'diagram-${d.id}',
              ),
            );
          },
        );
      },
    );
  }
}

/// Video cards; tap opens the video.
class VideosTab extends ConsumerWidget {
  const VideosTab({super.key, required this.detail});

  final TopicDetail detail;

  Future<void> _open(BuildContext context, Video video) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(video.url);
    final ok =
        uri != null &&
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        ).catchError((Object _) => false);
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Couldn't open this video.")),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = topicVideosProvider(detail.topic.id);
    return _AsyncTab<List<Video>>(
      value: ref.watch(provider),
      onRefresh: () => ref.refresh(provider.future),
      onRetry: () => ref.invalidate(provider),
      skeleton: const SkeletonList(
        count: 2,
        height: 220,
        label: 'Loading videos',
        padding: EdgeInsets.all(AppSpacing.lg),
      ),
      builder: (videos) {
        if (videos.isEmpty) {
          return const LearnEmptyState(
            icon: Icons.ondemand_video_outlined,
            title: 'No videos yet',
            message: 'Video lessons for this topic will show up here.',
          );
        }
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: videos.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) => VideoCard(
            video: videos[i],
            syllabusTag: detail.syllabusTagText,
            onTap: () => _open(context, videos[i]),
          ),
        );
      },
    );
  }
}

/// Questions available, accuracy, last attempt; Quick 10 MCQs / Weak
/// areas only open Practice with this topic.
class PracticeTab extends ConsumerWidget {
  const PracticeTab({super.key, required this.detail});

  final TopicDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = topicPracticeSummaryProvider(detail.topic.id);
    final textTheme = Theme.of(context).textTheme;
    final topicId = detail.topic.id;

    return _AsyncTab<PracticeSummary>(
      value: ref.watch(provider),
      onRefresh: () => ref.refresh(provider.future),
      onRetry: () => ref.invalidate(provider),
      skeleton: const SkeletonList(
        count: 2,
        height: 120,
        label: 'Loading practice',
        padding: EdgeInsets.all(AppSpacing.lg),
      ),
      builder: (summary) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          LearnCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice this topic',
                  style: textTheme.titleMedium?.copyWith(
                    color: context.learnInk,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    _Stat(
                      icon: Icons.quiz_outlined,
                      value: '${summary.questionCount}',
                      label: 'Questions',
                    ),
                    _Stat(
                      icon: Icons.track_changes,
                      value: summary.accuracyPercent == null
                          ? '–'
                          : '${summary.accuracyPercent!.round()}%',
                      label: 'Your accuracy',
                    ),
                    _Stat(
                      icon: Icons.history,
                      value: summary.lastAttemptAt == null
                          ? 'Never'
                          : Formatters.relativeTime(summary.lastAttemptAt!),
                      label: 'Last attempt',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: summary.questionCount == 0
                ? null
                : () => context.push(
                    AppRoutes.quizSetupPath(topicId: topicId, mode: 'quick'),
                  ),
            icon: const Icon(Icons.bolt),
            label: const Text('Quick 10 MCQs'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LearnStyle.buttonRadius),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: summary.questionCount == 0
                ? null
                : () => context.push(
                    AppRoutes.quizSetupPath(topicId: topicId, mode: 'weak'),
                  ),
            icon: const Icon(Icons.warning_amber_rounded),
            label: const Text('Weak areas only'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LearnStyle.buttonRadius),
              ),
            ),
          ),
          if (summary.questionCount == 0) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'No questions for this topic yet.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: context.learnMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Semantics(
        label: '$label: $value',
        child: ExcludeSemantics(
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(color: context.learnInk),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: context.learnMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton / error card with Retry / pull-to-refresh content.
class _AsyncTab<T> extends StatelessWidget {
  const _AsyncTab({
    required this.value,
    required this.onRefresh,
    required this.onRetry,
    required this.skeleton,
    required this.builder,
  });

  final AsyncValue<T> value;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final Widget skeleton;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncValue(hasValue: true, :final value) => RefreshIndicator(
        onRefresh: onRefresh,
        child: builder(value as T),
      ),
      AsyncError(:final error) => ErrorCard(error: error, onRetry: onRetry),
      _ => skeleton,
    };
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading diagrams',
      child: ExcludeSemantics(
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.8,
          children: [
            for (var i = 0; i < 4; i++)
              const SkeletonBox(
                height: double.infinity,
                radius: LearnStyle.cardRadius,
              ),
          ],
        ),
      ),
    );
  }
}
