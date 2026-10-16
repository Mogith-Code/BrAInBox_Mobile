import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/community_models.dart';

part 'community_repository.g.dart';

/// Data layer for the Community feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class CommunityRepository {
  CommunityRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Community screen.
  Future<CommunitySummary> fetchSummary() async {
    // TODO(mogith): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/groups');
    // return CommunitySummary.fromJson(json);
    return const CommunitySummary(
      title: 'Community',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(mogith): add one method per endpoint, e.g.
  //   GET /groups/{group_id}/posts  ->  Posts in a group
  //   GET /posts/{post_id}  ->  One post with comments
  //   POST /groups/{group_id}/posts  ->  Create a post
  //   POST /posts/{post_id}/report  ->  Report a post to moderators
}

@riverpod
CommunityRepository communityRepository(Ref ref) =>
    CommunityRepository(ref.watch(apiClientProvider));
