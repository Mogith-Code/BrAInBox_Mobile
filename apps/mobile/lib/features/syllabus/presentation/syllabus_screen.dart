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

/// Learn screen (Figma B2) - all syllabus units with mastery.
///
/// Route: `/learn` (second tab). Search filters units by title or topic;
/// pull to refresh; skeleton while loading; error banner with Retry.
class SyllabusScreen extends ConsumerStatefulWidget {
  const SyllabusScreen({super.key});

  @override
  ConsumerState<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends ConsumerState<SyllabusScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(syllabusControllerProvider);
    final textTheme = Theme.of(context).textTheme;

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
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  SoftIconButton(
                    tooltip: 'Upload notes',
                    icon: Icons.upload_file_outlined,
                    onPressed: () => context.push(AppRoutes.upload),
                  ),
                  const SizedBox(width: AppSpacing.sm),
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
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search units or topics',
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        ),
                  // 14 + 20 (line) + 14 = the 48px field from Figma.
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md + 2,
                  ),
                  isDense: true,
                  fillColor: AppColors.white,
                  border: _fieldBorder(AppColors.border),
                  enabledBorder: _fieldBorder(AppColors.border),
                  focusedBorder: _fieldBorder(AppColors.primary, 2),
                ),
              ),
            ),
            const _SubjectPills(),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: switch (state) {
                AsyncData(:final value) => _UnitList(
                  units: filterUnits(value, _query),
                  searching: _query.trim().isNotEmpty,
                  onClearSearch: _clearSearch,
                ),
                AsyncError(:final error) when !state.hasValue => Center(
                  child: ErrorBanner(
                    message: ErrorMessages.of(error),
                    onRetry: () => ref.invalidate(syllabusControllerProvider),
                  ),
                ),
                _ when state.hasValue => _UnitList(
                  units: filterUnits(state.requireValue, _query),
                  searching: _query.trim().isNotEmpty,
                  onClearSearch: _clearSearch,
                ),
                _ => const LearnSkeleton(),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd + 2),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Biology / Chemistry / Physics. Only Biology has content for now.
class _SubjectPills extends StatelessWidget {
  const _SubjectPills();

  static const _subjects = ['Biology', 'Chemistry', 'Physics'];
  static const _active = 'Biology';

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (final subject in _subjects) ...[
            if (subject != _subjects.first)
              const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: Text(subject),
              selected: subject == _active,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.white,
              labelStyle: labelStyle?.copyWith(
                color: subject == _active ? AppColors.white : AppColors.ink,
                fontWeight: subject == _active
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: subject == _active
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              onSelected: (_) {
                if (subject == _active) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text('$subject is coming soon.')),
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
    required this.searching,
    required this.onClearSearch,
  });

  final List<UnitProgress> units;
  final bool searching;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (units.isEmpty) {
      return searching
          ? EmptyState(
              icon: Icons.search_off,
              title: 'No matching units',
              message: 'Try a different unit or topic name.',
              actionLabel: 'Clear search',
              onAction: onClearSearch,
            )
          : const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No units yet',
              message: 'Your syllabus will show up here.',
            );
    }

    // The upload card sits above the units, except while searching.
    final showUpload = !searching;
    final offset = showUpload ? 1 : 0;

    return RefreshIndicator(
      onRefresh: ref.read(syllabusControllerProvider.notifier).refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom padding keeps the last card clear of the floating button.
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 88),
        itemCount: units.length + offset,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          if (showUpload && i == 0) {
            return UploadNotesCard(onTap: () => context.push(AppRoutes.upload));
          }
          final unit = units[i - offset];
          return UnitCard(
            unit: unit,
            onTap: () => context.push(AppRoutes.unitDetailPath(unit.id)),
          );
        },
      ),
    );
  }
}
