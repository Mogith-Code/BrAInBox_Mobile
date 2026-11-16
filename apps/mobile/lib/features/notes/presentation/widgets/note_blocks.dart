import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../../syllabus/domain/learn_models.dart';
import '../../../syllabus/presentation/widgets/learn_widgets.dart';
import '../../../syllabus/presentation/widgets/media_cards.dart';
import '../../../syllabus/presentation/zoom_image_screen.dart';

/// Renders a note's blocks with native widgets (no WebView).
class NoteBlocksView extends StatelessWidget {
  const NoteBlocksView({super.key, required this.blocks});

  final List<NoteBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in blocks)
          if (block is! UnknownBlock)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: NoteBlockView(block: block),
            ),
      ],
    );
  }
}

/// One block: heading, paragraph, definition, tip, bullets, table, image.
class NoteBlockView extends StatelessWidget {
  const NoteBlockView({super.key, required this.block});

  final NoteBlock block;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final body = textTheme.bodyLarge?.copyWith(
      color: context.learnInk,
      fontSize: 15,
      height: 1.55,
    );

    return switch (block) {
      HeadingBlock(:final text, :final level) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Semantics(
          header: true,
          child: Text(
            text,
            style: (level <= 2 ? textTheme.titleLarge : textTheme.titleMedium)
                ?.copyWith(
                  color: context.learnInk,
                  fontSize: level <= 1 ? 24 : (level == 2 ? 20 : 17),
                ),
          ),
        ),
      ),
      ParagraphBlock(:final text, :final highlights) => Text.rich(
        TextSpan(children: highlightSpans(text, highlights)),
        style: body,
      ),
      DefinitionBlock(:final term, :final text) => _Callout(
        borderColor: AppColors.secondary,
        background: context.isDark
            ? AppColors.secondary.withValues(alpha: 0.12)
            : AppColors.secondarySoft,
        icon: Icons.menu_book_outlined,
        iconColor: AppColors.secondaryDark,
        label: 'Definition',
        title: term.isEmpty ? null : term,
        text: text,
        textStyle: body,
      ),
      TipBlock(:final title, :final text) => _Callout(
        background: context.isDark
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.primarySoft,
        icon: Icons.lightbulb_outline,
        iconColor: AppColors.primary,
        label: title,
        text: text,
        textStyle: body,
      ),
      BulletListBlock(:final items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 9,
                      right: AppSpacing.sm + 2,
                    ),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(child: Text(item, style: body)),
                ],
              ),
            ),
        ],
      ),
      TableBlock(:final headers, :final rows, :final caption) => _NoteTable(
        headers: headers,
        rows: rows,
        caption: caption,
      ),
      ImageBlock(:final url, :final caption) => _Figure(
        url: url,
        caption: caption,
      ),
      UnknownBlock() => const SizedBox.shrink(),
    };
  }
}

/// [text] as spans, with every term in [terms] (any case) highlighted.
List<TextSpan> highlightSpans(String text, List<String> terms) {
  final clean = [
    for (final t in terms)
      if (t.trim().isNotEmpty) t.trim(),
  ]..sort((a, b) => b.length.compareTo(a.length));
  if (clean.isEmpty) return [TextSpan(text: text)];
  final pattern = RegExp(
    clean.map(RegExp.escape).join('|'),
    caseSensitive: false,
  );
  final spans = <TextSpan>[];
  var start = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > start) {
      spans.add(TextSpan(text: text.substring(start, m.start)));
    }
    spans.add(
      TextSpan(
        text: m.group(0),
        style: const TextStyle(
          backgroundColor: LearnStyle.highlight,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
    start = m.end;
  }
  if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
  return spans;
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.text,
    required this.textStyle,
    this.borderColor,
    this.title,
  });

  final Color background;
  final Color? borderColor;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? title;
  final String text;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: borderColor == null
            ? null
            : Border(left: BorderSide(color: borderColor!, width: 4)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (title != null) ...[
            Text(
              title!,
              style: textTheme.titleSmall?.copyWith(color: context.learnInk),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(text, style: textStyle),
        ],
      ),
    );
  }
}

class _NoteTable extends StatelessWidget {
  const _NoteTable({required this.headers, required this.rows, this.caption});

  final List<String> headers;
  final List<List<String>> rows;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final columns = [
      headers.length,
      for (final r in rows) r.length,
    ].fold(0, (a, b) => a > b ? a : b);
    if (columns == 0) return const SizedBox.shrink();
    Widget cell(String text, {bool header = false}) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        text,
        style: textTheme.bodyMedium?.copyWith(
          color: context.learnInk,
          fontWeight: header ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
    List<String> pad(List<String> r) => [
      ...r,
      for (var i = r.length; i < columns; i++) '',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.sizeOf(context).width - AppSpacing.lg * 2,
            ),
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(
                color: context.learnBorder,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              children: [
                if (headers.isNotEmpty)
                  TableRow(
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : AppColors.primarySoft,
                    ),
                    children: [
                      for (final h in pad(headers)) cell(h, header: true),
                    ],
                  ),
                for (final r in rows)
                  TableRow(children: [for (final c in pad(r)) cell(c)]),
              ],
            ),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            caption!,
            style: textTheme.bodySmall?.copyWith(color: context.learnMuted),
          ),
        ],
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.url, this.caption});

  final String url;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: 'Figure${caption == null ? '' : ': $caption'}. Tap to zoom',
          child: GestureDetector(
            onTap: () =>
                ZoomImageScreen.open(context, url: url, caption: caption),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                color: AppColors.white,
                constraints: const BoxConstraints(
                  minHeight: 120,
                  maxHeight: 260,
                ),
                width: double.infinity,
                child: DiagramImage(url: url),
              ),
            ),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            caption!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.learnMuted),
          ),
        ],
      ],
    );
  }
}
