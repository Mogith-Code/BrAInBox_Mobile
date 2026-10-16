import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Notes library screen - All saved and uploaded notes.
///
/// Route: `/notes/library`
///
// TODO(samni): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes library')),
      body: FeaturePlaceholder(
        title: 'Notes library',
        owner: 'Samni',
        description: 'All saved and uploaded notes.',
        actionLabel: 'Upload notes',
        onAction: () => context.push(AppRoutes.upload),
      ),
    );
  }
}
