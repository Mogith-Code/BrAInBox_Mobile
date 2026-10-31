import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/visuals_models.dart';
import 'visual_widgets.dart';

/// One of the three style cards (Flat colour / Textbook line / Cross
/// section) with a small sample on top.
class StyleCard extends StatelessWidget {
  const StyleCard({
    super.key,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final VisualStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusLg);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Style: ${style.label}',
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 52, child: _sample()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      style.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _sample() => switch (style) {
    VisualStyle.flatColour => const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.mint, AppColors.primaryLight],
        ),
      ),
    ),
    VisualStyle.textbookLine => const ColoredBox(
      color: AppColors.white,
      child: Icon(Icons.gesture, color: AppColors.mutedLight),
    ),
    VisualStyle.crossSection => const ColoredBox(
      color: AppColors.surfaceMuted,
      child: Icon(Icons.donut_large, color: AppColors.mutedLight),
    ),
  };
}

/// A sample of what the chosen type looks like (not the real result).
class VisualTypePreview extends StatelessWidget {
  const VisualTypePreview({super.key, required this.type});

  final VisualType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: switch (type) {
        VisualType.process => const _ProcessPreview(),
        VisualType.structure => const _StructurePreview(),
        VisualType.comparison => const _ComparisonPreview(),
      },
    );
  }
}

class _ProcessPreview extends StatelessWidget {
  const _ProcessPreview();

  static const _steps = [
    ('Filtration', 'Glomerulus'),
    ('Reabsorption', 'PCT'),
    ('Concentration', 'Loop'),
    ('Collection', 'Duct'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.mutedLight,
              ),
            ),
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: labelColor(i + 1),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _steps[i].$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _steps[i].$2,
                  maxLines: 1,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StructurePreview extends StatelessWidget {
  const _StructurePreview();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 140,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: AppColors.secondary, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLight,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
          ),
          for (final (n, align) in const [
            (1, Alignment(-0.55, -0.8)),
            (2, Alignment(0, 0.1)),
            (3, Alignment(0.55, 0.8)),
          ])
            Align(
              alignment: align,
              child: LabelMarker(
                label: VisualLabel(number: n, name: 'Part $n'),
                selected: false,
                size: 22,
                onTap: () {},
              ),
            ),
        ],
      ),
    );
  }
}

class _ComparisonPreview extends StatelessWidget {
  const _ComparisonPreview();

  static const _rows = [
    ('Divisions', '1', '2'),
    ('Daughter cells', '2', '4'),
    ('Chromosomes', 'Diploid', 'Haploid'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final head = textTheme.labelSmall?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w800,
    );
    final cell = textTheme.labelSmall?.copyWith(color: AppColors.ink);
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.4)},
      children: [
        TableRow(
          children: [
            const SizedBox(),
            Text('Mitosis', style: head),
            Text('Meiosis', style: head),
          ],
        ),
        for (final (name, a, b) in _rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs + 2),
                child: Text(
                  name,
                  style: cell?.copyWith(color: AppColors.muted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs + 2),
                child: Text(a, style: cell),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs + 2),
                child: Text(b, style: cell),
              ),
            ],
          ),
      ],
    );
  }
}
