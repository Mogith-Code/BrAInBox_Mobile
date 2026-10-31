import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/visuals_controller.dart';
import '../domain/visuals_models.dart';
import 'widgets/visual_widgets.dart';

/// Diagram viewer (Figma B9): the visual full screen on a dark background.
/// Pinch or use +/- to zoom; tap a number to read that part in the panel
/// below. "Report inaccuracy" and "New visual" sit at the bottom.
///
/// Route: `/visuals/view/:visualId`
class DiagramViewerScreen extends ConsumerWidget {
  const DiagramViewerScreen({super.key, required this.visualId});

  final String visualId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visualDetailProvider(visualId));
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.white),
          ),
          error: (error, _) => Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: _CloseButton(),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: Card(
                      child: Padding(
                        padding: AppSpacing.cardPadding,
                        child: ErrorBanner(
                          message: ErrorMessages.of(error),
                          onRetry: () =>
                              ref.invalidate(visualDetailProvider(visualId)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          data: (visual) => _Viewer(visual: visual),
        ),
      ),
    );
  }
}

class _Viewer extends StatefulWidget {
  const _Viewer({required this.visual});

  final Visual visual;

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  final _zoom = TransformationController();
  bool _showLabels = true;
  late int? _selected = widget.visual.labels.firstOrNull?.number;

  static const _minScale = 1.0;
  static const _maxScale = 5.0;

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  /// Zooms by [factor] around the middle of the [viewport].
  void _zoomBy(double factor, Size viewport) {
    final scale = (_zoom.value.getMaxScaleOnAxis() * factor).clamp(
      _minScale,
      _maxScale,
    );
    _zoom.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        viewport.width / 2 * (1 - scale),
        viewport.height / 2 * (1 - scale),
        0,
      );
  }

  @override
  Widget build(BuildContext context) {
    final visual = widget.visual;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              const _CloseButton(),
              Expanded(
                child: Text(
                  visual.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (visual.isAiGenerated)
                const AiBadge(onDark: true)
              else if (visual.isVerified)
                const VerifiedBadge(),
              if (visual.hasLabels) ...[
                const SizedBox(width: AppSpacing.sm),
                _LabelsToggle(
                  value: _showLabels,
                  onChanged: (v) => setState(() => _showLabels = v),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: _zoom,
                    minScale: _minScale,
                    maxScale: _maxScale,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXl,
                            ),
                          ),
                          child: LabelledVisual(
                            visual: visual,
                            showLabels: _showLabels,
                            selected: _selected,
                            onSelect: (n) => setState(() => _selected = n),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.md,
                  bottom: AppSpacing.xl,
                  child: Column(
                    children: [
                      _ZoomButton(
                        icon: Icons.add,
                        tooltip: 'Zoom in',
                        onTap: () => _zoomBy(1.5, box.biggest),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ZoomButton(
                        icon: Icons.remove,
                        tooltip: 'Zoom out',
                        onTap: () => _zoomBy(1 / 1.5, box.biggest),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            visual.hasLabels
                ? 'Pinch to zoom · tap a number to read about it'
                : 'Pinch to zoom',
            style: textTheme.bodySmall?.copyWith(color: AppColors.mutedLight),
          ),
        ),
        _InfoPanel(
          visual: visual,
          selected: _selected,
          onSelect: (n) => setState(() {
            _selected = n;
            _showLabels = true;
          }),
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Close',
      icon: const Icon(Icons.close, color: AppColors.white),
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.home),
    );
  }
}

/// White "Labels" pill that shows / hides the numbered markers.
class _LabelsToggle extends StatelessWidget {
  const _LabelsToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: 'Show labels',
      child: Material(
        color: value ? AppColors.white : AppColors.darkSurface,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.darkBorder),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            child: ExcludeSemantics(
              child: Text(
                'Labels',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: value ? AppColors.ink : AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkSurface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.darkBorder)),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: AppColors.white),
        onPressed: onTap,
      ),
    );
  }
}

/// The white panel at the bottom: the selected label (or the description),
/// the label list, and the two actions.
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.visual,
    required this.selected,
    required this.onSelect,
  });

  final Visual visual;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = visual.labels.where((l) => l.number == selected).firstOrNull;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (label != null) ...[
                _NumberDot(number: label.number),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label?.name ?? 'About this visual',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (visual.isAiGenerated) const AiBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 96),
            child: SingleChildScrollView(
              child: Text(
                label?.description ??
                    visual.altText ??
                    'AI visuals can contain errors. Report anything wrong.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
            ),
          ),
          if (visual.labels.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visual.labels.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final l = visual.labels[i];
                  return ChoicePill(
                    label: '${l.number}  ${l.name}',
                    selected: l.number == selected,
                    onTap: () => onSelect(l.number),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Report inaccuracy'),
                  onPressed: () => showReportVisualSheet(context, visual.id),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'New visual',
                  icon: Icons.auto_awesome,
                  variant: AppButtonVariant.gradient,
                  onPressed: () => context.push(
                    AppRoutes.generateVisualPath(topicId: visual.topicId),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberDot extends StatelessWidget {
  const _NumberDot({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Opens the "Report inaccuracy" sheet. Shows a thank-you snack bar when
/// the report is sent (or was already sent before).
Future<void> showReportVisualSheet(
  BuildContext context,
  String visualId,
) async {
  final thanks = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (_) => _ReportSheet(visualId: visualId),
  );
  if (thanks != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(thanks)));
  }
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.visualId});

  final String visualId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  VisualReportReason? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null) return;
    final thanks = await ref
        .read(visualReportControllerProvider.notifier)
        .submit(widget.visualId, reason: reason, details: _details.text);
    if (thanks != null && mounted) Navigator.of(context).pop(thanks);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visualReportControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What is wrong?',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'A teacher checks every report and fixes the visual.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final r in VisualReportReason.values)
                  ChoicePill(
                    label: r.label,
                    selected: r == _reason,
                    onTap: () => setState(() => _reason = r),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Details (optional)',
              hint: 'e.g. Label 2 should be the PCT, not the DCT',
              controller: _details,
              maxLines: 3,
            ),
            if (state.hasError) ...[
              const SizedBox(height: AppSpacing.md),
              ErrorBanner(message: ErrorMessages.of(state.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Send report',
              isLoading: state.isLoading,
              onPressed: _reason == null ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
