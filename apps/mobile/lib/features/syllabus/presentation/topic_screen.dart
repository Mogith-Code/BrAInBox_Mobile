import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/topic_controller.dart';
import '../domain/syllabus_models.dart';
import 'topic_tabs.dart';
import 'widgets/ask_brainbox_button.dart';
import 'widgets/status_pill.dart';

/// Topic screen (Figma B4) - breadcrumb, title and the topic tabs.
///
/// Routes (inside the Learn tab): `/learn/unit/:unitId/topic/:topicId`,
/// and `/learn/topic/:topicId` when only the topic id is known.
/// The tab bodies come from other features (see `topic_tabs.dart`).
class TopicScreen extends ConsumerWidget {
  const TopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(topicControllerProvider(topicId));

    return switch (state) {
      AsyncData(:final value) => _TopicShell(detail: value),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(leading: const _BackButton()),
        body: Center(
          child: ErrorBanner(
            message: ErrorMessages.of(error),
            onRetry: () => ref.invalidate(topicControllerProvider(topicId)),
          ),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(leading: const _BackButton()),
        body: const Center(child: CircularProgressIndicator()),
      ),
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

  void _onTabChanged() {
    // Rebuild once the tab settles, to show / hide the Ask button.
    if (!_tabs.indexIsChanging) setState(() {});
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
      backgroundColor: AppColors.background,
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
                  const _BackButton(),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Biology › Unit ${detail.unit.order} › ${topic.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        topic.title,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs + 2),
                    child: StatusPill.topic(topic.status),
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
              unselectedLabelColor: AppColors.muted,
              labelStyle: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: AppColors.primary,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: AppColors.border,
              tabs: [for (final tab in TopicTab.values) Tab(text: tab.label)],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  for (final tab in TopicTab.values)
                    TopicTabBody(tab: tab, detail: detail),
                ],
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

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return SoftIconButton(
      tooltip: 'Back',
      icon: Icons.arrow_back,
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.learn),
    );
  }
}
