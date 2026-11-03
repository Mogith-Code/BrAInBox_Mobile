import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';

/// The dark indigo "Ask BrAInBox" floating button (bottom right).
///
/// Opens the AI tutor, about [topicId] when given. [extended] = pill with
/// a label (Topic page); otherwise a round 56px ✦ button (Learn tab).
class AskBrainBoxButton extends StatelessWidget {
  const AskBrainBoxButton({super.key, this.topicId, this.extended = true});

  final String? topicId;
  final bool extended;

  static const _label = 'Ask BrAInBox';

  @override
  Widget build(BuildContext context) {
    void open() => context.push(AppRoutes.askPath(topicId: topicId));

    if (!extended) {
      return FloatingActionButton(
        // No hero: each tab has its own navigator and its own button.
        heroTag: null,
        tooltip: _label,
        onPressed: open,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.auto_awesome),
      );
    }
    return FloatingActionButton.extended(
      heroTag: null,
      tooltip: _label,
      onPressed: open,
      backgroundColor: AppColors.primaryDark,
      foregroundColor: AppColors.white,
      shape: const StadiumBorder(),
      icon: const Icon(Icons.auto_awesome, size: 20),
      label: Text(
        _label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
