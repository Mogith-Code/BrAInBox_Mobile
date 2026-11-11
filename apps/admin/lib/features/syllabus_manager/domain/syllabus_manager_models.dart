import 'package:freezed_annotation/freezed_annotation.dart';

part 'syllabus_manager_models.freezed.dart';
part 'syllabus_manager_models.g.dart';

/// `AdminUnitOut` from `GET /admin/syllabus/units`.
@freezed
abstract class AdminUnit with _$AdminUnit {
  const factory AdminUnit({
    required String id,
    required int number,
    required String title,
    String? description,
    @Default(1) double examWeight,
    @Default(false) bool isOutdated,
    @Default(0) int topicCount,
  }) = _AdminUnit;

  factory AdminUnit.fromJson(Map<String, dynamic> json) =>
      _$AdminUnitFromJson(json);
}

/// `AdminTopicOut` from `GET /admin/syllabus/units/{id}/topics`.
@freezed
abstract class AdminTopic with _$AdminTopic {
  const factory AdminTopic({
    required String id,
    required String unitId,
    required String number, // "6.2"
    required String title,
    String? description,
    @Default(0) int orderIndex,
    @Default(false) bool isOutdated,
    @Default(0) int conceptCount,
  }) = _AdminTopic;

  factory AdminTopic.fromJson(Map<String, dynamic> json) =>
      _$AdminTopicFromJson(json);
}

/// `AdminConceptOut` from `GET /admin/syllabus/topics/{id}/concepts`.
@freezed
abstract class AdminConcept with _$AdminConcept {
  const factory AdminConcept({
    required String id,
    required String topicId,
    String? code, // "6.2.4" (shown as BIO-6.2.4)
    required String name,
    String? description,
    String? learningOutcome,
    @Default(0) int orderIndex,
    @Default(false) bool isOutdated,
  }) = _AdminConcept;

  factory AdminConcept.fromJson(Map<String, dynamic> json) =>
      _$AdminConceptFromJson(json);
}

/// Which level of the tree a node is (unit, topic or concept).
enum NodeKind { unit, topic, concept }

/// The node selected in the tree, with what the edit form needs.
@freezed
abstract class SelectedNode with _$SelectedNode {
  const factory SelectedNode({
    required NodeKind kind,
    required String id,
    required String parentId, // '' for units
    required String name, // unit / topic title, concept name
    String? code, // unit number, topic number, concept code
    String? text, // concept learning outcome, else description
    @Default(false) bool isOutdated,
    @Default('') String breadcrumb, // "Biology › 06 Genetics › 6.2 Deviations"
  }) = _SelectedNode;
}
