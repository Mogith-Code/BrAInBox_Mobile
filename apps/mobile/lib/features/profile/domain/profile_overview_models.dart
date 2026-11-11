import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_overview_models.freezed.dart';
part 'profile_overview_models.g.dart';

/// A badge the student can earn (Figma F1 / F8).
@freezed
abstract class Achievement with _$Achievement {
  const Achievement._();

  const factory Achievement({
    required String id,
    required String title, // "Genetics fixer"
    @Default('') String icon, // streak, first_mastery, genetics_fixer...
    @Default('')
    String description, // "You took Genetics from Weak to Strong in 9 days."
    @Default(false) bool unlocked,
    DateTime? unlockedAt,
    @Default(false) bool seen, // false = show the "Achievement unlocked" pop-up
    String? badgeLabel, // "Strong"
    int? xp, // 150
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);

  /// The picture for [icon] (locked badges show a lock).
  String get emoji => !unlocked
      ? '🔒'
      : switch (icon) {
          'streak' => '🔥',
          'first_mastery' => '🌱',
          'genetics_fixer' || 'unit_fixer' => '🧬',
          'mcq_100' => '🎯',
          'past_paper_pro' => '📄',
          'unit_master' => '🏆',
          _ => '⭐',
        };
}

/// `GET /profile/overview`: the Profile page (Figma F1) in one call.
@freezed
abstract class ProfileOverview with _$ProfileOverview {
  const ProfileOverview._();

  const factory ProfileOverview({
    @Default('') String fullName,
    @Default('') String streamLabel, // "Biological Science"
    int? examYear,
    String? targetGrade, // "A"
    int? daysToExam,
    @Default(0) int streakDays,
    @Default(0) int questionsAnswered,
    @Default(0) int topicsMastered,
    @Default([]) List<Achievement> achievements,
    @Default(0) int achievementsTotal, // all that exist ("4 of 18")
  }) = _ProfileOverview;

  factory ProfileOverview.fromJson(Map<String, dynamic> json) =>
      _$ProfileOverviewFromJson(json);

  int get unlockedCount => achievements.where((a) => a.unlocked).length;

  /// The newest unlocked badge the student hasn't seen yet, if any.
  Achievement? get unseen =>
      achievements.where((a) => a.unlocked && !a.seen).firstOrNull;
}
