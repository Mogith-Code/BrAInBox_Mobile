import 'package:freezed_annotation/freezed_annotation.dart';

part 'quality_review_models.freezed.dart';
part 'quality_review_models.g.dart';

/// The result of one automatic check.
enum CheckResult {
  pass('Pass'),
  review('Review'),
  fail('Fail');

  const CheckResult(this.label);

  final String label;
}

/// One automatic check on an AI question, e.g. "Single correct answer".
@freezed
abstract class QualityCheck with _$QualityCheck {
  const factory QualityCheck({
    required String name,
    @JsonKey(unknownEnumValue: CheckResult.review)
    @Default(CheckResult.pass)
    CheckResult result,
    @Default('No issues found.') String note,
  }) = _QualityCheck;

  factory QualityCheck.fromJson(Map<String, dynamic> json) =>
      _$QualityCheckFromJson(json);
}

/// A student report on the question, grouped by what they said.
@freezed
abstract class StudentReportCount with _$StudentReportCount {
  const factory StudentReportCount({
    required String text,
    @Default(1) int count,
  }) = _StudentReportCount;

  factory StudentReportCount.fromJson(Map<String, dynamic> json) =>
      _$StudentReportCountFromJson(json);
}

/// One AI question waiting in the quality queue.
@freezed
abstract class QualityItem with _$QualityItem {
  const QualityItem._();

  const factory QualityItem({
    required String id,
    required String code, // "Q-4877"
    required String stem,
    int? unitNumber,
    String? topicCode, // "5.4"
    @Default([]) List<QualityCheck> checks,
    @Default([]) List<StudentReportCount> studentReports,
  }) = _QualityItem;

  factory QualityItem.fromJson(Map<String, dynamic> json) =>
      _$QualityItemFromJson(json);

  bool get allPass => checks.every((c) => c.result == CheckResult.pass);

  int get reportTotal => studentReports.fold(0, (n, r) => n + r.count);

  /// The result of the check called [name] (null if it didn't run).
  CheckResult? result(String name) =>
      checks.where((c) => c.name == name).firstOrNull?.result;
}

/// `GET /admin/questions/quality`: the four numbers and the queue.
@freezed
abstract class QualityQueue with _$QualityQueue {
  const factory QualityQueue({
    @Default(0) int inQueue,
    @Default(0) int autoCheckFailed,
    @Default(0) int withStudentReports,
    int? avgReviewMinutes,
    @Default([]) List<QualityItem> items,
  }) = _QualityQueue;

  factory QualityQueue.fromJson(Map<String, dynamic> json) =>
      _$QualityQueueFromJson(json);
}
