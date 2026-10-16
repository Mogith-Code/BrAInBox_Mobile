import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/knowledge_base_models.dart';

part 'knowledge_base_repository.g.dart';

/// Data layer for the KnowledgeBase feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class KnowledgeBaseRepository {
  KnowledgeBaseRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main KnowledgeBase screen.
  Future<KnowledgeBaseSummary> fetchSummary() async {
    // TODO(keshomigha): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/admin/model-answers');
    // return KnowledgeBaseSummary.fromJson(json);
    return const KnowledgeBaseSummary(
      title: 'Knowledge base',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(keshomigha): add one method per endpoint, e.g.
  //   POST /admin/model-answers  ->  Add a model answer
  //   PUT /admin/model-answers/{answer_id}/keywords  ->  Edit keywords
}

@riverpod
KnowledgeBaseRepository knowledgeBaseRepository(Ref ref) =>
    KnowledgeBaseRepository(ref.watch(apiClientProvider));
