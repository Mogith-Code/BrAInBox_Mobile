import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/upload_models.dart';

part 'upload_repository.g.dart';

/// Data layer for the Upload feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class UploadRepository {
  UploadRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Upload screen.
  Future<UploadSummary> fetchSummary() async {
    // TODO(samni): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/jobs/$jobId');
    // return UploadSummary.fromJson(json);
    return const UploadSummary(
      title: 'Upload notes',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(samni): add one method per endpoint, e.g.
  //   POST /uploads  ->  Multipart upload (returns a job id)
  //   GET /uploads/{upload_id}/summary  ->  AI summary of the upload
}

@riverpod
UploadRepository uploadRepository(Ref ref) =>
    UploadRepository(ref.watch(apiClientProvider));
