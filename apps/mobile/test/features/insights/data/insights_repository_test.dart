import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/insights/data/insights_repository.dart';
import 'package:brainbox_mobile/features/insights/domain/insights_models.dart';
import 'package:brainbox_mobile/features/insights/domain/insights_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../insights_fixtures.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient api;
  late InsightsRepository repository;

  void answerWith(Future<Map<String, dynamic>> Function() answer) {
    when(
      () => api.get<Map<String, dynamic>>(any(), query: any(named: 'query')),
    ).thenAnswer((_) => answer());
  }

  void failWith(ApiException error) =>
      answerWith(() => Future<Map<String, dynamic>>.error(error));

  setUp(() {
    api = _MockApiClient();
    repository = InsightsRepository(api);
  });

  test('loads every attempt from GET /insights/topics', () async {
    answerWith(() async => sampleInsightsJson());

    final data = await repository.fetchTopicInsights();

    expect(data.topics, hasLength(7));
    verify(
      () => api.get<Map<String, dynamic>>('/insights/topics', query: null),
    ).called(1);
  });

  test('passes attempt_id for a single attempt', () async {
    answerWith(() async => sampleInsightsJson());

    await repository.fetchTopicInsights(attemptId: 'a-1');

    verify(
      () => api.get<Map<String, dynamic>>(
        '/insights/topics',
        query: {'attempt_id': 'a-1'},
      ),
    ).called(1);
  });

  group('GET /insights/summary', () {
    test('sends the period and parses every card', () async {
      answerWith(() async => sampleSummaryJson());

      final summary = await repository.fetchSummary(
        period: InsightsPeriod.month,
      );

      expect(summary.mastery!.bands, hasLength(4));
      expect(summary.studyTime!.totalMinutes, 822);
      expect(summary.accuracyTrend!.points[2].percent, isNull);
      expect(summary.units.last.status, TopicStatus.notAttempted);
      verify(
        () => api.get<Map<String, dynamic>>(
          '/insights/summary',
          query: {'period': 'month'},
        ),
      ).called(1);
    });

    test('404 (endpoint not built yet) -> InsightsNotAvailableYet', () {
      failWith(
        const ApiException(
          code: 'NOT_FOUND',
          message: 'Not Found',
          statusCode: 404,
        ),
      );
      expect(
        repository.fetchSummary(period: InsightsPeriod.week),
        throwsA(isA<InsightsNotAvailableYet>()),
      );
    });

    test('unknown band keys and statuses do not crash', () async {
      answerWith(
        () async => {
          ...sampleSummaryJson(),
          'mastery': {
            'percent': 50.0,
            'bands': [
              {'key': 'legendary', 'label': 'Legendary', 'topic_count': 1},
            ],
          },
          'units': [
            {'name': 'New unit', 'status': 'brand_new_status'},
          ],
        },
      );

      final summary = await repository.fetchSummary(
        period: InsightsPeriod.week,
      );

      expect(summary.mastery!.bands.single.key, MasteryBandKey.unknown);
      expect(summary.units.single.status, TopicStatus.unknown);
    });
  });

  group('error mapping', () {
    test('401 USER_NOT_REGISTERED -> InsightsNotRegistered', () {
      failWith(
        const ApiException(
          code: 'USER_NOT_REGISTERED',
          message: 'Not registered',
          statusCode: 401,
        ),
      );
      expect(
        repository.fetchTopicInsights(),
        throwsA(isA<InsightsNotRegistered>()),
      );
    });

    test('403 -> InsightsUnavailable', () {
      failWith(
        const ApiException(
          code: 'FORBIDDEN',
          message: 'Forbidden',
          statusCode: 403,
        ),
      );
      expect(
        repository.fetchTopicInsights(attemptId: 'other'),
        throwsA(isA<InsightsUnavailable>()),
      );
    });

    test('404 -> InsightsUnavailable', () {
      failWith(
        const ApiException(
          code: 'ATTEMPT_NOT_FOUND',
          message: 'Not found',
          statusCode: 404,
        ),
      );
      expect(
        repository.fetchTopicInsights(attemptId: 'missing'),
        throwsA(isA<InsightsUnavailable>()),
      );
    });

    test('422 -> generic InsightsServerError', () {
      failWith(
        const ApiException(
          code: 'VALIDATION_ERROR',
          message: 'attempt_id is not a valid uuid',
          statusCode: 422,
        ),
      );
      expect(
        repository.fetchTopicInsights(attemptId: 'bad'),
        throwsA(
          isA<InsightsServerError>().having(
            (e) => e.message,
            'message',
            'Something went wrong. Please try again.',
          ),
        ),
      );
    });

    test('no connection -> InsightsOffline', () {
      failWith(
        const ApiException(code: 'network', message: 'Cannot reach server'),
      );
      expect(repository.fetchTopicInsights(), throwsA(isA<InsightsOffline>()));
    });

    test('timeout -> InsightsOffline', () {
      failWith(const ApiException(code: 'timeout', message: 'Too slow'));
      expect(repository.fetchTopicInsights(), throwsA(isA<InsightsOffline>()));
    });

    test('500 -> InsightsServerError with the server message', () {
      failWith(
        const ApiException(
          code: 'INTERNAL',
          message: 'Server error',
          statusCode: 500,
        ),
      );
      expect(
        repository.fetchTopicInsights(),
        throwsA(
          isA<InsightsServerError>().having(
            (e) => e.message,
            'message',
            'Server error',
          ),
        ),
      );
    });
  });
}
