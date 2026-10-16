import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The BrAInBox logo (SVG, bundled in brainbox_core).
///
/// ```dart
/// const AppLogo(size: 96)
/// ```
///
// TODO(samni): replace assets/logo/brainbox_logo.svg in brainbox_core with
// the real logo exported from Figma (keep the same file name).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64});

  final double size;

  static const String assetPath = 'assets/logo/brainbox_logo.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      package: 'brainbox_core',
      width: size,
      height: size,
      semanticsLabel: 'BrAInBox logo',
    );
  }
}
