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

  // TODO(keshomigha): add one method per endpoint, e.g.
  //   GET /units/{unit_id}  ->  One unit with its topics
  //   GET /topics/{topic_id}  ->  One topic with its concepts
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
    topicTitles: ['Dihybrid crosses', 'Mendelian inheritance'],
  ),
];

@riverpod
SyllabusRepository syllabusRepository(Ref ref) =>
    SyllabusRepository(ref.watch(apiClientProvider));
