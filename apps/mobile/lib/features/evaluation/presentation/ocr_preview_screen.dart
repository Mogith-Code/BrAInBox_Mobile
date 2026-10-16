import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// OCR preview screen - Check and fix the text read from the photo.
///
/// Route: `/evaluation/ocr-preview`
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class OcrPreviewScreen extends StatelessWidget {
  const OcrPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR preview')),
      body: FeaturePlaceholder(
        title: 'OCR preview',
        owner: 'Keshomigha',
        description: 'Check and fix the text read from the photo.',
        actionLabel: 'Get feedback',
        onAction: () => context.push(AppRoutes.evaluationFeedbackPath('demo')),
      ),
    );
  }
}
