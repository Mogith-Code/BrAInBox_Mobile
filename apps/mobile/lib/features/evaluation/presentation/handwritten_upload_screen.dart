import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Handwritten answer screen - Take a photo of a handwritten answer (camera / image_picker).
///
/// Route: `/evaluation/handwritten/:questionId`
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class HandwrittenUploadScreen extends StatelessWidget {
  const HandwrittenUploadScreen({super.key, required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Handwritten answer')),
      body: FeaturePlaceholder(
        title: 'Handwritten answer',
        owner: 'Keshomigha',
        description:
            'Take a photo of a handwritten answer (camera / image_picker). (questionId: $questionId)',
        actionLabel: 'Preview OCR text',
        onAction: () => context.push(AppRoutes.ocrPreview),
      ),
    );
  }
}
