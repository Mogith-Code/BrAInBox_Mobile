import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../syllabus/data/learn_repository.dart';
import '../../syllabus/presentation/widgets/learn_widgets.dart';
import '../application/notes_controller.dart';
import 'generate_notes_sheet.dart';
import 'widgets/note_blocks.dart';

/// The Notes tab (full notes) of the Topic screen.
///
/// Tracks reading: when the student scrolls to the end (or leaves the tab)
/// it sends `POST /progress {event: read, seconds, completed}`.
class NotesTab extends StatelessWidget {
  const NotesTab({super.key, required this.detail});

  final TopicDetail detail;

  @override
  Widget build(BuildContext context) =>
      _NoteTabBody(detail: detail, type: NoteType.full, trackReading: true);
}

/// The Short Notes tab: bullet-point revision summary.
class ShortNotesTab extends StatelessWidget {
  const ShortNotesTab({super.key, required this.detail});

  final TopicDetail detail;

  @override
  Widget build(BuildContext context) =>
      _NoteTabBody(detail: detail, type: NoteType.short, trackReading: false);
}

class _NoteTabBody extends ConsumerWidget {
  const _NoteTabBody({
    required this.detail,
    required this.type,
    required this.trackReading,
  });

  final TopicDetail detail;
  final NoteType type;
  final bool trackReading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = topicNoteProvider(detail.topic.id, type);
    final state = ref.watch(provider);
    final isShort = type == NoteType.short;

    return switch (state) {
      AsyncValue(hasValue: true, :final value) when value != null =>
        _NoteReader(
          note: value,
          detail: detail,
          trackReading: trackReading,
          onRefresh: () => ref.refresh(provider.future),
        ),
      AsyncValue(hasValue: true) => RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: LearnEmptyState(
                icon: isShort ? Icons.format_list_bulleted : Icons.article_outlined,
                title: isShort ? 'No short notes yet' : 'No notes yet',
                message: isShort
                    ? 'Let BrAInBox make a quick revision summary of this topic.'
                    : 'Let BrAInBox write syllabus-matched notes for this topic.',
                action: GradientButton(
                  label: isShort ? 'Generate short notes' : 'Generate notes',
                  expand: false,
                  onPressed: () => showGenerateNotesSheet(
                    context,
                    detail: detail,
                    type: type,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      AsyncError(:final error) => ErrorCard(
        error: error,
        onRetry: () => ref.invalidate(provider),
      ),
      _ => const _NoteSkeleton(),
    };
  }
}

class _NoteReader extends ConsumerStatefulWidget {
  const _NoteReader({
    required this.note,
    required this.detail,
    required this.trackReading,
    required this.onRefresh,
  });

  final TopicNote note;
  final TopicDetail detail;
  final bool trackReading;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_NoteReader> createState() => _NoteReaderState();
}

class _NoteReaderState extends ConsumerState<_NoteReader> {
  final _scroll = ScrollController();
  final _stopwatch = Stopwatch()..start();
  late final LearnRepository _repository = ref.read(learnRepositoryProvider);
  bool _sentCompleted = false;

  @override
  void initState() {
    super.initState();
    if (widget.trackReading) {
      _scroll.addListener(_checkEnd);
      // Short notes that fit on screen count as read once shown.
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkEnd());
    }
  }

  void _checkEnd() {
    if (_sentCompleted || !_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - 24) {
      _sentCompleted = true;
      _send(completed: true);
    }
  }

  void _send({required bool completed}) {
    _repository
        .sendProgress(
          widget.detail.topic.id,
          ProgressEvent.read,
          seconds: _stopwatch.elapsed.inSeconds,
          completed: completed,
        )
        .catchError((Object _) {}); // best effort
  }

  @override
  void dispose() {
    if (widget.trackReading && !_sentCompleted && _stopwatch.elapsed.inSeconds >= 3) {
      _send(completed: false);
    }
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SyllabusTag(text: widget.detail.syllabusTagText),
              if (note.aiGenerated) const AiBadge(),
              if (note.readMinutes > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 14, color: context.learnMuted),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${note.readMinutes} min read',
                      style: textTheme.bodySmall?.copyWith(color: context.learnMuted),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          NoteBlocksView(blocks: note.blocks),
        ],
      ),
    );
  }
}

class _NoteSkeleton extends StatelessWidget {
  const _NoteSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading notes',
      child: const ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 20, width: 200, radius: AppSpacing.radiusPill),
              SizedBox(height: AppSpacing.lg),
              SkeletonBox(height: 24, width: 220),
              SizedBox(height: AppSpacing.md),
              SkeletonCard(height: 14, lines: 5),
              SizedBox(height: AppSpacing.lg),
              SkeletonCard(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}
