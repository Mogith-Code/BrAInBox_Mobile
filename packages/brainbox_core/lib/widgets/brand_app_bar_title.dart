import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_logo.dart';

/// An app bar title with the small BrAInBox icon on its left.
///
/// ```dart
/// AppBar(title: const BrandAppBarTitle('Learn'))
/// ```
class BrandAppBarTitle extends StatelessWidget {
  const BrandAppBarTitle(this.title, {super.key, this.logoSize = 28});

  final String title;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
