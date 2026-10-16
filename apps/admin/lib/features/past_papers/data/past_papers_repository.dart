import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/past_papers_models.dart';

part 'past_papers_repository.g.dart';

/// Data layer for the PastPapers feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class PastPapersRepository {
  PastPapersRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main PastPapers screen.
  Future<PastPapersSummary> fetchSummary() async {
    // TODO(udith): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/admin/past-papers');
    // return PastPapersSummary.fromJson(json);
    return const PastPapersSummary(
      title: 'Past papers',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(udith): add one method per endpoint, e.g.
  //   POST /admin/past-papers  ->  Upload a paper (multipart)
  //   POST /admin/past-papers/{paper_id}/marking-scheme  ->  Upload its marking scheme
}

@riverpod
PastPapersRepository pastPapersRepository(Ref ref) =>
    PastPapersRepository(ref.watch(apiClientProvider));
