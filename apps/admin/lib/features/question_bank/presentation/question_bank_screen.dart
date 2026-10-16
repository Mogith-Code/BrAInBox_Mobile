import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/question_bank_controller.dart';

/// Question bank screen - Searchable question table, filters, bulk import (CSV).
///
/// Route: `/question-bank`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class QuestionBankScreen extends ConsumerWidget {
  const QuestionBankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionBankControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorBanner(
          message: '$error',
          onRetry: () => ref.invalidate(questionBankControllerProvider),
        ),
      ),
      data: (summary) => FeaturePlaceholder(
        title: 'Question bank',
        owner: 'Udith',
        description:
            'Searchable question table, filters, bulk import (CSV).\n${summary.message}',
      ),
    );
  }
}
