import 'package:freezed_annotation/freezed_annotation.dart';

part 'notifications_models.freezed.dart';
part 'notifications_models.g.dart';

/// What a notification is about (picks its icon and filter chip).
enum NotificationKind {
  reminder,
  recommendation,
  community,
  achievement,
  streak,
  other,
}

/// One row of the Notification center (`GET /notifications`).
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    @JsonKey(unknownEnumValue: NotificationKind.other)
    @Default(NotificationKind.other)
    NotificationKind type,
    required String title,
    @Default('') String body,
    DateTime? createdAt,
    @Default(false) bool read,
    @Default(false) bool aiGenerated,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}

/// The chips above the list (Figma F4).
enum NotificationFilter {
  all('All', null),
  reminders('Reminders', NotificationKind.reminder),
  recommendations('Recommendations', NotificationKind.recommendation),
  community('Community', NotificationKind.community);

  const NotificationFilter(this.label, this.kind);

  final String label;
  final NotificationKind? kind;

  bool matches(AppNotification n) => kind == null || n.type == kind;
}
