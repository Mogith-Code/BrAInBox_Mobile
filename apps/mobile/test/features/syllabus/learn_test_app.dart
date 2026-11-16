import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/notes/presentation/library_screen.dart';
import 'package:brainbox_mobile/features/syllabus/data/learn_repository.dart';
import 'package:brainbox_mobile/features/syllabus/data/mock_learn_repository.dart';
import 'package:brainbox_mobile/features/syllabus/presentation/syllabus_screen.dart';
import 'package:brainbox_mobile/features/syllabus/presentation/topic_screen.dart';
import 'package:brainbox_mobile/features/syllabus/presentation/unit_detail_screen.dart';
import 'package:brainbox_mobile/features/upload/presentation/upload_detail_screen.dart';
import 'package:brainbox_mobile/features/upload/presentation/upload_sheet.dart';
import 'package:brainbox_mobile/features/upload/presentation/uploads_screen.dart';
import 'package:brainbox_mobile/features/visuals/data/fake_visuals_repository.dart';
import 'package:brainbox_mobile/features/visuals/data/visuals_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A fresh mock with no delays.
MockLearnRepository fastMock() =>
    MockLearnRepository(latency: Duration.zero, pollsUntilDone: 2);

/// The Learn screens on [repository], at 360×800 (the smallest phone we
/// support). Other routes show `AT <uri>`.
Future<GoRouter> pumpLearnApp(
  WidgetTester tester, {
  required LearnRepository repository,
  String initialLocation = AppRoutes.learn,
  UploadFilePicker? picker,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Widget at(GoRouterState state) => Scaffold(body: Text('AT ${state.uri}'));
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: AppRoutes.learn, builder: (_, _) => const SyllabusScreen()),
      GoRoute(
        path: AppRoutes.unitDetail,
        builder: (_, s) =>
            UnitDetailScreen(unitId: s.pathParameters['unitId']!),
      ),
      for (final path in [AppRoutes.unitTopic, AppRoutes.topic])
        GoRoute(
          path: path,
          builder: (_, s) => TopicScreen(topicId: s.pathParameters['topicId']!),
        ),
      GoRoute(
        path: AppRoutes.notesLibrary,
        builder: (_, _) => const LibraryScreen(),
      ),
      GoRoute(
        path: AppRoutes.uploads,
        builder: (_, _) => picker == null
            ? const UploadsScreen()
            : UploadsScreen(picker: picker),
      ),
      GoRoute(
        path: AppRoutes.uploadDetail,
        builder: (_, s) =>
            UploadDetailScreen(uploadId: s.pathParameters['uploadId']!),
      ),
      GoRoute(path: AppRoutes.ask, builder: (_, s) => at(s)),
      GoRoute(path: AppRoutes.quizSetup, builder: (_, s) => at(s)),
      // The Diagrams tab's "Generate a new visual" card opens this.
      GoRoute(path: AppRoutes.generateVisual, builder: (_, s) => at(s)),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        learnRepositoryProvider.overrideWithValue(repository),
        learnPollIntervalProvider.overrideWithValue(Duration.zero),
        // The topic's Diagrams tab is the visuals gallery.
        visualsRepositoryProvider.overrideWithValue(
          FakeVisualsRepository(step: Duration.zero),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
