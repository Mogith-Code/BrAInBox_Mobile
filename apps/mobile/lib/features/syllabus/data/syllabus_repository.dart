import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/syllabus_models.dart';

part 'syllabus_repository.g.dart';

/// Data layer for the Syllabus feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class SyllabusRepository {
  SyllabusRepository(this.api);

  final ApiClient api;

  /// `GET /units` - every unit with the student's mastery, in syllabus order.
  Future<List<UnitProgress>> fetchUnits() async {
    // TODO(keshomigha): call the backend instead of returning sample data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<List<dynamic>>('/units');
    // return [
    //   for (final item in json)
    //     UnitProgress.fromJson(item as Map<String, dynamic>),
    // ]..sort((a, b) => a.order.compareTo(b.order));
    return _sampleUnits;
  }

  /// `GET /units/{unit_id}` - one unit with its topics (Figma B3).
  Future<UnitDetail> fetchUnit(String unitId) async {
    // TODO(keshomigha): call the backend instead of returning sample data.
    // final json = await api.get<Map<String, dynamic>>('/units/$unitId');
    // return UnitDetail.fromJson(json);
    final unit = _sampleUnits.where((u) => u.id == unitId).firstOrNull;
    if (unit == null) throw _notFound('unit_not_found', 'Unit not found.');
    return UnitDetail(unit: unit, topics: _sampleTopics[unitId] ?? const []);
  }

  /// `GET /topics/{topic_id}` - one topic with its unit (Figma B4).
  Future<TopicDetail> fetchTopic(String topicId) async {
    // TODO(keshomigha): call the backend instead of returning sample data.
    // final json = await api.get<Map<String, dynamic>>('/topics/$topicId');
    // return TopicDetail.fromJson(json);
    for (final unit in _sampleUnits) {
      final topic = _sampleTopics[unit.id]
          ?.where((t) => t.id == topicId)
          .firstOrNull;
      if (topic != null) {
        return TopicDetail(
          topic: topic,
          unit: unit,
          saved: _savedTopicIds.contains(topicId),
        );
      }
    }
    throw _notFound('topic_not_found', 'Topic not found.');
  }

  /// Bookmarks a topic into "My library" (or removes it).
  Future<void> setTopicSaved(String topicId, {required bool saved}) async {
    // TODO(samni): call the library endpoint once the backend publishes it
    // (not in /docs yet). Kept in memory until then.
    saved ? _savedTopicIds.add(topicId) : _savedTopicIds.remove(topicId);
  }

  final Set<String> _savedTopicIds = {};

  static ApiException _notFound(String code, String message) =>
      ApiException(code: code, message: message, statusCode: 404);
}

/// The units from the Figma Learn screen (B2), until `GET /units` exists.
const _sampleUnits = [
  UnitProgress(
    id: 'unit-1',
    order: 1,
    title: 'Introduction to Biology',
    topicCount: 4,
    mastery: 0.88,
    status: UnitStatus.mastered,
    topicTitles: ['Characteristics of life', 'Levels of organisation'],
  ),
  UnitProgress(
    id: 'unit-2',
    order: 2,
    title: 'Chemical & Cellular Basis of Life',
    topicCount: 14,
    mastery: 0.70,
    status: UnitStatus.strong,
    topicTitles: ['Enzymes', 'Cell structure', 'Cell division'],
  ),
  UnitProgress(
    id: 'unit-3',
    order: 3,
    title: 'Evolution & Diversity of Organisms',
    topicCount: 11,
    mastery: 0.58,
    status: UnitStatus.improving,
    topicTitles: ['Classification', 'Origin of life'],
  ),
  UnitProgress(
    id: 'unit-4',
    order: 4,
    title: 'Plant Form & Function',
    topicCount: 12,
    mastery: 0.82,
    status: UnitStatus.strong,
    topicTitles: ['Photosynthesis', 'Transport in plants'],
  ),
  UnitProgress(
    id: 'unit-5',
    order: 5,
    title: 'Animal Form & Function',
    topicCount: 18,
    mastery: 0.54,
    status: UnitStatus.improving,
    topicTitles: ['Nephron', 'Circulation', 'Nervous system'],
  ),
  UnitProgress(
    id: 'unit-6',
    order: 6,
    title: 'Genetics',
    topicCount: 9,
    mastery: 0.42,
    status: UnitStatus.weak,
    topicTitles: [
      'Genetic material & the gene',
      'Mendelian inheritance',
      'Dihybrid crosses',
      'Deviations from Mendelian ratios',
      'Sex determination & sex linkage',
      'Linkage & crossing over',
      'Pedigree analysis',
      'Mutations',
      'Population genetics',
    ],
  ),
];

/// Topics per unit for B3 / B4, until `GET /units/{unit_id}` exists.
/// Unit 6 matches Figma ("9 topics · 2 mastered · 3 weak"). The ids used
/// by the Home sample data (t-dihybrid, t-nephron, t-enzymes) are here too.
const _sampleTopics = <String, List<TopicProgress>>{
  'unit-1': [
    TopicProgress(
      id: 't-characteristics',
      unitId: 'unit-1',
      order: 1,
      title: 'Characteristics of life',
      status: TopicStatus.mastered,
    ),
    TopicProgress(
      id: 't-levels',
      unitId: 'unit-1',
      order: 2,
      title: 'Levels of organisation',
      status: TopicStatus.mastered,
    ),
  ],
  'unit-2': [
    TopicProgress(
      id: 't-enzymes',
      unitId: 'unit-2',
      order: 1,
      title: 'Enzymes',
      status: TopicStatus.strong,
    ),
    TopicProgress(
      id: 't-cell-structure',
      unitId: 'unit-2',
      order: 2,
      title: 'Cell structure',
      status: TopicStatus.strong,
    ),
    TopicProgress(
      id: 't-cell-division',
      unitId: 'unit-2',
      order: 3,
      title: 'Cell division',
      status: TopicStatus.improving,
    ),
  ],
  'unit-3': [
    TopicProgress(
      id: 't-classification',
      unitId: 'unit-3',
      order: 1,
      title: 'Classification',
      status: TopicStatus.improving,
    ),
    TopicProgress(
      id: 't-origin-of-life',
      unitId: 'unit-3',
      order: 2,
      title: 'Origin of life',
      status: TopicStatus.inProgress,
      progress: 0.5,
    ),
  ],
  'unit-4': [
    TopicProgress(
      id: 't-photosynthesis',
      unitId: 'unit-4',
      order: 1,
      title: 'Photosynthesis',
      status: TopicStatus.strong,
    ),
    TopicProgress(
      id: 't-plant-transport',
      unitId: 'unit-4',
      order: 2,
      title: 'Transport in plants',
      status: TopicStatus.strong,
    ),
  ],
  'unit-5': [
    TopicProgress(
      id: 't-nephron',
      unitId: 'unit-5',
      order: 1,
      title: 'Nephron',
      status: TopicStatus.weak,
    ),
    TopicProgress(
      id: 't-circulation',
      unitId: 'unit-5',
      order: 2,
      title: 'Circulation',
      status: TopicStatus.improving,
    ),
    TopicProgress(
      id: 't-nervous-system',
      unitId: 'unit-5',
      order: 3,
      title: 'Nervous system',
      status: TopicStatus.inProgress,
      progress: 0.3,
    ),
  ],
  'unit-6': [
    TopicProgress(
      id: 't-genetic-material',
      unitId: 'unit-6',
      order: 1,
      title: 'Genetic material & the gene',
      status: TopicStatus.mastered,
    ),
    TopicProgress(
      id: 't-mendelian',
      unitId: 'unit-6',
      order: 2,
      title: 'Mendelian inheritance',
      status: TopicStatus.improving,
    ),
    TopicProgress(
      id: 't-dihybrid',
      unitId: 'unit-6',
      order: 3,
      title: 'Dihybrid crosses',
      status: TopicStatus.weak,
    ),
    TopicProgress(
      id: 't-non-mendelian',
      unitId: 'unit-6',
      order: 4,
      title: 'Deviations from Mendelian ratios',
      status: TopicStatus.weak,
    ),
    TopicProgress(
      id: 't-sex-linkage',
      unitId: 'unit-6',
      order: 5,
      title: 'Sex determination & sex linkage',
      status: TopicStatus.inProgress,
      progress: 0.4,
    ),
    TopicProgress(
      id: 't-linkage',
      unitId: 'unit-6',
      order: 6,
      title: 'Linkage & crossing over',
      status: TopicStatus.weak,
    ),
    TopicProgress(
      id: 't-pedigree',
      unitId: 'unit-6',
      order: 7,
      title: 'Pedigree analysis',
      status: TopicStatus.mastered,
    ),
    TopicProgress(
      id: 't-mutations',
      unitId: 'unit-6',
      order: 8,
      title: 'Mutations',
      status: TopicStatus.inProgress,
      progress: 0.25,
    ),
    TopicProgress(
      id: 't-population',
      unitId: 'unit-6',
      order: 9,
      title: 'Population genetics',
    ),
  ],
};

@riverpod
SyllabusRepository syllabusRepository(Ref ref) =>
    SyllabusRepository(ref.watch(apiClientProvider));
