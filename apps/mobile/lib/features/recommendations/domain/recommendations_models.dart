/// Models of the Recommendations feature (next steps + weekly study plan),
/// matching the backend's `/recommendations` and `/study-plan` responses.
library;

int? _intOrNull(Object? value) => value is num ? value.round() : null;
int _int(Object? value) => _intOrNull(value) ?? 0;

/// A video attached to a recommendation.
class LearningResource {
  const LearningResource({
    required this.title,
    required this.url,
    this.channel,
    this.durationSeconds,
  });

  factory LearningResource.fromJson(Map<String, dynamic> json) =>
      LearningResource(
        title: '${json['title'] ?? ''}',
        url: '${json['url'] ?? ''}',
        channel: json['channel'] as String?,
        durationSeconds: _intOrNull(json['duration_seconds']),
      );

  final String title;
  final String url;
  final String? channel;
  final int? durationSeconds;
}

/// One next step, with the reason it was given.
class NextStep {
  const NextStep({
    required this.id,
    required this.action,
    required this.title,
    required this.reason,
    required this.priority,
    required this.estimatedMinutes,
    this.conceptId,
    this.concept,
    this.topicId,
    this.topic,
    this.unitNumber,
    this.mastery,
    this.target = const {},
    this.resource,
  });

  factory NextStep.fromJson(Map<String, dynamic> json) => NextStep(
    id: '${json['id']}',
    action: '${json['action'] ?? ''}',
    title: '${json['title'] ?? ''}',
    reason: '${json['reason'] ?? ''}',
    priority: _int(json['priority']),
    estimatedMinutes: _int(json['estimated_minutes']),
    conceptId: json['concept_id'] as String?,
    concept: json['concept'] as String?,
    topicId: json['topic_id'] as String?,
    topic: json['topic'] as String?,
    unitNumber: _intOrNull(json['unit_number']),
    mastery: _intOrNull(json['mastery']),
    target: Map<String, dynamic>.from(json['target'] as Map? ?? const {}),
    resource: json['resource'] == null
        ? null
        : LearningResource.fromJson(
            Map<String, dynamic>.from(json['resource'] as Map),
          ),
  );

  final String id;

  /// `revise_note`, `practice_quiz`, `watch_video`, `retry_answer`,
  /// `reassess` or `view_visual`
  final String action;
  final String title;

  /// "Because you missed 3 questions on ..."
  final String reason;

  /// 1 = do this first.
  final int priority;
  final int estimatedMinutes;
  final String? conceptId;
  final String? concept;
  final String? topicId;
  final String? topic;
  final int? unitNumber;
  final int? mastery;
  final Map<String, dynamic> target;
  final LearningResource? resource;
}

class NextSteps {
  const NextSteps({this.items = const [], this.hint});

  factory NextSteps.fromJson(Map<String, dynamic> json) => NextSteps(
    items: [
      for (final item in (json['items'] as List? ?? const []))
        NextStep.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
    hint: json['hint'] as String?,
  );

  final List<NextStep> items;

  /// What to do to get recommendations, when the list is empty.
  final String? hint;
}

/// Before / after of a reassessment.
class Outcome {
  const Outcome({
    required this.message,
    this.concept,
    this.before,
    this.after,
    this.change,
    this.improved = false,
  });

  factory Outcome.fromJson(Map<String, dynamic> json) => Outcome(
    message: '${json['message'] ?? ''}',
    concept: json['concept'] as String?,
    before: _intOrNull(json['before']),
    after: _intOrNull(json['after']),
    change: _intOrNull(json['change']),
    improved: json['improved'] == true,
  );

  final String message;
  final String? concept;
  final int? before;
  final int? after;
  final int? change;
  final bool improved;
}

class PlanItem {
  const PlanItem({
    required this.id,
    required this.title,
    required this.isDone,
    this.action,
    this.estimatedMinutes,
    this.conceptId,
    this.topicId,
    this.recommendationId,
    this.target = const {},
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
    id: '${json['id']}',
    title: '${json['title'] ?? ''}',
    isDone: json['is_done'] == true,
    action: json['action'] as String?,
    estimatedMinutes: _intOrNull(json['estimated_minutes']),
    conceptId: json['concept_id'] as String?,
    topicId: json['topic_id'] as String?,
    recommendationId: json['recommendation_id'] as String?,
    target: Map<String, dynamic>.from(json['target'] as Map? ?? const {}),
  );

  final String id;
  final String title;
  final bool isDone;
  final String? action;
  final int? estimatedMinutes;
  final String? conceptId;
  final String? topicId;
  final String? recommendationId;
  final Map<String, dynamic> target;

  PlanItem copyWith({bool? isDone}) => PlanItem(
    id: id,
    title: title,
    isDone: isDone ?? this.isDone,
    action: action,
    estimatedMinutes: estimatedMinutes,
    conceptId: conceptId,
    topicId: topicId,
    recommendationId: recommendationId,
    target: target,
  );
}

class PlanDay {
  const PlanDay({
    required this.date,
    required this.weekday,
    required this.isStudyDay,
    required this.minutesPlanned,
    required this.minutesAvailable,
    required this.items,
  });

  factory PlanDay.fromJson(Map<String, dynamic> json) => PlanDay(
    date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
    weekday: '${json['weekday'] ?? ''}',
    isStudyDay: json['is_study_day'] != false,
    minutesPlanned: _int(json['minutes_planned']),
    minutesAvailable: _int(json['minutes_available']),
    items: [
      for (final item in (json['items'] as List? ?? const []))
        PlanItem.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
  );

  final DateTime date;

  /// "mon".."sun"
  final String weekday;
  final bool isStudyDay;
  final int minutesPlanned;
  final int minutesAvailable;
  final List<PlanItem> items;

  PlanDay copyWith({List<PlanItem>? items}) => PlanDay(
    date: date,
    weekday: weekday,
    isStudyDay: isStudyDay,
    minutesPlanned: minutesPlanned,
    minutesAvailable: minutesAvailable,
    items: items ?? this.items,
  );
}

class StudyPlan {
  const StudyPlan({
    required this.title,
    required this.days,
    this.id,
    this.done = 0,
    this.total = 0,
    this.hint,
  });

  factory StudyPlan.fromJson(Map<String, dynamic> json) => StudyPlan(
    id: json['id'] as String?,
    title: '${json['title'] ?? 'Your study plan'}',
    done: _int(json['done']),
    total: _int(json['total']),
    days: [
      for (final item in (json['days'] as List? ?? const []))
        PlanDay.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
    hint: json['hint'] as String?,
  );

  final String? id;
  final String title;
  final int done;
  final int total;
  final List<PlanDay> days;
  final String? hint;

  StudyPlan copyWithDays(List<PlanDay> days) {
    final items = days.expand((d) => d.items);
    return StudyPlan(
      id: id,
      title: title,
      done: items.where((i) => i.isDone).length,
      total: items.length,
      days: days,
      hint: hint,
    );
  }
}
