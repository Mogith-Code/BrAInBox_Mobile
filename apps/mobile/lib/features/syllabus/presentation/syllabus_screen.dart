import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/syllabus_controller.dart';
import '../domain/syllabus_models.dart';
import 'widgets/ask_brainbox_button.dart';
import 'widgets/unit_card.dart';
import 'widgets/upload_notes_card.dart';

/// Learn home: the syllabus units with mastery.
///
/// Route: `/learn` (second tab). The search box filters the units live and
/// asks `GET /learn/search` for matching topics (debounced). Pull to
/// refresh; skeleton while loading; error card with Retry.
class SyllabusScreen extends ConsumerStatefulWidget {
  const SyllabusScreen({super.key});

  /// Wait this long after the last key press before searching the server.
  static const searchDebounce = Duration(milliseconds: 300);

  @override
  ConsumerState<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends ConsumerState<SyllabusScreen> {
  final _search = TextEditingController();
  String _query = '';

  /// The query sent to the server (after the debounce).
  String _serverQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(SyllabusScreen.searchDebounce, () {
      if (mounted) setState(() => _serverQuery = value.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    setState(() => _query = _serverQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(syllabusControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final searching = _query.trim().isNotEmpty;

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
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Learn',
                        style: textTheme.headlineSmall?.copyWith(
                          color: context.learnInk,
                        ),
                      ),
                    ),
                  ),
                  SoftIconButton(
                    tooltip: 'My library',
                    icon: Icons.bookmark_border,
                    onPressed: () => context.push(AppRoutes.notesLibrary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: TextField(
                controller: _search,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search units or topics',
                  prefixIcon: Icon(Icons.search, color: context.learnMuted),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md + 2,
                  ),
                  isDense: true,
                  fillColor: context.learnSurface,
                  border: _fieldBorder(context.learnBorder),
                  enabledBorder: _fieldBorder(context.learnBorder),
                  focusedBorder: _fieldBorder(AppColors.primary, 2),
                ),
              ),
            ),
            const _SubjectPills(),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: switch (state) {
                AsyncValue(:final value?) => _UnitList(
                  units: filterUnits(value, _query),
                  query: _query.trim(),
                  serverQuery: searching ? _serverQuery : '',
                  onClearSearch: _clearSearch,
                ),
                AsyncError(:final error) => ErrorCard(
                  error: error,
                  onRetry: () => ref.invalidate(syllabusControllerProvider),
                ),
                _ => const SkeletonList(label: 'Loading units'),
              },
            ),
          ],
        ),
      ),
      floatingActionButton: const AskBrainBoxButton(extended: false),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Biology / Chemistry / Physics from `GET /learn/subjects`. Only available
/// subjects can be picked; the others say "coming soon".
class _SubjectPills extends ConsumerWidget {
  const _SubjectPills();

  static const _fallback = [
    Subject(id: 'biology', name: 'Biology', available: true),
    Subject(id: 'chemistry', name: 'Chemistry'),
    Subject(id: 'physics', name: 'Physics'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider).value ?? _fallback;
    final active = subjects.where((s) => s.available).firstOrNull;
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (final subject in subjects) ...[
            if (subject != subjects.first) const SizedBox(width: AppSpacing.sm),
            Builder(
              builder: (context) {
                final selected = subject == active;
                return ChoiceChip(
                  label: Text(
                    subject.available ? subject.name : '${subject.name} · Soon',
                  ),
                  tooltip: subject.available
                      ? null
                      : '${subject.name} is coming soon',
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  backgroundColor: context.learnSurface,
                  labelStyle: labelStyle?.copyWith(
                    color: selected
                        ? AppColors.white
                        : subject.available
                        ? context.learnInk
                        : context.learnMuted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: selected ? AppColors.primary : context.learnBorder,
                    ),
                  ),
                  onSelected: (_) {
                    if (selected) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('${subject.name} is coming soon.'),
                        ),
                      );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _UnitList extends ConsumerWidget {
  const _UnitList({
    required this.units,
    required this.query,
    required this.serverQuery,
    required this.onClearSearch,
  });

  final List<UnitProgress> units;
  final String query;
  final String serverQuery;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searching = query.isNotEmpty;
    final search = serverQuery.isEmpty
        ? null
        : ref.watch(learnSearchProvider(serverQuery));
    final topicHits = search?.value?.topics ?? const <TopicSearchHit>[];
    final searchPending =
        searching && (serverQuery != query || (search?.isLoading ?? false));

    if (searching && units.isEmpty && topicHits.isEmpty && !searchPending) {
      return LearnEmptyState(
        illustration: const SproutIllustration(),
        title: 'No units match "$query"',
        message: 'Try another unit or topic name.',
        action: TextButton(
          onPressed: onClearSearch,
          child: const Text('Clear search'),
        ),
      );
    }
    if (!searching && units.isEmpty) {
      return const LearnEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No units yet',
        message: 'Your syllabus will show up here.',
      );
    }

    final textTheme = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: ref.read(syllabusControllerProvider.notifier).refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom padding keeps the last card clear of the floating button.
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 96),
        children: [
          if (!searching) ...[
            UploadNotesCard(onTap: () => context.push(AppRoutes.uploads)),
            const SizedBox(height: AppSpacing.md),
          ],
          for (final unit in units) ...[
            UnitCard(
              unit: unit,
              onTap: () => context.push(AppRoutes.unitDetailPath(unit.id)),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (searching && topicHits.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                'Topics',
                style: textTheme.titleSmall?.copyWith(color: context.learnInk),
              ),
            ),
            for (final hit in topicHits) ...[
              LearnCard(
                onTap: () => context.push(AppRoutes.topicPath(hit.id)),
                child: Row(
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hit.title,
                            style: textTheme.titleSmall?.copyWith(
                              color: context.learnInk,
                            ),
                          ),
                          if (hit.unitTitle.isNotEmpty)
                            Text(
                              'Unit ${hit.unitOrder} · ${hit.unitTitle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: context.learnMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: context.learnMuted),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          if (searchPending)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: SkeletonCard(height: 56),
            ),
        ],
      ),
    );
  }
}
