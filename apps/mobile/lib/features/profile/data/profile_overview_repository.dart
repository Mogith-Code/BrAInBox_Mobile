import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dev/fake_backend.dart';
import '../domain/profile_overview_models.dart';

part 'profile_overview_repository.g.dart';

/// The Profile page and achievements. Only this layer calls the API.
abstract interface class ProfileOverviewRepository {
  /// `GET /profile/overview`
  Future<ProfileOverview> overview();

  /// `POST /achievements/{id}/seen` - the pop-up was shown.
  Future<void> markSeen(String achievementId);
}

class ApiProfileOverviewRepository implements ProfileOverviewRepository {
  ApiProfileOverviewRepository(this.api);

  final ApiClient api;

  @override
  Future<ProfileOverview> overview() async => ProfileOverview.fromJson(
    await api.get<Map<String, dynamic>>('/profile/overview'),
  );

  @override
  Future<void> markSeen(String achievementId) =>
      api.post<Object?>('/achievements/$achievementId/seen');
}

/// DEBUG ONLY (`USE_FAKE_API=true`): the Figma F1 profile, with one new
/// badge ("Genetics fixer") so the F8 pop-up shows once.
class FakeProfileOverviewRepository implements ProfileOverviewRepository {
  FakeProfileOverviewRepository(this.backend);

  final FakeBackend backend;
  final _seen = <String>{};

  @override
  Future<ProfileOverview> overview() async {
    await backend.delay();
    final account = backend.requireSignedIn();
    Achievement badge(
      String id,
      String title,
      String icon, {
      bool unlocked = true,
      String description = '',
      String? label,
      int? xp,
    }) => Achievement(
      id: id,
      title: title,
      icon: icon,
      unlocked: unlocked,
      description: description,
      badgeLabel: label,
      xp: xp,
      seen: !unlocked || id != 'genetics_fixer' || _seen.contains(id),
    );
    return ProfileOverview(
      fullName: account.fullName,
      streamLabel: 'Biological Science',
      examYear: 2027,
      targetGrade: 'A',
      daysToExam: 287,
      streakDays: 12,
      questionsAnswered: 438,
      topicsMastered: 9,
      achievementsTotal: 18,
      achievements: [
        badge('streak_12', '12-day streak', 'streak'),
        badge('first_mastery', 'First mastery', 'first_mastery'),
        badge(
          'genetics_fixer',
          'Genetics fixer',
          'genetics_fixer',
          description: 'You took Genetics from Weak to Strong in 9 days.',
          label: 'Strong',
          xp: 150,
        ),
        badge('mcq_100', '100 MCQs', 'mcq_100'),
        badge(
          'past_paper_pro',
          'Past paper pro',
          'past_paper_pro',
          unlocked: false,
        ),
        badge('unit_master', 'Unit master', 'unit_master', unlocked: false),
      ],
    );
  }

  @override
  Future<void> markSeen(String achievementId) async => _seen.add(achievementId);
}

@Riverpod(keepAlive: true)
ProfileOverviewRepository profileOverviewRepository(Ref ref) => Env.useFakeApi
    ? FakeProfileOverviewRepository(ref.watch(fakeBackendProvider))
    : ApiProfileOverviewRepository(ref.watch(apiClientProvider));
