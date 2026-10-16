import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/evaluation_models.dart';

part 'evaluation_repository.g.dart';

/// Data layer for the Evaluation feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class EvaluationRepository {
  EvaluationRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Evaluation screen.
  Future<EvaluationSummary> fetchSummary() async {
    // TODO(keshomigha): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/evaluations/$evaluationId');
    // return EvaluationSummary.fromJson(json);
    return const EvaluationSummary(
      title: 'Typed answer',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(keshomigha): add one method per endpoint, e.g.
  //   POST /evaluations/typed  ->  Evaluate a typed answer (returns a job id)
  //   POST /evaluations/handwritten  ->  Multipart photo upload, OCR + evaluation (job id)
}

@riverpod
EvaluationRepository evaluationRepository(Ref ref) =>
    EvaluationRepository(ref.watch(apiClientProvider));
