import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/community_controller.dart';
import '../domain/community_models.dart';

/// Create a post in a study group. While the student writes, the AI suggests
/// a topic tag (debounced); they can change or remove it before posting.
///
/// Route: `/community/create?groupId=` (without `groupId`, the student picks
/// one of their groups).
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key, this.groupId});

  final String? groupId;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _isQuestion = true;
  String? _pickedGroupId;
  String? _titleError;
  String? _bodyError;

  String? get _groupId => widget.groupId ?? _pickedGroupId;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _draftChanged() {
    ref
        .read(createPostProvider.notifier)
        .draftChanged(title: _title.text, body: _body.text, groupId: _groupId);
  }

  Future<void> _pickTopic(int unitNumber) async {
    final option = await showModalBottomSheet<TopicOption>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _TopicPicker(unitNumber: unitNumber),
    );
    if (option != null) {
      ref.read(createPostProvider.notifier).chooseTopic(option);
    }
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    setState(() {
      _titleError = title.length < 3 ? 'Write a title (3+ characters).' : null;
      _bodyError = body.isEmpty ? 'Write your post.' : null;
    });
    final groupId = _groupId;
    if (_titleError != null || _bodyError != null || groupId == null) return;

    final post = await ref
        .read(createPostProvider.notifier)
        .submit(
          groupId: groupId,
          title: title,
          body: body,
          isQuestion: _isQuestion,
        );
    if (post == null || !mounted) return;
    if (post.moderationStatus == ModerationStatus.flagged) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.flag_outlined, color: AppColors.warningDark),
          title: const Text('Waiting for an admin'),
          content: const Text(
            'Your post was sent, but it needs an admin to check it before '
            'others can see it. Until then, only you can see it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Posted')));
    }
    if (mounted) Navigator.of(context).pop(post);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createPostProvider);
    final groupId = _groupId;
    final group = groupId == null
        ? null
        : ref.watch(groupProvider(groupId)).value;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('New post')),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          if (widget.groupId == null) ...[
            _GroupPicker(
              selected: _pickedGroupId,
              onChanged: (id) {
                setState(() => _pickedGroupId = id);
                _draftChanged();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ] else if (group != null) ...[
            Text(
              'Posting in ${group.name}',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppTextField(
            label: 'Title',
            controller: _title,
            hint: 'e.g. Why is the F2 ratio 9:3:3:1?',
            errorText: _titleError,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _draftChanged(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Your post',
            controller: _body,
            hint: 'Explain what you tried and where you got stuck.',
            errorText: _bodyError,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => _draftChanged(),
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            value: _isQuestion,
            onChanged: (v) => setState(() => _isQuestion = v),
            title: const Text('This is a question'),
            subtitle: const Text('Questions get an AI-suggested answer too.'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          _TopicArea(
            state: state,
            onPick: group?.unitNumber == null
                ? null
                : () => _pickTopic(group!.unitNumber!),
            onRemove: () => ref.read(createPostProvider.notifier).removeTopic(),
          ),
          if (state.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            ErrorBanner(message: state.error!),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Post',
            icon: Icons.send_rounded,
            isLoading: state.submitting,
            onPressed: state.submitting || groupId == null ? null : _submit,
          ),
        ],
      ),
    );
  }
}

/// The topic tag: the AI's suggestion (with AiBadge), the student's own
/// pick, or nothing.
class _TopicArea extends StatelessWidget {
  const _TopicArea({
    required this.state,
    required this.onPick,
    required this.onRemove,
  });

  final CreatePostState state;

  /// Null when the group has no unit (no topic list to pick from).
  final VoidCallback? onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.muted);
    final topic = state.topic;
    if (topic == null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              state.suggesting
                  ? 'Suggesting a topic tag...'
                  : state.suggestion != null && !state.topicRemoved
                  ? 'No topic fits yet - you can pick one.'
                  : 'Topic tag (optional)',
              style: muted,
            ),
          ),
          if (onPick != null)
            TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.sell_outlined),
              label: const Text('Pick a topic'),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Topic tag', style: muted),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InputChip(
              avatar: const Icon(Icons.sell_outlined, size: 18),
              label: Text(topic),
              onPressed: onPick,
              onDeleted: onRemove,
              deleteButtonTooltipMessage: 'Remove topic',
            ),
            if (state.topicFromAi) const AiBadge(label: 'AI-suggested'),
          ],
        ),
        if (onPick != null) Text('Tap the tag to change it.', style: muted),
      ],
    );
  }
}

class _TopicPicker extends ConsumerWidget {
  const _TopicPicker({required this.unitNumber});

  final int unitNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(unitTopicsProvider(unitNumber));
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: switch (topics) {
          AsyncValue(value: final list?) =>
            list.isEmpty
                ? const EmptyState(title: 'No topics in this unit yet')
                : ListView(
                    children: [
                      for (final option in list)
                        ListTile(
                          leading: Text(option.code),
                          title: Text(option.title),
                          onTap: () => Navigator.of(context).pop(option),
                        ),
                    ],
                  ),
          AsyncValue(:final error?) => Padding(
            padding: AppSpacing.screenPadding,
            child: ErrorBanner(
              message: communityErrorMessage(error),
              onRetry: () => ref.invalidate(unitTopicsProvider(unitNumber)),
            ),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// "Post in": one of my groups (only members can post).
class _GroupPicker extends ConsumerWidget {
  const _GroupPicker({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(myGroupsProvider)) {
      AsyncValue(value: final groups?) =>
        groups.isEmpty
            ? const ErrorBanner(
                message: 'Join a study group first to post in it.',
              )
            : DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Post in'),
                items: [
                  for (final g in groups)
                    DropdownMenuItem(value: g.id, child: Text(g.name)),
                ],
                onChanged: onChanged,
              ),
      AsyncValue(:final error?) => ErrorBanner(
        message: communityErrorMessage(error),
        onRetry: () => ref.invalidate(myGroupsProvider),
      ),
      _ => const LinearProgressIndicator(),
    };
  }
}
