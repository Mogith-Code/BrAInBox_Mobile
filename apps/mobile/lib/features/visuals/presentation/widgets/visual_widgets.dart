import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../data/diagram_renderer.dart';

/// Soft backgrounds for the gallery thumbnails (Figma B8), picked by index.
const visualTints = [
  AppColors.primarySoft,
  AppColors.successSoft,
  AppColors.secondarySoft,
  AppColors.errorSoft,
  AppColors.warningSoft,
];

/// Colours of the numbered steps / markers (indigo, teal, green, amber).
const labelColors = [
  AppColors.primary,
  AppColors.secondary,
  AppColors.success,
  AppColors.warning,
];

Color labelColor(int number) => labelColors[(number - 1) % labelColors.length];

/// The picture of a [Visual]: its PNG, or its Mermaid code rendered by
/// Kroki. Shows a skeleton while loading and a message if it fails.
class VisualImage extends StatelessWidget {
  const VisualImage({super.key, required this.visual, this.fit = BoxFit.fill});

  final Visual visual;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = DiagramRenderer.imageUrlOf(visual);
    if (url == null) return const _ImageProblem();
    return Image.network(
      url,
      fit: fit,
      semanticLabel: visual.altText ?? visual.title,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const SkeletonBox(height: double.infinity, radius: 0),
      errorBuilder: (context, error, stack) => const _ImageProblem(),
    );
  }
}

class _ImageProblem extends StatelessWidget {
  const _ImageProblem();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.muted,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Couldn't load the image",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// A numbered circle on a visual ("1", "2"...). The selected one gets a
/// soft halo, like Bowman's capsule in Figma B9.
class LabelMarker extends StatelessWidget {
  const LabelMarker({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.size = 28,
  });

  final VisualLabel label;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Label ${label.number}: ${label.name}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            border: Border.all(color: AppColors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: selected ? 0.35 : 0.2,
                ),
                spreadRadius: selected ? 10 : 0,
                blurRadius: selected ? 0 : 6,
              ),
            ],
          ),
          child: ExcludeSemantics(
            child: Text(
              '${label.number}',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The visual at its own aspect ratio, with label markers placed on it
/// (labels without an x / y are not drawn here; the viewer lists them).
class LabelledVisual extends StatelessWidget {
  const LabelledVisual({
    super.key,
    required this.visual,
    required this.showLabels,
    required this.selected,
    required this.onSelect,
  });

  final Visual visual;
  final bool showLabels;
  final int? selected;
  final ValueChanged<int> onSelect;

  static const _marker = 28.0;

  @override
  Widget build(BuildContext context) {
    final placed = [
      for (final l in visual.labels)
        if (l.x != null && l.y != null) l,
    ];
    return AspectRatio(
      aspectRatio: visual.aspectRatio,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: VisualImage(visual: visual)),
            if (showLabels)
              for (final l in placed)
                Positioned(
                  left: l.x!.clamp(0.0, 1.0) * box.maxWidth - _marker / 2,
                  top: l.y!.clamp(0.0, 1.0) * box.maxHeight - _marker / 2,
                  child: LabelMarker(
                    label: l,
                    selected: l.number == selected,
                    onTap: () => onSelect(l.number),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Green "Verified" chip for visuals a teacher has checked.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        border: Border.all(color: AppColors.mint),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 13, color: AppColors.successDark),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Verified',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.successDark,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// One card in the diagram grid: tinted thumbnail, title and badge.
class VisualTile extends StatelessWidget {
  const VisualTile({
    super.key,
    required this.visual,
    required this.tint,
    required this.onTap,
  });

  final Visual visual;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusLg);
    return Semantics(
      button: true,
      label: visual.title,
      child: Material(
        color: AppColors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ColoredBox(
                    color: tint,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: VisualImage(visual: visual, fit: BoxFit.contain),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visual.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      // Shrinks on narrow phones instead of overflowing.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: visual.isAiGenerated
                            ? const AiBadge()
                            : visual.isVerified
                            ? const VerifiedBadge()
                            : const SizedBox(height: 22),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The last grid card: "Generate a new visual".
class GenerateVisualTile extends StatelessWidget {
  const GenerateVisualTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusLg);
    return Semantics(
      button: true,
      label: 'Generate a new visual',
      child: Material(
        color: AppColors.primarySoft.withValues(alpha: 0.6),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: ExcludeSemantics(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Generate a new visual',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small rounded chip that can be selected (indigo with a check mark).
/// Used for the gallery filters and the Generate a visual type chips.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.primary : AppColors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    const Icon(Icons.check, size: 16, color: AppColors.white),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? AppColors.white : AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
