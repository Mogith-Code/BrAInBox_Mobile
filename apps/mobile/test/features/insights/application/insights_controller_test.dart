import 'dart:async';

import 'package:brainbox_mobile/features/insights/application/insights_controller.dart';
import 'package:brainbox_mobile/features/insights/data/insights_repository.dart';
import 'package:brainbox_mobile/features/insights/domain/insights_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../insights_fixtures.dart';

class _MockRepository extends Mock implements InsightsRepository {}

void main() {
  late _MockRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockRepository();
    container = ProviderContainer(
      overrides: [insightsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  TopicInsights sample() => TopicInsights.fromJson(sampleInsightsJson());

  void answer({String? attemptId, required Future<TopicInsights> result}) {
    when(
      () => repository.fetchTopicInsights(attemptId: attemptId),
    ).thenAnswer((_) => result);
  }

  test('starts loading, then has data', () async {
    final completer = Completer<TopicInsights>();
    answer(result: completer.future);
    final provider = insightsControllerProvider();
    container.listen(provider, (_, _) {});

    expect(container.read(provider).isLoading, isTrue);

    completer.complete(sample());
    final data = await container.read(provider.future);

    expect(data.overall.percent, 61.76);
    expect(container.read(provider).hasValue, isTrue);
  });

  test('starts loading, then has the error', () async {
    answer(result: Future.error(const InsightsOffline('Offline')));
    final provider = insightsControllerProvider();
    container.listen(provider, (_, _) {});

    await expectLater(
      container.read(provider.future),
      throwsA(isA<InsightsOffline>()),
    );
    expect(container.read(provider).error, isA<InsightsOffline>());
  });

  test('refresh loads again', () async {
    answer(result: Future.value(sample()));
    final provider = insightsControllerProvider();
    container.listen(provider, (_, _) {});
    await container.read(provider.future);

    await container.read(provider.notifier).refresh();

    verify(() => repository.fetchTopicInsights()).called(2);
    expect(container.read(provider).hasValue, isTrue);
  });

  test('a failed refresh keeps the old data next to the error', () async {
    answer(result: Future.value(sample()));
    final provider = insightsControllerProvider();
    container.listen(provider, (_, _) {});
    await container.read(provider.future);

    answer(result: Future.error(const InsightsOffline('Offline')));
    await container.read(provider.notifier).refresh();

    final state = container.read(provider);
    expect(state.hasError, isTrue);
    expect(state.value?.overall.percent, 61.76);
  });

  test('passes the attempt id to the repository', () async {
    answer(attemptId: 'a-1', result: Future.value(sample()));
    final provider = insightsControllerProvider(attemptId: 'a-1');
    container.listen(provider, (_, _) {});

    await container.read(provider.future);

    verify(() => repository.fetchTopicInsights(attemptId: 'a-1')).called(1);
    verifyNever(() => repository.fetchTopicInsights());
  });
}
