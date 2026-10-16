import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Group feed screen - Posts in a group.
///
/// Route: `/community/groups/:groupId`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class GroupFeedScreen extends StatelessWidget {
  const GroupFeedScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group feed')),
      body: FeaturePlaceholder(
        title: 'Group feed',
        owner: 'Mogith',
        description: 'Posts in a group. (groupId: $groupId)',
        actionLabel: 'Open a post',
        onAction: () => context.push(AppRoutes.postDetailPath('demo')),
      ),
    );
  }
}
