import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/community_controller.dart';
import '../domain/community_models.dart';
import 'widgets/community_widgets.dart';

/// A study group's posts: Latest / Unanswered / Top, paged.
///
/// Route: `/community/groups/:groupId`
class GroupFeedScreen extends ConsumerStatefulWidget {
  const GroupFeedScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupFeedScreen> createState() => _GroupFeedScreenState();
}

class _GroupFeedScreenState extends ConsumerState<GroupFeedScreen> {
  FeedSort _sort = FeedSort.latest;
  bool _joining = false;

  FeedArgs get _args => (groupId: widget.groupId, sort: _sort);

  Future<void> _refresh() async {
    ref.invalidate(groupProvider(widget.groupId));
    await ref.read(feedProvider(_args).notifier).refresh();
  }

  /// Opens a page and refreshes the feed when the student comes back (they
  /// may have posted, replied or voted).
  Future<void> _openAndRefresh(String location) async {
    await context.push(location);
    if (mounted) await _refresh();
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    final error = await joinGroup(ref, widget.groupId);
    if (!mounted) return;
    setState(() => _joining = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final feed = ref.watch(feedProvider(_args));
    final isMember = group?.isMember ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(group?.name ?? 'Study group')),
      floatingActionButton: isMember
          ? FloatingActionButton.extended(
              onPressed: () => _openAndRefresh(
                AppRoutes.createPostPath(group?.id ?? widget.groupId),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('New post'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<FeedSort>(
                segments: [
                  for (final sort in FeedSort.values)
                    ButtonSegment(value: sort, label: Text(sort.label)),
                ],
                selected: {_sort},
                showSelectedIcon: false,
                onSelectionChanged: (value) =>
                    setState(() => _sort = value.first),
              ),
            ),
          ),
          if (group != null && !isMember)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Join this group to post and reply.'),
                      ),
                      AppButton(
                        label: 'Join',
                        expand: false,
                        isLoading: _joining,
                        onPressed: _joining ? null : _join,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: switch (feed) {
                AsyncValue(value: final state?) => _FeedList(
                  state: state,
                  onOpen: (post) =>
                      _openAndRefresh(AppRoutes.postDetailPath(post.id)),
                  onLoadMore: () =>
                      ref.read(feedProvider(_args).notifier).loadMore(),
                ),
                AsyncValue(:final error?) => ListView(
                  padding: AppSpacing.screenPadding,
                  children: [
                    ErrorBanner(
                      message: communityErrorMessage(error),
                      onRetry: _refresh,
                    ),
                  ],
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({
    required this.state,
    required this.onOpen,
    required this.onLoadMore,
  });

  final FeedState state;
  final ValueChanged<Post> onOpen;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final posts = state.visible;
    if (posts.isEmpty && !state.hasMore) {
      return ListView(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          EmptyState(
            icon: Icons.forum_outlined,
            title: state.sort == FeedSort.unanswered
                ? 'Every question has a reply'
                : 'No posts yet',
            message: state.sort == FeedSort.unanswered
                ? 'Nice work, group! Check Latest for new posts.'
                : 'Be the first to ask a question in this group.',
          ),
        ],
      );
    }
    // One extra row at the end: the loader / "Load more" / error.
    final footer = state.hasMore || state.loadMoreError != null;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 400 && state.hasMore) onLoadMore();
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          96, // room for the New post button
        ),
        itemCount: posts.length + (footer ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index < posts.length) {
            final post = posts[index];
            return PostCard(post: post, onTap: () => onOpen(post));
          }
          if (state.loadMoreError != null) {
            return ErrorBanner(
              message: state.loadMoreError!,
              onRetry: onLoadMore,
            );
          }
          return Center(
            child: state.loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    onPressed: onLoadMore,
                    child: const Text('Load more'),
                  ),
          );
        },
      ),
    );
  }
}
