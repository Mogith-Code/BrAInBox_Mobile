import 'package:freezed_annotation/freezed_annotation.dart';

part 'users_models.freezed.dart';
part 'users_models.g.dart';

/// active = can use the app, suspended = blocked by an admin,
/// inactive = has not studied for 30+ days (still allowed in).
enum StudentStatus {
  active('Active'),
  suspended('Suspended'),
  inactive('Inactive 30d+');

  const StudentStatus(this.label);

  final String label;
}

/// One row of the Students table (`GET /admin/users`).
@freezed
abstract class AdminStudent with _$AdminStudent {
  const factory AdminStudent({
    required String id,
    required String fullName,
    @Default('') String email,
    String? school, // "Visakha V."
    String? district, // "Colombo"
    int? examYear,
    int? avgMastery, // 0-100, null = not assessed yet
    @JsonKey(unknownEnumValue: StudentStatus.active)
    @Default(StudentStatus.active)
    StudentStatus status,
    DateTime? lastActiveAt,
  }) = _AdminStudent;

  factory AdminStudent.fromJson(Map<String, dynamic> json) =>
      _$AdminStudentFromJson(json);
}

/// One page of students plus the counts for the header ("2,418 active").
@freezed
abstract class StudentPage with _$StudentPage {
  const factory StudentPage({
    @Default([]) List<AdminStudent> items,
    @Default(0) int total,
    @Default(0) int activeTotal,
  }) = _StudentPage;

  factory StudentPage.fromJson(Map<String, dynamic> json) =>
      _$StudentPageFromJson(json);
}

/// The search box and the filter buttons above the table.
@freezed
abstract class StudentFilter with _$StudentFilter {
  const StudentFilter._();

  const factory StudentFilter({
    @Default('') String search,
    int? examYear,
    StudentStatus? status,
    String? district,
  }) = _StudentFilter;

  /// Query string for `GET /admin/users` (empty values left out).
  Map<String, dynamic> toQuery() => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    'exam_year': ?examYear,
    if (status != null) 'status': status!.name,
    'district': ?district,
  };
}
