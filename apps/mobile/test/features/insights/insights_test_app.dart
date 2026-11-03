import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/insights/data/insights_repository.dart';
import 'package:brainbox_mobile/features/insights/domain/insights_models.dart';
import 'package:brainbox_mobile/features/insights/domain/insights_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'insights_fixtures.dart';

class MockInsightsRepository extends Mock implements InsightsRepository {}

/// A repository that answers every topics call with [json] (or [error]) and
/// every summary call with [summaryJson] (or [summaryError]). The summary
/// defaults to [sampleSummaryJson].
MockInsightsRepository fakeRepository({
  Map<String, dynamic>? json,
  Object? error,
  Map<String, dynamic>? summaryJson,
  Object? summaryError,
}) {
  final repository = MockInsightsRepository();
  when(
    () => repository.fetchTopicInsights(attemptId: any(named: 'attemptId')),
  ).thenAnswer(
    (_) => error != null
        ? Future<TopicInsights>.error(error)
        : Future.value(TopicInsights.fromJson(json!)),
  );
  stubSummary(repository, json: summaryJson, error: summaryError);
  return repository;
}

/// Answers `fetchSummary` with [json] (default [sampleSummaryJson]) or
/// [error].
void stubSummary(
  MockInsightsRepository repository, {
  Map<String, dynamic>? json,
  Object? error,
}) {
  registerFallbackValue(InsightsPeriod.week);
  when(() => repository.fetchSummary(period: any(named: 'period'))).thenAnswer(
    (_) => error != null
        ? Future<InsightsSummary>.error(error)
        : Future.value(InsightsSummary.fromJson(json ?? sampleSummaryJson())),
  );
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
