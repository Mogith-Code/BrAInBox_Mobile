import 'dart:io';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/dev/fake_backend.dart';
import 'package:brainbox_mobile/app/router.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/auth/application/session_controller.dart';
import 'package:brainbox_mobile/features/auth/data/auth_repository.dart';
import 'package:brainbox_mobile/features/auth/data/fake_auth_repository.dart';
import 'package:brainbox_mobile/features/home/data/fake_home_repository.dart';
import 'package:brainbox_mobile/features/home/data/home_repository.dart';
import 'package:brainbox_mobile/features/practice/data/diagnostic_repository.dart';
import 'package:brainbox_mobile/features/practice/data/fake_diagnostic_repository.dart';
import 'package:brainbox_mobile/features/profile/data/fake_profile_repository.dart';
import 'package:brainbox_mobile/features/profile/data/profile_overview_repository.dart';
import 'package:brainbox_mobile/features/profile/data/profile_repository.dart';
import 'package:brainbox_mobile/features/settings/data/settings_repository.dart';
import 'package:brainbox_mobile/features/community/data/community_repository.dart';
import 'package:brainbox_mobile/features/community/domain/community_models.dart';
import 'package:brainbox_mobile/features/insights/data/insights_repository.dart';
import 'package:brainbox_mobile/features/practice/data/practice_repository.dart';
import 'package:brainbox_mobile/features/practice/domain/practice_models.dart';
import 'package:brainbox_mobile/features/syllabus/data/learn_repository.dart';
import 'package:brainbox_mobile/features/visuals/data/fake_visuals_repository.dart';
import 'package:brainbox_mobile/features/visuals/data/visuals_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/community/community_fixtures.dart';
import '../features/insights/insights_fixtures.dart';
import '../features/insights/insights_test_app.dart' as insights;
import '../features/syllabus/learn_test_app.dart';

class _MockPracticeRepository extends Mock implements PracticeRepository {}

class _MockCommunityRepository extends Mock implements CommunityRepository {}

/// Text scale the main screens must survive without overflow.
const _textScale = 1.3;

/// The main screens a student uses every day.
const _screens = <String, String>{
  'Log in': AppRoutes.login,
  'Sign up': AppRoutes.signup,
  'Diagnostic': AppRoutes.diagnostic,
  'Home': AppRoutes.home,
  'Learn': AppRoutes.learn,
  'Practice': AppRoutes.practice,
  'Insights': AppRoutes.insights,
  'Groups': AppRoutes.community,
  'Settings': AppRoutes.settings,
  'Data & privacy': AppRoutes.privacy,
};

/// Loads Roboto from the Flutter SDK so text has real glyph widths.
///
/// The default test font draws every glyph 1 em wide, which is much wider
/// than Inter and would report overflows that never happen on a phone.
/// Roboto is within a few percent of Inter, so the 1.3 check is realistic.
Future<bool> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return false;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return false;
  final loader = FontLoader('Roboto');
  for (final name in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]) {
    final file = File('${dir.path}/$name');
    if (!file.existsSync()) continue;
    final bytes = file.readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
  return true;
}

ThemeData _withRoboto(ThemeData theme, bool hasRoboto) => !hasRoboto
    ? theme
    : theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
        primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
      );

void main() {
  var hasRoboto = false;
  setUpAll(() async {
    registerFallbackValue(ReportReason.spam);
    hasRoboto = await _loadRoboto();
  });

  Future<void> pump(
    WidgetTester tester, {
    required String location,
    required ThemeMode themeMode,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final backend = FakeBackend(latency: Duration.zero);
    backend.setSignedIn(backend.accounts['nethmi.p@gmail.com']);

    final practice = _MockPracticeRepository();
    when(practice.fetchHub).thenAnswer(
      (_) async => const PracticeHub(
        inProgress: QuizBrief(
          quizId: 'q1',
          title: 'Quiz: Genetics and inheritance',
          status: 'in_progress',
          total: 10,
        ),
        recent: [
          QuizBrief(
            quizId: 'q0',
            title: 'Mixed quiz',
            status: 'graded',
            total: 10,
            score: 7,
            percent: 70,
          ),
        ],
        openMistakes: 3,
        weakConcepts: 2,
      ),
    );

    final community = _MockCommunityRepository();
    when(community.fetchGroups).thenAnswer(
      (_) async => [
        StudyGroup.fromJson(
          groupJson(
            id: 'g0',
            name: 'General',
            slug: 'general',
            isDefault: true,
            isMember: true,
            members: 120,
          ),
        ),
        StudyGroup.fromJson(
          groupJson(id: 'g6', name: 'Genetics', slug: 'unit-6', unitId: 'u-6'),
        ),
      ],
    );

    SharedPreferences.setMockInitialValues({'welcome_seen': true});
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        // The fake backend, signed in and onboarded, redirect off so the
        // auth screens open too.
        fakeBackendProvider.overrideWithValue(backend),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(backend)),
        profileRepositoryProvider.overrideWithValue(
          FakeProfileRepository(backend),
        ),
        profileOverviewRepositoryProvider.overrideWithValue(
          FakeProfileOverviewRepository(backend),
        ),
        diagnosticRepositoryProvider.overrideWithValue(
          FakeDiagnosticRepository(backend),
        ),
        homeRepositoryProvider.overrideWithValue(FakeHomeRepository(backend)),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        authGuardEnabledProvider.overrideWithValue(false),
        practiceRepositoryProvider.overrideWithValue(practice),
        communityRepositoryProvider.overrideWithValue(community),
        insightsRepositoryProvider.overrideWithValue(
          insights.fakeRepository(json: sampleInsightsJson()),
        ),
        learnRepositoryProvider.overrideWithValue(fastMock()),
        learnPollIntervalProvider.overrideWithValue(Duration.zero),
        visualsRepositoryProvider.overrideWithValue(
          FakeVisualsRepository(step: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: _withRoboto(AppTheme.light, hasRoboto),
          darkTheme: _withRoboto(AppTheme.dark, hasRoboto),
          themeMode: themeMode,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(_textScale)),
            child: child!,
          ),
        ),
      ),
    );
    router.go(location);
    await tester.pumpAndSettle();
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    group('${mode.name} mode, text x$_textScale, 360 dp', () {
      for (final MapEntry(key: title, value: location) in _screens.entries) {
        testWidgets(title, (tester) async {
          final semantics = tester.ensureSemantics();
          await pump(tester, location: location, themeMode: mode);

          // A RenderFlex overflow is reported as an exception.
          expect(tester.takeException(), isNull, reason: 'overflow');

          // Every tappable thing has a label (icon-only buttons need a
          // tooltip or Semantics) and is at least 48 x 48.
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

          // Text is readable on its background (WCAG AA) - this is the
          // dark-mode check that matters most.
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          semantics.dispose();
        });
      }
    });
  }
}
