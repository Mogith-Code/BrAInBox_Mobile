import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/notes_models.dart';

part 'notes_repository.g.dart';

/// Data layer for the Notes feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class NotesRepository {
  NotesRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Notes screen.
  Future<NotesSummary> fetchSummary() async {
    // TODO(samni): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/topics/$topicId/notes');
    // return NotesSummary.fromJson(json);
    return const NotesSummary(
      title: 'Topic notes',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(samni): add one method per endpoint, e.g.
  //   GET /topics/{topic_id}/short-notes  ->  Short notes for a topic
  //   POST /topics/{topic_id}/notes/generate  ->  Start AI note generation (returns a job id)
  //   GET /notes/library  ->  The student's saved notes
}

@riverpod
NotesRepository notesRepository(Ref ref) =>
    NotesRepository(ref.watch(apiClientProvider));
