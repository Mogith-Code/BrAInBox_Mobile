import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/community_models.dart';

/// The topic tag of a post ("Mendelian genetics").
class TopicTag extends StatelessWidget {
  const TopicTag({super.key, required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) =>
      AppChip(icon: Icons.sell_outlined, label: topic);
}

/// Up / down votes with the score between them. Buttons are 48 px.
///
/// [enabled] is false on my own post or reply (the backend refuses those
/// votes). Tapping my current vote again removes it.
class VoteBar extends StatelessWidget {
  const VoteBar({
    super.key,
    required this.score,
    required this.myVote,
    required this.onVote,
    this.enabled = true,
  });

  final int score;
  final int myVote;
  final ValueChanged<int> onVote;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: myVote == 1 ? 'Remove upvote' : 'Upvote',
          isSelected: myVote == 1,
          onPressed: enabled ? () => onVote(myVote == 1 ? 0 : 1) : null,
          icon: Icon(Icons.arrow_upward_rounded, color: muted),
          selectedIcon: const Icon(
            Icons.arrow_upward_rounded,
            color: AppColors.primary,
          ),
        ),
        Semantics(
          label: 'Score $score',
          excludeSemantics: true,
          child: Text(
            '$score',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: myVote == -1 ? 'Remove downvote' : 'Downvote',
          isSelected: myVote == -1,
          onPressed: enabled ? () => onVote(myVote == -1 ? 0 : -1) : null,
          icon: Icon(Icons.arrow_downward_rounded, color: muted),
          selectedIcon: const Icon(
            Icons.arrow_downward_rounded,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}

/// "Waiting for an admin" / "Hidden by a moderator" on my own content that
/// is not public. Icon + word + colour. Nothing for approved content.
class ModerationNote extends StatelessWidget {
  const ModerationNote({super.key, required this.status});

  final ModerationStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, text, background, foreground) = switch (status) {
      ModerationStatus.approved => (null, '', null, null),
      ModerationStatus.pending => (
        Icons.hourglass_top_rounded,
        'Checking - only you can see this for now.',
        AppColors.surfaceMuted,
        AppColors.muted,
      ),
      ModerationStatus.flagged => (
        Icons.flag_outlined,
        'Waiting for an admin to check it - only you can see it.',
        AppColors.warningSoft,
        AppColors.warningDark,
      ),
      ModerationStatus.removed => (
        Icons.block_rounded,
        'Removed by a moderator.',
        AppColors.errorSoft,
        AppColors.error,
      ),
    };
    if (icon == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Name · 2h ago". Only the display name, never an email.
String byline(Author? author, DateTime? createdAt, {String? fallback}) => [
  author?.name ?? fallback ?? 'Deleted account',
  if (createdAt != null) Formatters.relativeTime(createdAt),
].join(' · ');

/// A post in a group feed.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  if (post.acceptedReplyId != null)
                    const AppChip(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Answered',
                      tone: AppChipTone.success,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(post.title, style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                post.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              if (post.isMine &&
                  post.moderationStatus != ModerationStatus.approved) ...[
                const SizedBox(height: AppSpacing.sm),
                ModerationNote(status: post.moderationStatus),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Semantics(
                    label: 'Score ${post.score}',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 2),
                        Text('${post.score}', style: textTheme.labelLarge),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Semantics(
                    label:
                        '${post.replyCount} '
                        '${post.replyCount == 1 ? 'reply' : 'replies'}',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text('${post.replyCount}', style: textTheme.labelLarge),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      byline(post.author, post.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks why the content is reported. Returns null when cancelled.
Future<({ReportReason reason, String? details})?> showReportSheet(
  BuildContext context, {
  required String what,
}) => showModalBottomSheet<({ReportReason reason, String? details})>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _ReportSheet(what: what),
);

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.what});

  final String what;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Report this ${widget.what}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                children: [
                  for (final reason in ReportReason.values)
                    RadioListTile<ReportReason>(
                      value: reason,
                      title: Text(reason.label),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            AppTextField(
              label: 'Details (optional)',
              controller: _details,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Send report',
              icon: Icons.flag_outlined,
              onPressed: _reason == null
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop((reason: _reason!, details: _details.text)),
            ),
          ],
        ),
      ),
    );
  }
}
