import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/profile_models.dart';

part 'profile_repository.g.dart';

/// Data layer for the Profile feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class ProfileRepository {
  ProfileRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Profile screen.
  Future<ProfileSummary> fetchSummary() async {
    // TODO(mogith): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/me');
    // return ProfileSummary.fromJson(json);
    return const ProfileSummary(
      title: 'Profile setup',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(mogith): add one method per endpoint, e.g.
  //   PUT /me/profile  ->  Save stream, exam year, goals, study time
}

@riverpod
ProfileRepository profileRepository(Ref ref) =>
    ProfileRepository(ref.watch(apiClientProvider));
