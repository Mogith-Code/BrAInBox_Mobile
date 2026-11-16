import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/learn_models.dart';
import 'learn_widgets.dart';

/// A video: thumbnail with a play icon and duration chip, title, syllabus
/// tag.
class VideoCard extends StatelessWidget {
  const VideoCard({
    super.key,
    required this.video,
    required this.syllabusTag,
    required this.onTap,
  });

  final Video video;
  final String syllabusTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play video: ${video.title}, ${video.durationLabel}',
      child: ExcludeSemantics(
        child: LearnCard(
          onTap: onTap,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (video.thumbnailUrl != null)
                      Image.network(
                        video.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _ThumbPlaceholder(),
                      )
                    else
                      const _ThumbPlaceholder(),
                    Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 32,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                        child: Text(
                          video.durationLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: context.learnInk),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SyllabusTag(text: syllabusTag),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(gradient: AppColors.brandGradient),
    child: Center(
      child: Icon(Icons.ondemand_video, size: 40, color: Color(0x66FFFFFF)),
    ),
  );
}

/// One stored diagram in the grid: image, caption, AI badge when made by
/// AI.
class DiagramTile extends StatelessWidget {
  const DiagramTile({super.key, required this.diagram, required this.onTap});

  final Diagram diagram;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Diagram: ${diagram.caption}'
          '${diagram.aiGenerated ? ', AI-generated' : ''}. Tap to zoom',
      child: ExcludeSemantics(
        child: LearnCard(
          onTap: onTap,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Hero(
                  tag: 'diagram-${diagram.id}',
                  child: ColoredBox(
                    color: AppColors.white,
                    child: DiagramImage(url: diagram.imageUrl),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diagram.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.learnInk,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (diagram.aiGenerated) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const AiBadge(label: 'AI'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A network image with a friendly placeholder while loading / on error.
class DiagramImage extends StatelessWidget {
  const DiagramImage({super.key, required this.url, this.fit = BoxFit.contain});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: SkeletonBox(height: 60, width: 60)),
      errorBuilder: (_, _, _) => const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: AppColors.mutedLight,
        ),
      ),
    );
  }
}
