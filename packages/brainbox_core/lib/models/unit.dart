import 'package:freezed_annotation/freezed_annotation.dart';

part 'unit.freezed.dart';
part 'unit.g.dart';

/// A syllabus unit, e.g. 'Unit 5 - Animal form and function'.
///
// TODO(keshomigha): check these fields against the backend OpenAPI /docs.
@freezed
abstract class Unit with _$Unit {
  const factory Unit({
    required String id,
    required String title,
    @Default(0) int order, // position in the syllabus
    String? description,
    @Default(0) int topicCount,
  }) = _Unit;

  factory Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);
}
