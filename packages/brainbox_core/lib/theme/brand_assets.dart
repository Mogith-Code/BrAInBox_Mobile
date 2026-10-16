/// Paths and text for the BrAInBox brand assets bundled in brainbox_core.
///
/// The SVGs live in `packages/brainbox_core/assets/brand/`, so load them with
/// `package: BrandAssets.package`. In most cases use the `AppLogo` widget
/// instead of these paths.
///
/// RULE: never render the wordmark SVGs (horizontal / stacked) in Flutter.
/// flutter_svg cannot use the Poppins font inside SVG `<text>`, so the
/// wordmark would show in the wrong font. `AppLogo` builds the wordmark in
/// Flutter instead. The wordmark SVGs are for docs and the web only.
abstract final class BrandAssets {
  /// Package that holds the brand assets.
  static const String package = 'brainbox_core';

  static const String _dir = 'assets/brand';

  /// Gradient rounded-square app icon. OK in the app UI.
  static const String icon = '$_dir/brainbox-icon.svg';

  /// Box + sprout only, no background. OK in the app UI.
  static const String mark = '$_dir/brainbox-mark.svg';

  // Docs / web ONLY - do not render these in Flutter (see the rule above).
  static const String logoHorizontal = '$_dir/brainbox-logo-horizontal.svg';
  static const String logoHorizontalWhite =
      '$_dir/brainbox-logo-horizontal-white.svg';
  static const String logoStacked = '$_dir/brainbox-logo-stacked.svg';
  static const String logoStackedWhite =
      '$_dir/brainbox-logo-stacked-white.svg';

  // Android adaptive launcher icon layers (source art for the generators).
  static const String adaptiveForeground = '$_dir/adaptive-foreground.svg';
  static const String adaptiveBackground = '$_dir/adaptive-background.svg';

  /// The product name. Note the capital "AI".
  static const String appName = 'BrAInBox';

  /// The brand tagline.
  static const String tagline = 'Study smarter. Fix what matters.';
}
