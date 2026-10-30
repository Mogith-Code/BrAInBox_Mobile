import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/syllabus_controller.dart';
import '../domain/syllabus_models.dart';
import 'widgets/unit_card.dart';

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
                AppSpacing.xs,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Learn',
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Saved notes',
                    icon: const Icon(Icons.bookmark_border),
                    color: AppColors.ink,
                    onPressed: () => context.push(AppRoutes.notesLibrary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
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
                  border: _pillBorder(AppColors.border),
                  enabledBorder: _pillBorder(AppColors.border),
                  focusedBorder: _pillBorder(AppColors.primary, 2),
                ),
              ),
            ),
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
      floatingActionButton: const _AiTutorButton(),
    );
  }

  static OutlineInputBorder _pillBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        borderSide: BorderSide(color: color, width: width),
      );
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

    return RefreshIndicator(
      onRefresh: ref.read(syllabusControllerProvider.notifier).refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom padding keeps the last card clear of the floating button.
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 88),
        itemCount: units.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          final unit = units[i];
          return UnitCard(
            unit: unit,
            onTap: () => context.push(AppRoutes.unitDetailPath(unit.id)),
          );
        },
      ),
    );
  }
}

/// The round brand-gradient ✦ button (bottom right in Figma).
class _AiTutorButton extends StatelessWidget {
  const _AiTutorButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ask the AI tutor',
      child: Material(
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: InkWell(
            // TODO(keshomigha): open the AI tutor when its screen exists.
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('AI tutor is coming soon.')),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}
