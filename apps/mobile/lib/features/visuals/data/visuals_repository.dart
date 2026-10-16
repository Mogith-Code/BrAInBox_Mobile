import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/visuals_models.dart';

part 'visuals_repository.g.dart';

/// Data layer for the Visuals feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class VisualsRepository {
  VisualsRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Visuals screen.
  Future<VisualsSummary> fetchSummary() async {
    // TODO(mogith): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/topics/$topicId/visuals');
    // return VisualsSummary.fromJson(json);
    return const VisualsSummary(
      title: 'Diagrams',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(mogith): add one method per endpoint, e.g.
  //   GET /visuals/{visual_id}  ->  One diagram
  //   POST /visuals/generate  ->  Start AI visual generation (returns a job id)
}

@riverpod
VisualsRepository visualsRepository(Ref ref) =>
    VisualsRepository(ref.watch(apiClientProvider));
