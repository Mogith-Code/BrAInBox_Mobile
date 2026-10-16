import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/mcq_mapping_models.dart';

part 'mcq_mapping_repository.g.dart';

/// Data layer for the McqMapping feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class McqMappingRepository {
  McqMappingRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main McqMapping screen.
  Future<McqMappingSummary> fetchSummary() async {
    // TODO(udith): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/admin/questions/$questionId');
    // return McqMappingSummary.fromJson(json);
    return const McqMappingSummary(
      title: 'MCQ mapping',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(udith): add one method per endpoint, e.g.
  //   PUT /admin/options/{option_id}/misconception  ->  Set the misconception tag
}

@riverpod
McqMappingRepository mcqMappingRepository(Ref ref) =>
    McqMappingRepository(ref.watch(apiClientProvider));
