import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notes/presentation/official_notes_view.dart'
    show NotesZoomNotification;
import '../application/topic_controller.dart';
import '../domain/syllabus_models.dart';
import 'topic_tabs.dart';
import 'unit_detail_screen.dart' show LearnBackButton;
import 'widgets/ask_brainbox_button.dart';
import 'widgets/learn_widgets.dart';

/// Topic screen: breadcrumb, bookmark, title + mastery chip and the tabs
/// Notes · Short Notes · Diagrams · Videos · Practice.
///
/// Routes (inside the Learn tab): `/learn/unit/:unitId/topic/:topicId`,
/// and `/learn/topic/:topicId` when only the topic id is known.
/// Opening it marks the topic "in progress" and tells the progress API.
class TopicScreen extends ConsumerWidget {
  const TopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(topicControllerProvider(topicId));

    return switch (state) {
      AsyncValue(:final value?) => _TopicShell(detail: value),
      AsyncError(:final error) => Scaffold(
        backgroundColor: context.learnBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: LearnBackButton(onDark: false),
              ),
              Expanded(
                child: ErrorCard(
                  error: error,
                  onRetry: () =>
                      ref.invalidate(topicControllerProvider(topicId)),
                ),
              ),
            ],
          ),
        ),
      ),
      _ => const _TopicSkeleton(),
    };
  }
}

class _TopicShell extends ConsumerStatefulWidget {
  const _TopicShell({required this.detail});

  final TopicDetail detail;

  @override
  ConsumerState<_TopicShell> createState() => _TopicShellState();
}

class _TopicShellState extends ConsumerState<_TopicShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: TopicTab.values.length,
    vsync: this,
  )..addListener(_onTabChanged);

  TopicTab get _tab => TopicTab.values[_tabs.index];

  @override
  void initState() {
    super.initState();
    // Mark the topic opened once the first frame is up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(topicControllerProvider(widget.detail.topic.id).notifier)
          .markOpened();
    });
  }

  /// True while the student pinches or is zoomed into a government notes
  /// page, so a sideways finger move pans the page instead of changing tab.
  bool _swipeLocked = false;

  void _onTabChanged() {
    // Rebuild once the tab settles, to show / hide the Ask button.
    if (!_tabs.indexIsChanging) {
      setState(() => _swipeLocked = false);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _toggleSaved() async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(
      topicControllerProvider(widget.detail.topic.id).notifier,
    );
    try {
      final saved = await controller.toggleSaved();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              saved ? 'Saved to My library' : 'Removed from My library',
            ),
          ),
        );
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ErrorMessages.of(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detail = widget.detail;
    final topic = detail.topic;

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
                0,
              ),
              child: Row(
                children: [
                  const LearnBackButton(onDark: false),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      detail.breadcrumbText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: context.learnMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SoftIconButton(
                    tooltip: detail.saved
                        ? 'Remove from My library'
                        : 'Save to My library',
                    icon: Icons.bookmark_border,
                    selectedIcon: Icons.bookmark,
                    isSelected: detail.saved,
                    onPressed: _toggleSaved,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      topic.title,
                      style: textTheme.headlineSmall?.copyWith(
                        color: context.learnInk,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      MasteryChip(level: detail.masteryLevel),
                      if (detail.isOutdated)
                        OutdatedSyllabusTag(version: detail.syllabusVersion),
                    ],
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              labelColor: AppColors.primary,
              unselectedLabelColor: context.learnMuted,
              labelStyle: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: AppColors.primary,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: context.learnBorder,
              tabs: [for (final tab in TopicTab.values) Tab(text: tab.label)],
            ),
            Expanded(
              child: NotificationListener<NotesZoomNotification>(
                onNotification: (zoom) {
                  setState(() => _swipeLocked = zoom.active);
                  return true;
                },
                child: TabBarView(
                  controller: _tabs,
                  physics: _swipeLocked
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  children: [
                    for (final tab in TopicTab.values)
                      TopicTabBody(tab: tab, detail: detail),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tab.showsAskButton
          ? AskBrainBoxButton(topicId: topic.id)
          : null,
    );
  }
}

class _TopicSkeleton extends StatelessWidget {
  const _TopicSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.learnBackground,
      body: SafeArea(
        child: Semantics(
          label: 'Loading topic',
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LearnBackButton(onDark: false),
                SizedBox(height: AppSpacing.lg),
                SkeletonBox(height: 28, width: 240),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(
                  height: 20,
                  width: 90,
                  radius: AppSpacing.radiusPill,
                ),
                SizedBox(height: AppSpacing.xl),
                SkeletonBox(height: 32),
                SizedBox(height: AppSpacing.lg),
                SkeletonCard(height: 120, lines: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
