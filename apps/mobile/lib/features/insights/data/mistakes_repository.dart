import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/mistake_models.dart';

part 'mistakes_repository.g.dart';

/// The mistake journal. Uses the backend's `/mistakes` API (built).
abstract interface class MistakesRepository {
  /// `GET /mistakes?status=open|resolved&page=1&size=50` (newest first).
  Future<List<MistakeEntry>> mistakes(MistakeTab tab);

  /// `PATCH /mistakes/{id}` with `{resolved}`.
  Future<void> setResolved(String id, {required bool resolved});
}

class ApiMistakesRepository implements MistakesRepository {
  ApiMistakesRepository(this.api);

  final ApiClient api;

  @override
  Future<List<MistakeEntry>> mistakes(MistakeTab tab) async {
    final page = await api.get<Map<String, dynamic>>(
      '/mistakes',
      query: {'status': tab.apiValue, 'page': 1, 'size': 50},
    );
    return [
      for (final item in page['items'] as List<dynamic>)
        MistakeEntry.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> setResolved(String id, {required bool resolved}) =>
      api.patch<Object?>('/mistakes/$id', data: {'resolved': resolved});
}

/// DEBUG ONLY (`USE_FAKE_API=true`): two open mistakes.
class FakeMistakesRepository implements MistakesRepository {
  final _items = <MistakeEntry>[
    MistakeEntry(
      id: 'm1',
      question:
          'Which hormone increases water reabsorption in the collecting duct?',
      yourAnswer: 'Aldosterone',
      correctAnswer: 'ADH',
      misconception: const MistakeMisconception(
        id: 'mc1',
        title: 'Confuses ADH & aldosterone',
      ),
      correction: 'ADH controls water; aldosterone controls sodium.',
      topic: 'Excretion & osmoregulation',
      topicNumber: '5.4',
      unitNumber: 5,
      source: 'quiz',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    MistakeEntry(
      id: 'm2',
      question:
          'Genes A and B are 8 map units apart. Test cross AB/ab gives...',
      yourAnswer: '1 : 1 : 1 : 1',
      correctAnswer: 'Mostly parental types with few recombinants',
      misconception: const MistakeMisconception(
        id: 'mc2',
        title: 'Assumes independent assortment for linked genes',
      ),
      topic: 'Deviations from Mendel',
      topicNumber: '6.2',
      unitNumber: 6,
      source: 'diagnostic',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Future<List<MistakeEntry>> mistakes(MistakeTab tab) async => _items
      .where((m) => m.isResolved == (tab == MistakeTab.resolved))
      .toList();

  @override
  Future<void> setResolved(String id, {required bool resolved}) async {
    final i = _items.indexWhere((m) => m.id == id);
    _items[i] = _items[i].copyWith(isResolved: resolved);
  }
}

@Riverpod(keepAlive: true)
MistakesRepository mistakesRepository(Ref ref) => Env.useFakeApi
    ? FakeMistakesRepository()
    : ApiMistakesRepository(ref.watch(apiClientProvider));
