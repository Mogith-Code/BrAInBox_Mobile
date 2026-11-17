/// Models for `GET /insights/overview` and `GET /insights/heatmap`.
///
/// Plain classes (no codegen). Every number is shown as the backend sent it;
/// nothing is recomputed in the app.
library;

import 'insights_models.dart';

int? _intOrNull(Object? value) => value is num ? value.round() : null;
int _int(Object? value) => _intOrNull(value) ?? 0;

DateTime _date(Object? value) =>
    DateTime.tryParse('${value ?? ''}') ??
    DateTime.fromMillisecondsSinceEpoch(0);

List<Map<String, dynamic>> _list(Object? value) => [
  if (value is List)
    for (final item in value)
      if (item is Map<String, dynamic>) item,
];

/// Minutes studied on one day.
class StudyDay {
  const StudyDay({required this.date, required this.minutes});

  factory StudyDay.fromJson(Map<String, dynamic> json) =>
      StudyDay(date: _date(json['date']), minutes: _int(json['minutes']));

  final DateTime date;
  final int minutes;
}

/// MCQ accuracy on one day that had answers.
class AccuracyDay {
  const AccuracyDay({
    required this.date,
    required this.answered,
    this.accuracy,
  });

  factory AccuracyDay.fromJson(Map<String, dynamic> json) => AccuracyDay(
    date: _date(json['date']),
    answered: _int(json['answered']),
    accuracy: _intOrNull(json['accuracy']),
  );

  final DateTime date;
  final int answered;

  /// 0-100. Null when nothing valid was answered that day.
  final int? accuracy;
}

/// Response of `GET /insights/overview`.
class InsightsOverview {
  const InsightsOverview({
    this.overallMastery,
    this.masteryChangeWeek,
    this.streakDays = 0,
    this.studyMinutesWeek = 0,
    this.studyTime = const [],
    this.accuracyTrend = const [],
  });

  factory InsightsOverview.fromJson(Map<String, dynamic> json) =>
      InsightsOverview(
        overallMastery: _intOrNull(json['overall_mastery']),
        masteryChangeWeek: _intOrNull(json['mastery_change_week']),
        streakDays: _int(json['streak_days']),
        studyMinutesWeek: _int(json['study_minutes_week']),
        studyTime: [
          for (final d in _list(json['study_time'])) StudyDay.fromJson(d),
        ],
        accuracyTrend: [
          for (final d in _list(json['accuracy_trend']))
            AccuracyDay.fromJson(d),
        ],
      );

  /// 0-100, null for a new student.
  final int? overallMastery;
  final int? masteryChangeWeek;
  final int streakDays;
  final int studyMinutesWeek;

  /// The last 7 days, oldest first.
  final List<StudyDay> studyTime;

  /// Days with answers in the last 14 days, oldest first.
  final List<AccuracyDay> accuracyTrend;

  /// The accuracy days that have a value (the line chart's points).
  List<AccuracyDay> get accuracyPoints =>
      accuracyTrend.where((d) => d.accuracy != null).toList();
}

/// A topic's level on the heatmap, as decided by the backend.
enum HeatmapLevel {
  mastered('mastered', 'Mastered', TopicStatus.strong),
  strong('strong', 'Strong', TopicStatus.good),
  improving('improving', 'Improving', TopicStatus.developing),
  weak('weak', 'Weak', TopicStatus.weak),
  notStarted('not_started', 'Not started', TopicStatus.notAttempted),

  /// A value this app version does not know yet.
  unknown('unknown', 'Unknown', TopicStatus.unknown);

  const HeatmapLevel(this.apiValue, this.label, this.colourAs);

  final String apiValue;
  final String label;

  /// The [TopicStatus] whose colour and icon this level uses.
  final TopicStatus colourAs;

  static HeatmapLevel parse(Object? value) => HeatmapLevel.values.firstWhere(
    (l) => l.apiValue == value,
    orElse: () => HeatmapLevel.unknown,
  );
}

/// One topic on the heatmap.
class HeatmapTopic {
  const HeatmapTopic({
    required this.topicId,
    required this.number,
    required this.title,
    this.code,
    this.mastery,
    this.level = HeatmapLevel.notStarted,
    this.conceptsPractised = 0,
    this.conceptsTotal = 0,
  });

  factory HeatmapTopic.fromJson(Map<String, dynamic> json) => HeatmapTopic(
    topicId: '${json['topic_id']}',
    code: json['code'] as String?,
    number: '${json['number'] ?? ''}',
    title: '${json['title'] ?? ''}',
    mastery: _intOrNull(json['mastery']),
    level: HeatmapLevel.parse(json['level']),
    conceptsPractised: _int(json['concepts_practised']),
    conceptsTotal: _int(json['concepts_total']),
  );

  final String topicId;
  final String? code;
  final String number;
  final String title;

  /// 0-100, null = nothing practised yet (shown as "—", never 0).
  final int? mastery;
  final HeatmapLevel level;
  final int conceptsPractised;
  final int conceptsTotal;
}

/// One unit row on the heatmap.
class HeatmapUnit {
  const HeatmapUnit({
    required this.unitId,
    required this.number,
    required this.title,
    this.topics = const [],
  });

  factory HeatmapUnit.fromJson(Map<String, dynamic> json) => HeatmapUnit(
    unitId: '${json['unit_id']}',
    number: _int(json['number']),
    title: '${json['title'] ?? ''}',
    topics: [for (final t in _list(json['topics'])) HeatmapTopic.fromJson(t)],
  );

  final String unitId;
  final int number;
  final String title;
  final List<HeatmapTopic> topics;
}

/// Response of `GET /insights/heatmap`: units in syllabus order.
class TopicHeatmap {
  const TopicHeatmap({this.units = const []});

  factory TopicHeatmap.fromJson(Map<String, dynamic> json) => TopicHeatmap(
    units: [for (final u in _list(json['units'])) HeatmapUnit.fromJson(u)],
  );

  final List<HeatmapUnit> units;

  bool get hasTopics => units.any((u) => u.topics.isNotEmpty);

  bool get nothingPractised =>
      units.every((u) => u.topics.every((t) => t.mastery == null));
}
