import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/question_bank_models.dart';

part 'question_bank_repository.g.dart';

/// Data layer for the QuestionBank feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class QuestionBankRepository {
  QuestionBankRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main QuestionBank screen.
  Future<QuestionBankSummary> fetchSummary() async {
    // TODO(udith): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/admin/questions');
    // return QuestionBankSummary.fromJson(json);
    return const QuestionBankSummary(
      title: 'Question bank',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(udith): add one method per endpoint, e.g.
  //   POST /admin/questions  ->  Create a question
  //   POST /admin/questions/import  ->  Bulk import (multipart CSV)
}

@riverpod
QuestionBankRepository questionBankRepository(Ref ref) =>
    QuestionBankRepository(ref.watch(apiClientProvider));
