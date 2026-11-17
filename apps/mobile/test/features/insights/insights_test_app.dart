import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/insights/data/insights_repository.dart';
import 'package:brainbox_mobile/features/insights/domain/insights_models.dart';
import 'package:brainbox_mobile/features/insights/domain/progress_models.dart';
import 'package:brainbox_mobile/features/insights/domain/unit_insights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'insights_fixtures.dart';

class MockInsightsRepository extends Mock implements InsightsRepository {}

/// A repository that answers every topics call with [json] (or [error]),
/// every units call with [unitsJson] (default [sampleUnitsJson]) or
/// [unitsError], the overview with [overviewJson] (default
/// [sampleOverviewJson]) or [overviewError], and the heatmap with
/// [heatmapJson] (default [sampleHeatmapJson]) or [heatmapError].
MockInsightsRepository fakeRepository({
  Map<String, dynamic>? json,
  Object? error,
  Map<String, dynamic>? unitsJson,
  Object? unitsError,
  Map<String, dynamic>? overviewJson,
  Object? overviewError,
  Map<String, dynamic>? heatmapJson,
  Object? heatmapError,
}) {
  final repository = MockInsightsRepository();
  when(
    () => repository.fetchTopicInsights(attemptId: any(named: 'attemptId')),
  ).thenAnswer(
    (_) => error != null
        ? Future<TopicInsights>.error(error)
        : Future.value(TopicInsights.fromJson(json!)),
  );
  stubUnits(repository, json: unitsJson, error: unitsError);
  stubProgress(
    repository,
    overviewJson: overviewJson,
    overviewError: overviewError,
    heatmapJson: heatmapJson,
    heatmapError: heatmapError,
  );
  return repository;
}

/// Answers `fetchOverview` and `fetchHeatmap` (defaults: the sample
/// fixtures).
void stubProgress(
  MockInsightsRepository repository, {
  Map<String, dynamic>? overviewJson,
  Object? overviewError,
  Map<String, dynamic>? heatmapJson,
  Object? heatmapError,
}) {
  when(repository.fetchOverview).thenAnswer(
    (_) => overviewError != null
        ? Future<InsightsOverview>.error(overviewError)
        : Future.value(
            InsightsOverview.fromJson(overviewJson ?? sampleOverviewJson()),
          ),
  );
  when(repository.fetchHeatmap).thenAnswer(
    (_) => heatmapError != null
        ? Future<TopicHeatmap>.error(heatmapError)
        : Future.value(
            TopicHeatmap.fromJson(heatmapJson ?? sampleHeatmapJson()),
          ),
  );
}

/// Answers `fetchUnitInsights` with [json] (default [sampleUnitsJson]) or
/// [error].
void stubUnits(
  MockInsightsRepository repository, {
  Map<String, dynamic>? json,
  Object? error,
}) {
  when(repository.fetchUnitInsights).thenAnswer(
    (_) => error != null
        ? Future<UnitInsights>.error(error)
        : Future.value(UnitInsights.fromJson(json ?? sampleUnitsJson())),
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
