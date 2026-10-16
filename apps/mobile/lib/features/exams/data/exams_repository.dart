import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/exams_models.dart';

part 'exams_repository.g.dart';

/// Data layer for the Exams feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class ExamsRepository {
  ExamsRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Exams screen.
  Future<ExamsSummary> fetchSummary() async {
    // TODO(udith): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/past-papers');
    // return ExamsSummary.fromJson(json);
    return const ExamsSummary(
      title: 'Past papers',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(udith): add one method per endpoint, e.g.
  //   POST /model-papers/generate  ->  Start model paper generation (returns a job id)
  //   POST /exam-attempts  ->  Start an exam attempt
  //   POST /exam-attempts/{attempt_id}/submit  ->  Submit answers
}

@riverpod
ExamsRepository examsRepository(Ref ref) =>
    ExamsRepository(ref.watch(apiClientProvider));
