import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/brand_assets.dart';

/// Which version of the logo to show. See docs/brand.md for where to use each.
enum AppLogoVariant {
  /// Gradient rounded-square app icon.
  icon,

  /// Box + sprout only, no background (illustrations, empty states).
  mark,

  /// Icon with the wordmark on its right.
  horizontal,

  /// Icon with the wordmark below it.
  stacked,

  /// The wordmark (and optional tagline) only, sized as in [stacked] for an
  /// icon of height `size`. Use it when the icon is drawn separately, e.g.
  /// inside the frosted tile on the splash screen.
  wordmark,
}

/// The BrAInBox logo.
///
/// ```dart
/// const AppLogo()                                          // icon, 48 px
/// const AppLogo(variant: AppLogoVariant.horizontal, size: 32)
/// const AppLogo(variant: AppLogoVariant.stacked, onDark: true, showTagline: true)
/// ```
///
/// The icon and mark come from the brand SVGs. The wordmark ("BrAInBox") is
/// built here in Flutter with Poppins Bold, because flutter_svg cannot render
/// Poppins inside the wordmark SVGs. Proportions match the brand SVG files.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.variant = AppLogoVariant.icon,
    this.size = 48,
    this.onDark = false,
    this.showTagline = false,
  });

  final AppLogoVariant variant;

  /// Height of the icon part, in logical pixels.
  final double size;

  /// Use `true` on dark or gradient backgrounds (white wordmark).
  final bool onDark;

  /// Show "Study smarter. Fix what matters." under the wordmark
  /// (horizontal and stacked only).
  final bool showTagline;

  // Proportions taken from the brand SVGs (relative to the icon height).
  static const double _horizontalWordmark = 128 / 280;
  static const double _horizontalTagline = 34 / 280;
  static const double _horizontalGap = 50 / 280;
  static const double _stackedWordmark = 96 / 288;
  static const double _stackedTagline = 28 / 288;
  // Smaller than the SVG gap because Flutter's line box adds space above
  // the capitals; the visible gap ends up the same.
  static const double _stackedGap = 26 / 288;

  @override
  Widget build(BuildContext context) {
    final Widget logo = switch (variant) {
      AppLogoVariant.icon => _svg(BrandAssets.icon),
      AppLogoVariant.mark => _svg(BrandAssets.mark),
      AppLogoVariant.horizontal => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _svg(BrandAssets.icon),
          SizedBox(width: size * _horizontalGap),
          _wordmarkBlock(
            wordmarkSize: size * _horizontalWordmark,
            taglineSize: size * _horizontalTagline,
            align: CrossAxisAlignment.start,
          ),
        ],
      ),
      AppLogoVariant.stacked => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _svg(BrandAssets.icon),
          SizedBox(height: size * _stackedGap),
          _wordmarkBlock(
            wordmarkSize: size * _stackedWordmark,
            taglineSize: size * _stackedTagline,
            align: CrossAxisAlignment.center,
          ),
        ],
      ),
      AppLogoVariant.wordmark => _wordmarkBlock(
        wordmarkSize: size * _stackedWordmark,
        taglineSize: size * _stackedTagline,
        align: CrossAxisAlignment.center,
      ),
    };

    return Semantics(
      label: 'BrAInBox logo',
      image: true,
      child: ExcludeSemantics(child: logo),
    );
  }

  Widget _svg(String asset) => SvgPicture.asset(
    asset,
    package: BrandAssets.package,
    height: size,
    // The icon is square; the mark keeps its own aspect ratio.
    width: asset == BrandAssets.icon ? size : null,
  );

  Widget _wordmarkBlock({
    required double wordmarkSize,
    required double taglineSize,
    required CrossAxisAlignment align,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        _Wordmark(fontSize: wordmarkSize, onDark: onDark),
        if (showTagline) ...[
          SizedBox(height: taglineSize * 0.5),
          Text(
            BrandAssets.tagline,
            maxLines: 1,
            softWrap: false,
            // The logo keeps its proportions, so it ignores the text scale.
            textScaler: TextScaler.noScaling,
            style: GoogleFonts.inter(
              fontSize: taglineSize,
              fontWeight: FontWeight.w500,
              color: onDark ? AppColors.taglineOnDark : AppColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

/// "Br" + "AI" + "nBox" in Poppins Bold, with "AI" highlighted.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.fontSize, required this.onDark});

  final double fontSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: 1.1,
      // The SVG uses -2 at 128 px.
      letterSpacing: -fontSize / 64,
      color: onDark ? AppColors.white : AppColors.ink,
    );
    final highlight = base.copyWith(
      color: onDark ? AppColors.aiHighlightOnDark : AppColors.primary,
    );
    return RichText(
      maxLines: 1,
      softWrap: false,
      textScaler: TextScaler.noScaling,
      text: TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Br'),
          TextSpan(text: 'AI', style: highlight),
          const TextSpan(text: 'nBox'),
        ],
      ),
    );
  }
}
