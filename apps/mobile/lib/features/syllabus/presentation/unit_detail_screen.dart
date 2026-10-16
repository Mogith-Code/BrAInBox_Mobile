import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Unit detail screen - Topics in this unit.
///
/// Route: `/learn/units/:unitId`
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class UnitDetailScreen extends StatelessWidget {
  const UnitDetailScreen({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unit detail')),
      body: FeaturePlaceholder(
        title: 'Unit detail',
        owner: 'Keshomigha',
        description: 'Topics in this unit. (unitId: $unitId)',
        actionLabel: 'Open a topic',
        onAction: () => context.push(AppRoutes.topicPath('demo')),
      ),
    );
  }
}
