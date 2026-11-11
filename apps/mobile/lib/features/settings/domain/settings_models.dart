import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_models.freezed.dart';
part 'settings_models.g.dart';

/// Settings > Notifications (`GET /settings`, `PATCH /settings`).
@freezed
abstract class NotificationSettings with _$NotificationSettings {
  const factory NotificationSettings({
    @Default(true) bool studyReminders,
    @Default('20:30') String reminderTime, // 24 h "HH:mm", Sri Lanka time
    @Default(true) bool communityReplies,
  }) = _NotificationSettings;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);
}

/// Data & privacy choices (Figma F3, `GET /privacy`, `PATCH /privacy`).
/// Personalised recommendations are needed for the core app, so that one
/// is always on.
@freezed
abstract class PrivacySettings with _$PrivacySettings {
  const factory PrivacySettings({
    @Default(true) bool personalisedRecommendations,
    @Default(true) bool improveAi, // anonymised answers improve AI feedback
    @Default(true) bool showNameInCommunity, // otherwise "A/L student"
    @Default(false) bool shareResearch, // anonymised, approved universities
  }) = _PrivacySettings;

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$PrivacySettingsFromJson(json);
}

/// "20:30" -> "8:30 PM"
String friendlyTime(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts.first) ?? 20;
  final m = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12:$m ${h < 12 ? 'AM' : 'PM'}';
}
