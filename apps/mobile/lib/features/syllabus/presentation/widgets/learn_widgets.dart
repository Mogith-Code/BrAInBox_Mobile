import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import 'learn_style.dart';

export 'learn_style.dart';
export 'status_pill.dart';

/// Mastery ring with the % in the middle. Colour follows
/// [LearnStyle.ringColor] unless [color] is given.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 44,
    this.strokeWidth = 4,
    this.color,
    this.trackColor,
    this.labelColor,
  });

  /// 0-1.
  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return MasteryRing(
      value: v,
      size: size,
      strokeWidth: strokeWidth,
      color: color ?? LearnStyle.ringColor(v),
      trackColor: trackColor ?? context.learnBorder,
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: labelColor ?? context.learnInk,
        fontWeight: FontWeight.w600,
        fontSize: size >= 60 ? 15 : 11,
      ),
    );
  }
}

/// Thin rounded progress bar (teal on the border colour).
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.width = 70, this.color});

  final double value;
  final double? width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 5,
          backgroundColor: context.learnBorder,
          color: color ?? AppColors.secondary,
        ),
      ),
    );
  }
}

/// "Unit 6 · 6.1 Mendelian inheritance" in a teal tag.
class SyllabusTag extends StatelessWidget {
  const SyllabusTag({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => _Tag(
    icon: Icons.bookmark_outline,
    text: text,
    background: AppColors.secondarySoft,
    foreground: AppColors.secondaryDark,
  );
}

/// Amber "Older syllabus (2017)" tag for topics from a past syllabus.
class OutdatedSyllabusTag extends StatelessWidget {
  const OutdatedSyllabusTag({super.key, this.version});

  final String? version;

  @override
  Widget build(BuildContext context) => _Tag(
    icon: Icons.history,
    text: version == null ? 'Older syllabus' : 'Older syllabus ($version)',
    background: AppColors.streakSoft,
    foreground: AppColors.streakDark,
  );
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Brand-gradient button (teal → indigo), for AI actions only.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.auto_awesome,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(LearnStyle.buttonRadius);
    final enabled = onPressed != null;
    final button = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: AppColors.white),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.white,
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
      ),
    );
    return Semantics(button: true, enabled: enabled, label: label, child: ExcludeSemantics(child: button));
  }
}

/// Grey placeholder card (skeleton loader).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 76, this.lines = 0});

  final double height;

  /// Extra grey text lines under the block.
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: height, radius: LearnStyle.cardRadius),
        for (var i = 0; i < lines; i++) ...[
          const SizedBox(height: AppSpacing.sm),
          FractionallySizedBox(
            widthFactor: i.isEven ? 0.9 : 0.6,
            child: const SkeletonBox(height: 12, radius: AppSpacing.radiusSm),
          ),
        ],
      ],
    );
  }
}

/// A list of [SkeletonCard]s with a screen-reader label.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 6,
    this.height = 76,
    this.label = 'Loading',
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  final int count;
  final double height;
  final String label;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: padding,
          itemCount: count,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, _) => SkeletonCard(height: height),
        ),
      ),
    );
  }
}

/// A small sprout drawn with icons (empty search).
class SproutIllustration extends StatelessWidget {
  const SproutIllustration({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
            ),
            Positioned(
              bottom: size * 0.2,
              child: Container(
                width: size * 0.5,
                height: size * 0.08,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
            Icon(Icons.spa, size: size * 0.46, color: AppColors.success),
            Positioned(
              top: size * 0.14,
              right: size * 0.18,
              child: Icon(
                Icons.auto_awesome,
                size: size * 0.16,
                color: AppColors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered empty state: illustration (or icon), title, message, action.
class LearnEmptyState extends StatelessWidget {
  const LearnEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.illustration,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? illustration;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration ??
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: AppColors.primary),
                ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(color: context.learnInk),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: context.learnMuted),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Friendly error card with Retry. Shows an offline message for network
/// errors.
class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  bool get _offline =>
      error is ApiException && (error as ApiException).code == 'network';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Semantics(
          liveRegion: true,
          child: LearnCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _offline ? Icons.wifi_off_rounded : Icons.sentiment_dissatisfied_outlined,
                  size: 40,
                  color: _offline ? AppColors.warning : AppColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _offline ? "You're offline" : 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(color: context.learnInk),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _offline
                      ? 'Check your internet connection and try again.'
                      : ErrorMessages.of(error),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: context.learnMuted),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LearnStyle.buttonRadius),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "BrAInBox is thinking": three bouncing dots and shimmering lines.
class AIThinkingCard extends StatefulWidget {
  const AIThinkingCard({super.key, this.message = 'BrAInBox is thinking'});

  final String message;

  @override
  State<AIThinkingCard> createState() => _AIThinkingCardState();
}

class _AIThinkingCardState extends State<AIThinkingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      label: '${widget.message}, please wait',
      child: ExcludeSemantics(
        child: LearnCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: textTheme.titleSmall?.copyWith(color: context.learnInk),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    for (var i = 0; i < 3; i++) _dot(i),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final w in [1.0, 0.85, 0.6]) ...[
                  _shimmerLine(w),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(int i) {
    final t = (_c.value - i * 0.2) % 1.0;
    final lift = t < 0.5 ? (0.5 - (t - 0.25).abs()) * 2 : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Transform.translate(
        offset: Offset(0, -4 * lift),
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _shimmerLine(double widthFactor) {
    final base = context.learnBorder;
    final shine = context.isDark ? AppColors.darkSurface : AppColors.white;
    final x = _c.value * 3 - 1; // -1 .. 2
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          gradient: LinearGradient(
            begin: Alignment(x - 1, 0),
            end: Alignment(x + 1, 0),
            colors: [base, shine, base],
          ),
        ),
      ),
    );
  }
}
