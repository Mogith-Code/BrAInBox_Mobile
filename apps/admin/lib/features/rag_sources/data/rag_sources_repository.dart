import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/rag_sources_models.dart';

part 'rag_sources_repository.g.dart';

/// Data layer for the RagSources feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class RagSourcesRepository {
  RagSourcesRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main RagSources screen.
  Future<RagSourcesSummary> fetchSummary() async {
    // TODO(samni): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/admin/rag/sources');
    // return RagSourcesSummary.fromJson(json);
    return const RagSourcesSummary(
      title: 'RAG sources',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(samni): add one method per endpoint, e.g.
  //   POST /admin/rag/sources  ->  Upload a source (multipart, returns a job id)
  //   POST /admin/rag/reindex  ->  Re-index everything (job id)
}

@riverpod
RagSourcesRepository ragSourcesRepository(Ref ref) =>
    RagSourcesRepository(ref.watch(apiClientProvider));
