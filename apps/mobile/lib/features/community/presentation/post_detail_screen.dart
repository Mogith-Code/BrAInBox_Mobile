import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/community_controller.dart';
import '../domain/community_models.dart';
import 'widgets/community_widgets.dart';

/// A post with its replies: the AI-suggested answer first, then the accepted
/// answer, then the rest by score. Votes, reply, best answer, report, and
/// edit / delete for my own content. Pull down to refresh (the AI answer
/// arrives a few seconds after a question is posted).
///
/// Route: `/community/posts/:postId`
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _reply = TextEditingController();
  bool _sending = false;

  PostDetailController get _controller =>
      ref.read(postDetailProvider(widget.postId).notifier);

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _show(String? message) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendReply() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final error = await _controller.reply(text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error == null) {
      _reply.clear();
      FocusScope.of(context).unfocus();
    }
    _show(error);
  }

  Future<void> _report({Reply? reply}) async {
    final answer = await showReportSheet(
      context,
      what: reply == null ? 'post' : 'reply',
    );
    if (answer == null) return;
    final error = await _controller.report(
      reply: reply,
      reason: answer.reason,
      details: answer.details,
    );
    _show(error ?? 'Thanks. A moderator will check it.');
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _editPost(Post post) async {
    final result = await showDialog<({String title, String body})>(
      context: context,
      builder: (_) =>
          _EditDialog(heading: 'Edit post', title: post.title, body: post.body),
    );
    if (result == null) return;
    _show(await _controller.editPost(title: result.title, body: result.body));
  }

  Future<void> _deletePost() async {
    if (!await _confirm('Delete post?', 'Nobody will see it any more.')) {
      return;
    }
    final error = await _controller.deletePost();
    if (error != null) {
      _show(error);
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _editReply(Reply reply) async {
    final result = await showDialog<({String title, String body})>(
      context: context,
      builder: (_) => _EditDialog(heading: 'Edit reply', body: reply.body),
    );
    if (result == null) return;
    _show(await _controller.editReply(reply, result.body));
  }

  Future<void> _deleteReply(Reply reply) async {
    if (await _confirm('Delete reply?', 'Nobody will see it any more.')) {
      _show(await _controller.deleteReply(reply));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailProvider(widget.postId));
    final detail = state.value;
    final post = detail?.post;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          if (post != null)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (value) => switch (value) {
                'edit' => _editPost(post),
                'delete' => _deletePost(),
                _ => _report(),
              },
              itemBuilder: (_) => post.isMine
                  ? const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ]
                  : const [
                      PopupMenuItem(value: 'report', child: Text('Report')),
                    ],
            ),
        ],
      ),
      bottomNavigationBar: detail == null
          ? null
          : _ReplyBox(
              controller: _reply,
              sending: _sending,
              onSend: _sendReply,
            ),
      body: RefreshIndicator(
        onRefresh: _controller.refresh,
        child: switch (state) {
          AsyncValue(value: final d?) => _PostBody(
            detail: d,
            onVotePost: (v) async => _show(await _controller.vote(value: v)),
            onVoteReply: (r, v) async =>
                _show(await _controller.vote(reply: r, value: v)),
            onToggleAccepted: (r) async =>
                _show(await _controller.toggleAccepted(r)),
            onEditReply: _editReply,
            onDeleteReply: _deleteReply,
            onReportReply: (r) => _report(reply: r),
          ),
          AsyncValue(:final error?) => ListView(
            padding: AppSpacing.screenPadding,
            children: [
              ErrorBanner(
                message: communityErrorMessage(error),
                onRetry: _controller.refresh,
              ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _PostBody extends StatelessWidget {
  const _PostBody({
    required this.detail,
    required this.onVotePost,
    required this.onVoteReply,
    required this.onToggleAccepted,
    required this.onEditReply,
    required this.onDeleteReply,
    required this.onReportReply,
  });

  final PostDetail detail;
  final ValueChanged<int> onVotePost;
  final void Function(Reply reply, int value) onVoteReply;
  final ValueChanged<Reply> onToggleAccepted;
  final ValueChanged<Reply> onEditReply;
  final ValueChanged<Reply> onDeleteReply;
  final ValueChanged<Reply> onReportReply;

  @override
  Widget build(BuildContext context) {
    final post = detail.post;
    final replies = detail.orderedReplies;
    final textTheme = Theme.of(context).textTheme;
    final hasAi = replies.any((r) => r.isAiSuggested);
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            if (post.topic != null) TopicTag(topic: post.topic!),
            if (post.isQuestion)
              const AppChip(
                icon: Icons.help_outline_rounded,
                label: 'Question',
                tone: AppChipTone.neutral,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(post.title, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          byline(post.author, post.createdAt),
          style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        if (post.isMine && post.moderationStatus != ModerationStatus.approved)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: ModerationNote(status: post.moderationStatus),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(post.body, style: textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: VoteBar(
            score: post.score,
            myVote: post.myVote,
            enabled: !post.isMine,
            onVote: onVotePost,
          ),
        ),
        const Divider(height: AppSpacing.xl),
        Semantics(
          header: true,
          child: Text(
            '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
            style: textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (post.isQuestion && !hasAi)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'An AI-suggested answer usually arrives within a few seconds. '
              'Pull down to refresh.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ),
        if (replies.isEmpty)
          Text(
            'No replies yet. Be the first to help.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        for (final reply in replies)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ReplyCard(
              reply: reply,
              canAccept: post.isMine,
              onVote: (v) => onVoteReply(reply, v),
              onToggleAccepted: () => onToggleAccepted(reply),
              onEdit: () => onEditReply(reply),
              onDelete: () => onDeleteReply(reply),
              onReport: () => onReportReply(reply),
            ),
          ),
      ],
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({
    required this.reply,
    required this.canAccept,
    required this.onVote,
    required this.onToggleAccepted,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
  });

  final Reply reply;

  /// I wrote the post, so I can mark the best answer.
  final bool canAccept;
  final ValueChanged<int> onVote;
  final VoidCallback onToggleAccepted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ai = reply.isAiSuggested;
    return Card(
      margin: EdgeInsets.zero,
      color: reply.isAccepted ? AppColors.successSoft : null,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        byline(
                          reply.author,
                          reply.createdAt,
                          fallback: ai ? 'BrAInBox AI' : null,
                        ),
                        style: textTheme.labelLarge,
                      ),
                      if (ai) const AiBadge(label: 'AI-suggested answer'),
                      if (reply.isAccepted)
                        const AppChip(
                          icon: Icons.check_circle_rounded,
                          label: 'Best answer',
                          tone: AppChipTone.success,
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Reply options',
                  onSelected: (value) => switch (value) {
                    'accept' => onToggleAccepted(),
                    'edit' => onEdit(),
                    'delete' => onDelete(),
                    _ => onReport(),
                  },
                  itemBuilder: (_) => [
                    if (canAccept)
                      PopupMenuItem(
                        value: 'accept',
                        child: Text(
                          reply.isAccepted
                              ? 'Unmark best answer'
                              : 'Mark as best answer',
                        ),
                      ),
                    if (reply.isMine) ...const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ] else
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('Report'),
                      ),
                  ],
                ),
              ],
            ),
            if (reply.isMine &&
                reply.moderationStatus != ModerationStatus.approved)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ModerationNote(status: reply.moderationStatus),
              ),
            Text(reply.body, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            if (ai)
              _HelpfulButtons(myVote: reply.myVote, onVote: onVote)
            else
              VoteBar(
                score: reply.score,
                myVote: reply.myVote,
                enabled: !reply.isMine,
                onVote: onVote,
              ),
          ],
        ),
      ),
    );
  }
}

/// "Helpful" / "Not helpful" on the AI answer: an up / down vote. Tapping
/// the chosen one again removes the vote.
class _HelpfulButtons extends StatelessWidget {
  const _HelpfulButtons({required this.myVote, required this.onVote});

  final int myVote;
  final ValueChanged<int> onVote;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Was this helpful?', style: Theme.of(context).textTheme.bodySmall),
        ChoiceChip(
          avatar: const Icon(Icons.thumb_up_alt_outlined, size: 18),
          label: const Text('Helpful'),
          selected: myVote == 1,
          showCheckmark: false,
          onSelected: (_) => onVote(myVote == 1 ? 0 : 1),
        ),
        ChoiceChip(
          avatar: const Icon(Icons.thumb_down_alt_outlined, size: 18),
          label: const Text('Not helpful'),
          selected: myVote == -1,
          showCheckmark: false,
          onSelected: (_) => onVote(myVote == -1 ? 0 : -1),
        ),
      ],
    );
  }
}

class _ReplyBox extends StatelessWidget {
  const _ReplyBox({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        elevation: 4,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Write a reply...',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Send reply',
                  onPressed: sending ? null : onSend,
                  icon: sending
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Edit a post (title + body) or a reply (body only, [title] null).
class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.heading, required this.body, this.title});

  final String heading;
  final String? title;
  final String body;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _title = TextEditingController(text: widget.title);
  late final _body = TextEditingController(text: widget.body);

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.heading),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null) ...[
              AppTextField(label: 'Title', controller: _title),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(label: 'Text', controller: _body, maxLines: 5),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final title = _title.text.trim();
            final body = _body.text.trim();
            if (body.isEmpty || (widget.title != null && title.length < 3)) {
              return;
            }
            Navigator.of(context).pop((title: title, body: body));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
