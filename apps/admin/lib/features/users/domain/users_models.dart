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
    @Default(1) int page,
  }) = _StudentFilter;

  /// Rows per page of the table.
  static const pageSize = 25;

  /// The most the backend sends per page (used by the CSV export).
  static const maxPageSize = 100;

  /// Query string for `GET /admin/users` (empty values left out).
  Map<String, dynamic> toQuery({int pageSize = pageSize}) => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    'exam_year': ?examYear,
    if (status != null) 'status': status!.name,
    'district': ?district,
    'page': page,
    'page_size': pageSize,
  };
}

/// The CSV the "Export CSV" button saves: one row per student.
///
/// Cells that a spreadsheet would run as a formula (`=`, `+`, `-`, `@`)
/// get a leading `'`, because names and schools are typed by students.
String studentsCsv(List<AdminStudent> students) {
  String cell(Object? value) {
    var text = value?.toString() ?? '';
    if (text.isNotEmpty && '=+-@\t\r'.contains(text[0])) text = "'$text";
    final quote = text.contains(RegExp('[",\r\n]'));
    return quote ? '"${text.replaceAll('"', '""')}"' : text;
  }

  return [
    'Name,Email,School,District,A/L year,Average mastery (%),Status,Last active',
    for (final s in students)
      [
        s.fullName,
        s.email,
        s.school,
        s.district,
        s.examYear,
        s.avgMastery,
        s.status.label,
        s.lastActiveAt?.toUtc().toIso8601String(),
      ].map(cell).join(','),
  ].join('\r\n');
}
