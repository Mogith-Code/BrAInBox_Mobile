import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/visuals_controller.dart';
import 'widgets/visual_widgets.dart';
import 'widgets/visualise_anything_card.dart';

/// "My visuals": draw any Biology idea (no topic needed) and see the
/// visuals made on this phone, newest first.
///
/// Route: `/visuals`. Opened from the Home "Visualise anything" card.
class MyVisualsScreen extends ConsumerWidget {
  const MyVisualsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myVisualsControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    void generate() => context.push(AppRoutes.generateVisualPath());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('My visuals'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(myVisualsControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: VisualiseAnythingCard(
                  onOpen: generate,
                  buttonLabel: 'Generate a visual',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Recent on this phone',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            ...switch (state) {
              AsyncData(:final value) when value.isEmpty => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.collections_outlined,
                    title: 'No visuals yet',
                    message:
                        'Ask for any diagram - a process, a structure or a '
                        'comparison - and it will appear here.',
                    actionLabel: 'Generate a visual',
                    onAction: generate,
                  ),
                ),
              ],
              AsyncData(:final value) => [_Grid(visuals: value)],
              AsyncError(:final error) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: ErrorBanner(
                      message: ErrorMessages.of(error),
                      onRetry: () =>
                          ref.invalidate(myVisualsControllerProvider),
                    ),
                  ),
                ),
              ],
              _ => [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.visuals});

  final List<Visual> visuals;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.82,
        ),
        itemCount: visuals.length,
        itemBuilder: (context, i) => VisualTile(
          visual: visuals[i],
          tint: visualTints[i % visualTints.length],
          onTap: () => context.push(AppRoutes.diagramViewerPath(visuals[i].id)),
        ),
      ),
    );
  }
}
