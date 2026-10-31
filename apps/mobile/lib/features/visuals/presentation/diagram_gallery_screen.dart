import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/visuals_controller.dart';
import '../domain/visuals_models.dart';
import 'widgets/visual_widgets.dart';

/// Diagrams gallery (Figma B8): a topic's diagrams with filter chips and a
/// "Generate a new visual" card.
///
/// Route: `/visuals/topics/:topicId`. The topic page's "Diagrams" tab can
/// show the same grid without the header: `DiagramGallery(topicId: id,
/// showHeader: false)`.
class DiagramGalleryScreen extends StatelessWidget {
  const DiagramGalleryScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: DiagramGallery(topicId: topicId)),
    );
  }
}

/// The gallery body (header, filters, grid), usable inside another screen.
class DiagramGallery extends ConsumerStatefulWidget {
  const DiagramGallery({
    super.key,
    required this.topicId,
    this.showHeader = true,
  });

  final String topicId;
  final bool showHeader;

  @override
  ConsumerState<DiagramGallery> createState() => _DiagramGalleryState();
}

class _DiagramGalleryState extends ConsumerState<DiagramGallery> {
  VisualFilter _filter = VisualFilter.all;

  @override
  Widget build(BuildContext context) {
    final provider = topicVisualsControllerProvider(widget.topicId);
    final state = ref.watch(provider);
    final data = state.value;

    return RefreshIndicator(
      onRefresh: () => ref.read(provider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.showHeader)
            SliverToBoxAdapter(child: _Header(topic: data)),
          SliverToBoxAdapter(
            child: _FilterChips(
              value: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
          ),
          if (data != null)
            ..._grid(context, data)
          else if (state.hasError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: ErrorBanner(
                    message: ErrorMessages.of(state.error),
                    onRetry: () => ref.invalidate(provider),
                  ),
                ),
              ),
            )
          else
            const _LoadingGrid(),
        ],
      ),
    );
  }

  List<Widget> _grid(BuildContext context, TopicVisuals data) {
    final shown = data.visuals.where(_filter.matches).toList();
    void generate() =>
        context.push(AppRoutes.generateVisualPath(topicId: widget.topicId));

    return [
      if (shown.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Text(
              _filter == VisualFilter.all
                  ? 'No diagrams for this topic yet. Make the first one!'
                  : 'No ${_filter.label.toLowerCase()} diagrams yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xxl * 2,
        ),
        sliver: SliverGrid.builder(
          gridDelegate: _gridDelegate,
          itemCount: shown.length + 1,
          itemBuilder: (context, i) {
            if (i == shown.length) return GenerateVisualTile(onTap: generate);
            final visual = shown[i];
            return VisualTile(
              visual: visual,
              tint: visualTints[i % visualTints.length],
              onTap: () => context.push(AppRoutes.diagramViewerPath(visual.id)),
            );
          },
        ),
      ),
    ];
  }
}

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  mainAxisSpacing: AppSpacing.md,
  crossAxisSpacing: AppSpacing.md,
  childAspectRatio: 0.82,
);

class _Header extends StatelessWidget {
  const _Header({required this.topic});

  final TopicVisuals? topic;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unit = Formatters.unitLabel(topic?.unitCode);
    final crumbs = ['Biology', if (unit.isNotEmpty) unit, ?topic?.topicTitle];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.learn),
              ),
              Expanded(
                child: Text(
                  crumbs.join('  ›  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: topic == null
                ? const SkeletonBox(height: 32, width: 220)
                : Text(
                    topic!.topicTitle,
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              top: AppSpacing.xs,
            ),
            child: Text(
              'Diagrams',
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.value, required this.onChanged});

  final VisualFilter value;
  final ValueChanged<VisualFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        itemCount: VisualFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final filter = VisualFilter.values[i];
          return ChoicePill(
            label: filter.label,
            selected: filter == value,
            onTap: () => onChanged(filter),
          );
        },
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverGrid.builder(
        gridDelegate: _gridDelegate,
        itemCount: 4,
        itemBuilder: (_, _) => const SkeletonBox(
          height: double.infinity,
          radius: AppSpacing.radiusLg,
        ),
      ),
    );
  }
}
