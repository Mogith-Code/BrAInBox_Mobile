import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/syllabus_manager_models.dart';

part 'syllabus_manager_repository.g.dart';

/// The curriculum tree (admin). Uses the backend's `/admin/syllabus` API.
abstract interface class SyllabusManagerRepository {
  Future<List<AdminUnit>> units();
  Future<List<AdminTopic>> topics(String unitId);
  Future<List<AdminConcept>> concepts(String topicId);

  /// `PATCH /admin/syllabus/{units|topics|concepts}/{id}` with only the
  /// changed fields (snake_case, e.g. `{name, code, is_outdated}`).
  Future<void> update(NodeKind kind, String id, Map<String, dynamic> fields);

  /// `POST /admin/syllabus/units`, `/units/{id}/topics` or
  /// `/topics/{id}/concepts`.
  Future<void> create(
    NodeKind kind, {
    required String parentId,
    required Map<String, dynamic> fields,
  });
}

class ApiSyllabusManagerRepository implements SyllabusManagerRepository {
  ApiSyllabusManagerRepository(this.api);

  final ApiClient api;

  static const _base = '/admin/syllabus';

  Future<List<T>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async => [
    for (final j in await api.get<List<dynamic>>(path))
      fromJson(j as Map<String, dynamic>),
  ];

  @override
  Future<List<AdminUnit>> units() => _list('$_base/units', AdminUnit.fromJson);

  @override
  Future<List<AdminTopic>> topics(String unitId) =>
      _list('$_base/units/$unitId/topics', AdminTopic.fromJson);

  @override
  Future<List<AdminConcept>> concepts(String topicId) =>
      _list('$_base/topics/$topicId/concepts', AdminConcept.fromJson);

  @override
  Future<void> update(NodeKind kind, String id, Map<String, dynamic> fields) =>
      api.patch<Object?>('$_base/${kind.name}s/$id', data: fields);

  @override
  Future<void> create(
    NodeKind kind, {
    required String parentId,
    required Map<String, dynamic> fields,
  }) => api.post<Object?>(switch (kind) {
    NodeKind.unit => '$_base/units',
    NodeKind.topic => '$_base/units/$parentId/topics',
    NodeKind.concept => '$_base/topics/$parentId/concepts',
  }, data: fields);
}

/// DEBUG ONLY (`USE_FAKE_API=true`): part of the tree from the Figma page.
class FakeSyllabusManagerRepository implements SyllabusManagerRepository {
  final _units = <AdminUnit>[
    for (final (n, title) in const [
      (1, 'Introduction to Biology'),
      (2, 'Chemical & cellular basis of life'),
      (3, 'Evolution & diversity of organisms'),
      (4, 'Plant form & function'),
      (5, 'Animal form & function'),
      (6, 'Genetics'),
      (7, 'Molecular biology'),
    ])
      AdminUnit(id: 'u$n', number: n, title: title, topicCount: n == 6 ? 3 : 1),
  ];

  final _topics = <AdminTopic>[
    const AdminTopic(
      id: 't5.4',
      unitId: 'u5',
      number: '5.4',
      title: 'Excretion & osmoregulation',
      conceptCount: 0,
    ),
    const AdminTopic(
      id: 't6.1',
      unitId: 'u6',
      number: '6.1',
      title: 'Mendelian inheritance',
      conceptCount: 3,
    ),
    const AdminTopic(
      id: 't6.2',
      unitId: 'u6',
      number: '6.2',
      title: 'Deviations from Mendel',
      orderIndex: 1,
      conceptCount: 2,
    ),
    const AdminTopic(
      id: 't6.3',
      unitId: 'u6',
      number: '6.3',
      title: 'Chromosome mapping',
      orderIndex: 2,
      isOutdated: true,
    ),
  ];

  final _concepts = <AdminConcept>[
    const AdminConcept(
      id: 'c1',
      topicId: 't6.1',
      code: '6.1.1',
      name: 'Law of segregation',
    ),
    const AdminConcept(
      id: 'c2',
      topicId: 't6.1',
      code: '6.1.2',
      name: 'Dihybrid crosses',
      orderIndex: 1,
    ),
    const AdminConcept(
      id: 'c3',
      topicId: 't6.1',
      code: '6.1.3',
      name: 'Test cross',
      orderIndex: 2,
    ),
    const AdminConcept(
      id: 'c4',
      topicId: 't6.2',
      code: '6.2.1',
      name: 'Linkage & crossing over',
    ),
    const AdminConcept(
      id: 'c5',
      topicId: 't6.2',
      code: '6.2.4',
      name: 'Blood group (old syllabus)',
      learningOutcome:
          'Explains inheritance of ABO blood groups using multiple alleles '
          'and co-dominance.',
      orderIndex: 1,
      isOutdated: true,
    ),
  ];

  @override
  Future<List<AdminUnit>> units() async => List.of(_units);

  @override
  Future<List<AdminTopic>> topics(String unitId) async =>
      _topics.where((t) => t.unitId == unitId).toList();

  @override
  Future<List<AdminConcept>> concepts(String topicId) async =>
      _concepts.where((c) => c.topicId == topicId).toList();

  @override
  Future<void> update(
    NodeKind kind,
    String id,
    Map<String, dynamic> fields,
  ) async {
    switch (kind) {
      case NodeKind.unit:
        final i = _units.indexWhere((u) => u.id == id);
        _units[i] = _units[i].copyWith(
          title: fields['title'] as String? ?? _units[i].title,
          isOutdated: fields['is_outdated'] as bool? ?? _units[i].isOutdated,
        );
      case NodeKind.topic:
        final i = _topics.indexWhere((t) => t.id == id);
        _topics[i] = _topics[i].copyWith(
          title: fields['title'] as String? ?? _topics[i].title,
          number: fields['number'] as String? ?? _topics[i].number,
          isOutdated: fields['is_outdated'] as bool? ?? _topics[i].isOutdated,
        );
      case NodeKind.concept:
        final i = _concepts.indexWhere((c) => c.id == id);
        _concepts[i] = _concepts[i].copyWith(
          name: fields['name'] as String? ?? _concepts[i].name,
          code: fields['code'] as String? ?? _concepts[i].code,
          learningOutcome:
              fields['learning_outcome'] as String? ??
              _concepts[i].learningOutcome,
          isOutdated: fields['is_outdated'] as bool? ?? _concepts[i].isOutdated,
        );
    }
  }

  @override
  Future<void> create(
    NodeKind kind, {
    required String parentId,
    required Map<String, dynamic> fields,
  }) async {
    final id = 'new${_concepts.length + _topics.length + _units.length}';
    switch (kind) {
      case NodeKind.unit:
        _units.add(
          AdminUnit(
            id: id,
            number: fields['number'] as int,
            title: fields['title'] as String,
          ),
        );
      case NodeKind.topic:
        _topics.add(
          AdminTopic(
            id: id,
            unitId: parentId,
            number: fields['number'] as String,
            title: fields['title'] as String,
          ),
        );
      case NodeKind.concept:
        _concepts.add(
          AdminConcept(
            id: id,
            topicId: parentId,
            code: fields['code'] as String?,
            name: fields['name'] as String,
          ),
        );
    }
  }
}

@Riverpod(keepAlive: true)
SyllabusManagerRepository syllabusManagerRepository(Ref ref) => Env.useFakeApi
    ? FakeSyllabusManagerRepository()
    : ApiSyllabusManagerRepository(ref.watch(apiClientProvider));
