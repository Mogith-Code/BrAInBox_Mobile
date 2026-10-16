import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_logo.dart';

/// The pulsing BrAInBox mark with a message. Show it while the AI is working
/// (generating notes, visuals, papers, evaluating an answer...).
///
/// Pass [progress] (0.0 - 1.0) if the backend reports it, e.g. from
/// `AiJob.progress`; otherwise the bar just animates.
class AiGeneratingLoader extends StatefulWidget {
  const AiGeneratingLoader({
    super.key,
    this.message = 'AI is generating...',
    this.progress,
  });

  final String message;
  final double? progress;

  @override
  State<AiGeneratingLoader> createState() => _AiGeneratingLoaderState();
}

class _AiGeneratingLoaderState extends State<AiGeneratingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.message,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.1).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            ),
            child: const AppLogo(variant: AppLogoVariant.mark, size: 72),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(widget.message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: widget.progress,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              color: AppColors.primary,
              backgroundColor: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}
