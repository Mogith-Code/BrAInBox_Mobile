import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_models.freezed.dart';
part 'profile_models.g.dart';

/// A simple choice from `GET /profile/options` (stream, target grade).
/// The backend may send plain strings or `{id, name}` objects; both work.
@freezed
abstract class OptionItem with _$OptionItem {
  const factory OptionItem({required String id, required String name}) =
      _OptionItem;

  factory OptionItem.fromJson(Map<String, dynamic> json) =>
      _$OptionItemFromJson(json);
}

/// Reads "A" or {"id": "A", "name": "A"} (or {"id", "label"}).
class OptionItemConverter implements JsonConverter<OptionItem, Object> {
  const OptionItemConverter();

  @override
  OptionItem fromJson(Object json) {
    if (json is Map) {
      final id = '${json['id'] ?? json['name'] ?? json['label']}';
      return OptionItem(id: id, name: '${json['name'] ?? json['label'] ?? id}');
    }
    return OptionItem(id: '$json', name: '$json');
  }

  @override
  Object toJson(OptionItem item) => item.toJson();
}

/// A subject card ("Biology · 10 units · 2025 syllabus").
@freezed
abstract class SubjectOption with _$SubjectOption {
  const factory SubjectOption({
    required String id,
    required String name,
    int? units,
    String? syllabus,
    @Default(true) bool available, // false = "Coming soon", can't be picked
  }) = _SubjectOption;

  factory SubjectOption.fromJson(Map<String, dynamic> json) =>
      _$SubjectOptionFromJson(json);
}

/// A preferred-time card ("Evening · 4–8 PM").
@freezed
abstract class PreferredTimeOption with _$PreferredTimeOption {
  const factory PreferredTimeOption({
    required String id,
    required String label,
    @Default('') String hint,
  }) = _PreferredTimeOption;

  factory PreferredTimeOption.fromJson(Map<String, dynamic> json) =>
      _$PreferredTimeOptionFromJson(json);
}

/// `GET /profile/options` - what the setup screens offer.
@freezed
abstract class ProfileOptions with _$ProfileOptions {
  const factory ProfileOptions({
    @OptionItemConverter() @Default(<OptionItem>[]) List<OptionItem> streams,
    @Default(<SubjectOption>[]) List<SubjectOption> subjects,
    @Default(<int>[]) List<int> examYears,
    @OptionItemConverter()
    @Default(<OptionItem>[])
    List<OptionItem> targetGrades,
    @Default(<PreferredTimeOption>[]) List<PreferredTimeOption> preferredTimes,
  }) = _ProfileOptions;

  factory ProfileOptions.fromJson(Map<String, dynamic> json) =>
      _$ProfileOptionsFromJson(json);
}

/// `ProfileOut` from `GET /profile`, `PATCH /profile`, `POST /profile/complete`.
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    String? stream,
    String? subject,
    int? examYear,
    String? targetGrade,
    int? confidence, // 0 - 100
    @Default(<String>[]) List<String> studyDays, // "mon" ... "sun"
    double? hoursPerDay,
    String? preferredTime,
    double? weeklyHours,
    @Default(false) bool profileCompleted,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}

/// "How confident do you feel in Biology?" label for a 0-100 value.
String confidenceLabel(int value) {
  if (value <= 20) return 'Not at all';
  if (value <= 40) return 'A little';
  if (value <= 60) return 'Okay-ish';
  if (value <= 80) return 'Fairly';
  return 'Very';
}

/// "≈ 10 hours a week · a steady pace"
String weeklyHoursHint(double weeklyHours) {
  final hours = weeklyHours % 1 == 0
      ? weeklyHours.toStringAsFixed(0)
      : weeklyHours.toStringAsFixed(1);
  final pace = weeklyHours < 6
      ? 'a light pace'
      : weeklyHours <= 14
      ? 'a steady pace'
      : 'an intense pace';
  return '≈ $hours hours a week · $pace';
}
