import 'package:freezed_annotation/freezed_annotation.dart';

part 'moderation_models.freezed.dart';
part 'moderation_models.g.dart';

/// What a report is about. The backend sends visuals today; posts and
/// replies come with the community module.
enum ReportTarget { post, reply, visual }

/// What an admin does with a report
/// (`POST /admin/moderation/reports/{id}/resolve` with `{action}`).
enum ModerationAction {
  keep('Keep'),
  warn('Warn'),
  remove('Remove');

  const ModerationAction(this.label);

  final String label;
}

/// One item in the moderation queue (`GET /admin/moderation/reports`).
///
/// Works with today's visual reports (`visual_title`, `image_url`) and the
/// planned post / reply reports (`author_handle`, `group_name`, `text`,
/// `ai_flag_label`, `ai_flag_score`).
@freezed
abstract class ModerationItem with _$ModerationItem {
  const factory ModerationItem({
    required String id,
    @JsonKey(unknownEnumValue: ReportTarget.post)
    @Default(ReportTarget.visual)
    ReportTarget targetType,
    @Default('other') String reason, // e.g. spam, offensive, wrong_label
    String? details,
    String? authorHandle, // "kavindu_22"
    String? groupName, // "Unit 6 · Genetics"
    String? text, // the post / reply text
    String? visualTitle,
    String? imageUrl,
    String? aiFlagLabel, // "Spam / external link"
    double? aiFlagScore, // 0.0 - 1.0
    @Default(1) int reportCount,
    DateTime? createdAt,
  }) = _ModerationItem;

  factory ModerationItem.fromJson(Map<String, dynamic> json) =>
      _$ModerationItemFromJson(json);
}

/// A study group in the right-hand list (`GET /admin/community/groups`).
@freezed
abstract class StudyGroup with _$StudyGroup {
  const factory StudyGroup({
    required String id,
    required String name,
    @Default(0) int members,
    String? moderatorName, // null = no moderator yet
    @Default(true) bool isOpen,
  }) = _StudyGroup;

  factory StudyGroup.fromJson(Map<String, dynamic> json) =>
      _$StudyGroupFromJson(json);
}
