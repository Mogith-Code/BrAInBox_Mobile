import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/insights/data/insights_repository.dart';
import 'package:brainbox_mobile/features/insights/domain/insights_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInsightsRepository extends Mock implements InsightsRepository {}

/// A repository that answers every call with [json] (or [error]).
MockInsightsRepository fakeRepository({
  Map<String, dynamic>? json,
  Object? error,
}) {
  final repository = MockInsightsRepository();
  when(
    () => repository.fetchTopicInsights(attemptId: any(named: 'attemptId')),
  ).thenAnswer(
    (_) => error != null
        ? Future<TopicInsights>.error(error)
        : Future.value(TopicInsights.fromJson(json!)),
  );
  return repository;
}

/// Pumps [screen] with the app theme and a fake repository, on a tall
/// surface so the whole list is built.
Future<void> pumpInsights(
  WidgetTester tester,
  Widget screen,
  InsightsRepository repository, {
  ThemeMode themeMode = ThemeMode.light,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(420, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [insightsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: screen,
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}
