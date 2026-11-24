import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

/// The small "Demo data" corner ribbon shown on every screen while demo mode
/// is on, so viewers always know the AI answers are saved examples.
class DemoDataLabel extends StatelessWidget {
  const DemoDataLabel({super.key, required this.child});

  static const text = 'Demo data';

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$text: AI answers are saved examples',
      child: Banner(
        message: text,
        location: BannerLocation.bottomStart,
        color: AppColors.warningDark,
        textStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
        child: child,
      ),
    );
  }
}
