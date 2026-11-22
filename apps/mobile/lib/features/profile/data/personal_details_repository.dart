import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who the student is: name, phone, bio and photo.
class PersonalDetails {
  const PersonalDetails({
    required this.fullName,
    this.email,
    this.phone,
    this.bio,
    this.avatarUrl,
  });

  factory PersonalDetails.fromJson(Map<String, dynamic> json) =>
      PersonalDetails(
        fullName: '${json['full_name'] ?? ''}',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  final String fullName;
  final String? email;
  final String? phone;
  final String? bio;
  final String? avatarUrl;
}

/// Edit profile data. Only this layer calls the API.
class PersonalDetailsRepository {
  PersonalDetailsRepository(this.api);

  final ApiClient api;

  /// `GET /profile/details`
  Future<PersonalDetails> load() async => PersonalDetails.fromJson(
    await api.get<Map<String, dynamic>>('/profile/details'),
  );

  /// Name and phone go to `PATCH /auth/me`, the bio to `PATCH /profile/details`.
  Future<PersonalDetails> save({
    required String fullName,
    required String phone,
    required String bio,
  }) async {
    await api.patch<Object?>(
      '/auth/me',
      data: {'full_name': fullName, 'phone': phone.isEmpty ? null : phone},
    );
    return PersonalDetails.fromJson(
      await api.patch<Map<String, dynamic>>(
        '/profile/details',
        data: {'bio': bio},
      ),
    );
  }

  /// `POST /profile/avatar`
  Future<PersonalDetails> uploadPhoto(List<int> bytes, String fileName) async =>
      PersonalDetails.fromJson(
        await api.uploadBytes<Map<String, dynamic>>(
          '/profile/avatar',
          bytes: bytes,
          fileName: fileName,
        ),
      );

  /// `DELETE /profile/avatar`
  Future<PersonalDetails> removePhoto() async => PersonalDetails.fromJson(
    await api.delete<Map<String, dynamic>>('/profile/avatar'),
  );
}

final personalDetailsRepositoryProvider = Provider<PersonalDetailsRepository>(
  (ref) => PersonalDetailsRepository(ref.watch(apiClientProvider)),
);

/// The saved details, loaded when Edit profile opens.
final personalDetailsProvider = FutureProvider.autoDispose<PersonalDetails>(
  (ref) => ref.watch(personalDetailsRepositoryProvider).load(),
);
