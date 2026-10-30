import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/auth/application/session_controller.dart';
import 'package:brainbox_mobile/features/profile/application/profile_setup_controller.dart';
import 'package:brainbox_mobile/features/profile/data/fake_profile_repository.dart';
import 'package:brainbox_mobile/features/profile/data/profile_repository.dart';
import 'package:brainbox_mobile/features/profile/domain/profile_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _FakeSession extends Session {
  int refreshed = 0;

  @override
  Future<SessionState> build() async => const SessionState(welcomeSeen: true);

  @override
  Future<void> refresh() async => refreshed++;
}

final _options = ProfileOptions.fromJson(FakeProfileRepository.optionsJson);

void main() {
  late _MockProfileRepository repo;
  late _FakeSession session;
  late ProviderContainer c;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    repo = _MockProfileRepository();
    session = _FakeSession();
    when(() => repo.options()).thenAnswer((_) async => _options);
    c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        sessionProvider.overrideWith(() => session),
      ],
    );
    addTearDown(c.dispose);
  });

  /// Starts (or restarts) the controller, kept alive like a screen would.
  Future<ProfileSetupState> load() {
    final sub = c.listen(profileSetupControllerProvider, (_, _) {});
    addTearDown(sub.close);
    return c.read(profileSetupControllerProvider.future);
  }

  test('a new student starts at step 1 with sensible defaults', () async {
    when(() => repo.profile()).thenAnswer((_) async => const Profile());
    final s = await load();
    expect(s.step, 0);
    expect(s.stream, 'biological_science'); // the only stream
    expect(s.subject, 'biology'); // first available subject
    expect(s.confidence, 50);
    expect(s.stepComplete, isTrue);
  });

  test('resumes at the first unsaved step', () async {
    when(() => repo.profile()).thenAnswer(
      (_) async =>
          const Profile(stream: 'biological_science', subject: 'biology'),
    );
    expect((await load()).step, 1);

    when(() => repo.profile()).thenAnswer(
      (_) async => const Profile(
        stream: 'biological_science',
        subject: 'biology',
        examYear: 2027,
        targetGrade: 'A',
        confidence: 40,
      ),
    );
    c.invalidate(profileSetupControllerProvider);
    final s = await load();
    expect(s.step, 2);
    expect(s.confidence, 40);
  });

  test('"Coming soon" subjects cannot be selected', () async {
    when(() => repo.profile()).thenAnswer((_) async => const Profile());
    await load();
    c
        .read(profileSetupControllerProvider.notifier)
        .selectSubject(_options.subjects.firstWhere((s) => !s.available));
    expect(c.read(profileSetupControllerProvider).value!.subject, 'biology');
  });

  test('Continue sends only this step with PATCH, back keeps values', () async {
    when(() => repo.profile()).thenAnswer((_) async => const Profile());
    when(() => repo.update(any())).thenAnswer((_) async => const Profile());
    await load();
    final ctrl = c.read(profileSetupControllerProvider.notifier);

    expect(await ctrl.next(), isFalse); // not the last step
    verify(
      () => repo.update({'stream': 'biological_science', 'subject': 'biology'}),
    ).called(1);
    expect(c.read(profileSetupControllerProvider).value!.step, 1);

    ctrl
      ..setTargetGrade('A')
      ..setConfidence(55)
      ..setExamYear(2028);
    expect(ctrl.back(), isTrue);
    expect(c.read(profileSetupControllerProvider).value!.step, 0);
    await ctrl.next();
    final s = c.read(profileSetupControllerProvider).value!;
    expect(s.step, 1);
    expect(s.targetGrade, 'A'); // kept
    expect(s.confidence, 55);
    expect(s.examYear, 2028);
  });

  test(
    'Finish setup patches step 3, completes, refreshes the session',
    () async {
      when(() => repo.profile()).thenAnswer(
        (_) async => const Profile(
          stream: 'biological_science',
          subject: 'biology',
          examYear: 2027,
          targetGrade: 'A',
          confidence: 50,
        ),
      );
      when(() => repo.update(any())).thenAnswer((_) async => const Profile());
      when(
        () => repo.complete(),
      ).thenAnswer((_) async => const Profile(profileCompleted: true));
      await load();
      final ctrl = c.read(profileSetupControllerProvider.notifier)
        ..setStudyDays({'sun', 'mon', 'tue'})
        ..setHoursPerDay(2)
        ..setPreferredTime('evening');
      expect(c.read(profileSetupControllerProvider).value!.weeklyHours, 6);

      expect(await ctrl.next(), isTrue);
      verify(
        () => repo.update({
          'study_days': ['mon', 'tue', 'sun'], // week order
          'hours_per_day': 2.0,
          'preferred_time': 'evening',
        }),
      ).called(1);
      verify(() => repo.complete()).called(1);
      expect(session.refreshed, 1);
    },
  );

  test('an API error is shown and the step stays', () async {
    when(() => repo.profile()).thenAnswer((_) async => const Profile());
    when(
      () => repo.update(any()),
    ).thenThrow(const ApiException(code: 'network', message: 'offline'));
    await load();
    expect(
      await c.read(profileSetupControllerProvider.notifier).next(),
      isFalse,
    );
    final s = c.read(profileSetupControllerProvider).value!;
    expect(s.step, 0);
    expect(s.saving, isFalse);
    expect(s.error, 'No internet connection. Check it and try again.');
  });
}
