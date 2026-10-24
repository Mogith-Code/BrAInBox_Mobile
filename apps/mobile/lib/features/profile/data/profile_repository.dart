import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dev/fake_backend.dart';
import '../domain/profile_models.dart';
import 'fake_profile_repository.dart';

part 'profile_repository.g.dart';

/// Profile setup data. Only this layer calls the API.
abstract interface class ProfileRepository {
  /// `GET /profile/options`
  Future<ProfileOptions> options();

  /// `GET /profile` (to resume where the student left off)
  Future<Profile> profile();

  /// `PATCH /profile` with only the fields of one step (snake_case keys).
  Future<Profile> update(Map<String, dynamic> fields);

  /// `POST /profile/complete` (throws `PROFILE_INCOMPLETE` if a step is
  /// missing).
  Future<Profile> complete();
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this.api);

  final ApiClient api;

  @override
  Future<ProfileOptions> options() async => ProfileOptions.fromJson(
    await api.get<Map<String, dynamic>>('/profile/options'),
  );

  @override
  Future<Profile> profile() async =>
      Profile.fromJson(await api.get<Map<String, dynamic>>('/profile'));

  @override
  Future<Profile> update(Map<String, dynamic> fields) async => Profile.fromJson(
    await api.patch<Map<String, dynamic>>('/profile', data: fields),
  );

  @override
  Future<Profile> complete() async => Profile.fromJson(
    await api.post<Map<String, dynamic>>('/profile/complete'),
  );
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => Env.useFakeApi
    ? FakeProfileRepository(ref.watch(fakeBackendProvider))
    : ApiProfileRepository(ref.watch(apiClientProvider));
