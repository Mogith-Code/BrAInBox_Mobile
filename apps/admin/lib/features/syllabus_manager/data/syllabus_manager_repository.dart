import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/syllabus_manager_models.dart';

part 'syllabus_manager_repository.g.dart';

/// Data layer for the SyllabusManager feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class SyllabusManagerRepository {
  SyllabusManagerRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main SyllabusManager screen.
  Future<SyllabusManagerSummary> fetchSummary() async {
    // TODO(keshomigha): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/admin/units');
    // return SyllabusManagerSummary.fromJson(json);
    return const SyllabusManagerSummary(
      title: 'Syllabus manager',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(keshomigha): add one method per endpoint, e.g.
  //   POST /admin/units  ->  Create a unit (same for /admin/topics, /admin/concepts)
  //   PUT /admin/topics/{topic_id}  ->  Edit a topic
  //   DELETE /admin/concepts/{concept_id}  ->  Delete a concept
}

@riverpod
SyllabusManagerRepository syllabusManagerRepository(Ref ref) =>
    SyllabusManagerRepository(ref.watch(apiClientProvider));
