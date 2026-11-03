import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/syllabus_repository.dart';
import '../domain/syllabus_models.dart';

part 'unit_detail_controller.g.dart';

/// State for the Unit detail screen (Figma B3): one unit and its topics.
///
/// ```dart
/// final state = ref.watch(unitDetailControllerProvider(unitId));
/// ```
@riverpod
class UnitDetailController extends _$UnitDetailController {
  @override
  Future<UnitDetail> build(String unitId) {
    return ref.watch(syllabusRepositoryProvider).fetchUnit(unitId);
  }
}
