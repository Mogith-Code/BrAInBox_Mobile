import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/syllabus_models.dart';

part 'syllabus_repository.g.dart';

/// Data layer for the Syllabus feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class SyllabusRepository {
  SyllabusRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Syllabus screen.
  Future<SyllabusSummary> fetchSummary() async {
    // TODO(keshomigha): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/units');
    // return SyllabusSummary.fromJson(json);
    return const SyllabusSummary(
      title: 'Learn',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(keshomigha): add one method per endpoint, e.g.
  //   GET /units/{unit_id}  ->  One unit with its topics
  //   GET /topics/{topic_id}  ->  One topic with its concepts
}

@riverpod
SyllabusRepository syllabusRepository(Ref ref) =>
    SyllabusRepository(ref.watch(apiClientProvider));
