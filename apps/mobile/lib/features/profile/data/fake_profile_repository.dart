import 'package:brainbox_core/brainbox_core.dart';

import '../../../app/dev/fake_backend.dart';
import '../domain/profile_models.dart';
import 'profile_repository.dart';

/// DEBUG ONLY: [ProfileRepository] on the in-memory [FakeBackend], with the
/// options from the Figma screens.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.backend);

  final FakeBackend backend;

  static const optionsJson = {
    'streams': [
      {'id': 'biological_science', 'name': 'Biological Science'},
    ],
    'subjects': [
      {
        'id': 'biology',
        'name': 'Biology',
        'units': 10,
        'syllabus': '2025 syllabus',
        'available': true,
      },
      {'id': 'chemistry', 'name': 'Chemistry', 'available': false},
      {'id': 'physics', 'name': 'Physics', 'available': false},
    ],
    'exam_years': [2026, 2027, 2028],
    'target_grades': ['A', 'B', 'C'],
    'preferred_times': [
      {'id': 'morning', 'label': 'Morning', 'hint': '5–9 AM'},
      {'id': 'evening', 'label': 'Evening', 'hint': '4–8 PM'},
      {'id': 'night', 'label': 'Night', 'hint': '8 PM+'},
    ],
  };

  Map<String, dynamic> get _store => backend.requireSignedIn().profile;

  Profile _out() {
    final p = _store;
    final days = (p['study_days'] as List?)?.length ?? 0;
    final hours = (p['hours_per_day'] as num?)?.toDouble();
    return Profile.fromJson({
      ...p,
      'weekly_hours': hours == null ? null : days * hours,
      'profile_completed': backend
          .requireSignedIn()
          .onboarding
          .profileCompleted,
    });
  }

  @override
  Future<ProfileOptions> options() async {
    await backend.delay();
    return ProfileOptions.fromJson(optionsJson);
  }

  @override
  Future<Profile> profile() async {
    await backend.delay();
    return _out();
  }

  @override
  Future<Profile> update(Map<String, dynamic> fields) async {
    await backend.delay();
    _store.addAll(fields);
    return _out();
  }

  @override
  Future<Profile> complete() async {
    await backend.delay();
    const required = [
      'stream',
      'subject',
      'exam_year',
      'target_grade',
      'confidence',
      'hours_per_day',
      'preferred_time',
    ];
    final p = _store;
    final missing =
        required.any((k) => p[k] == null) ||
        ((p['study_days'] as List?)?.isEmpty ?? true);
    if (missing) {
      throw const ApiException(
        code: 'PROFILE_INCOMPLETE',
        message: 'Profile incomplete.',
        statusCode: 400,
      );
    }
    final account = backend.requireSignedIn();
    account.onboarding = account.onboarding.copyWith(profileCompleted: true);
    return _out();
  }
}
