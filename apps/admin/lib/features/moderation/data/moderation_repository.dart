import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/moderation_models.dart';

part 'moderation_repository.g.dart';

/// Data layer for the Moderation feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class ModerationRepository {
  ModerationRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Moderation screen.
  Future<ModerationSummary> fetchSummary() async {
    // TODO(mogith): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/admin/reports');
    // return ModerationSummary.fromJson(json);
    return const ModerationSummary(
      title: 'Moderation',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(mogith): add one method per endpoint, e.g.
  //   POST /admin/posts/{post_id}/hide  ->  Hide a post
  //   POST /admin/groups/{group_id}/lock  ->  Lock a group
}

@riverpod
ModerationRepository moderationRepository(Ref ref) =>
    ModerationRepository(ref.watch(apiClientProvider));
