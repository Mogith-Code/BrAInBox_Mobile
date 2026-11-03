import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/syllabus/application/topic_controller.dart';
import 'package:brainbox_mobile/features/syllabus/application/unit_detail_controller.dart';
import 'package:brainbox_mobile/features/syllabus/data/syllabus_repository.dart';
import 'package:brainbox_mobile/features/syllabus/domain/syllabus_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements SyllabusRepository {}

const _detail = TopicDetail(
  topic: TopicProgress(
    id: 't-mendelian',
    unitId: 'unit-6',
    title: 'Mendelian inheritance',
    status: TopicStatus.improving,
  ),
  unit: UnitProgress(id: 'unit-6', title: 'Genetics', order: 6),
);

void main() {
  late _MockRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockRepository();
    when(
      () => repository.fetchTopic('t-mendelian'),
    ).thenAnswer((_) async => _detail);
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [syllabusRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('toggleSaved saves, then un-saves', () async {
    when(
      () => repository.setTopicSaved(any(), saved: any(named: 'saved')),
    ).thenAnswer((_) async {});
    final provider = topicControllerProvider('t-mendelian');
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await container.read(provider.future);

    expect(await container.read(provider.notifier).toggleSaved(), isTrue);
    expect(container.read(provider).requireValue.saved, isTrue);
    verify(() => repository.setTopicSaved('t-mendelian', saved: true));

    expect(await container.read(provider.notifier).toggleSaved(), isFalse);
    expect(container.read(provider).requireValue.saved, isFalse);
  });

  test('toggleSaved puts the old value back when the call fails', () async {
    when(
      () => repository.setTopicSaved(any(), saved: any(named: 'saved')),
    ).thenThrow(const ApiException(code: 'offline', message: 'Offline'));
    final provider = topicControllerProvider('t-mendelian');
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await container.read(provider.future);

    await expectLater(
      container.read(provider.notifier).toggleSaved(),
      throwsA(isA<ApiException>()),
    );
    expect(container.read(provider).requireValue.saved, isFalse);
  });

  test('sample data: Genetics has 9 topics, 2 mastered, 3 weak', () async {
    final real = ProviderContainer();
    addTearDown(real.dispose);

    final provider = unitDetailControllerProvider('unit-6');
    final sub = real.listen(provider, (_, _) {});
    addTearDown(sub.close);

    final unit = await real.read(provider.future);

    expect(unit.topics, hasLength(9));
    expect(unit.masteredCount, 2);
    expect(unit.weakCount, 3);
  });
}
