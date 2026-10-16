import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/practice_models.dart';

part 'practice_repository.g.dart';

/// Data layer for the Practice feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class PracticeRepository {
  PracticeRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Practice screen.
  Future<PracticeSummary> fetchSummary() async {
    // TODO(udith): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/practice/hub');
    // return PracticeSummary.fromJson(json);
    return const PracticeSummary(
      title: 'Practice',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(udith): add one method per endpoint, e.g.
  //   POST /quizzes  ->  Create a quiz from the setup options
  //   GET /quizzes/{quiz_id}/questions  ->  Questions for a quiz
  //   POST /quizzes/{quiz_id}/answers  ->  Submit one answer, get feedback
  //   GET /quizzes/{quiz_id}/result  ->  Final result
  //   POST /diagnostic  ->  Start the diagnostic test
}

@riverpod
PracticeRepository practiceRepository(Ref ref) =>
    PracticeRepository(ref.watch(apiClientProvider));
