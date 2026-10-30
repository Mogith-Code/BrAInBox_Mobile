import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Mistake, Topic;

part 'insights_models.freezed.dart';
part 'insights_models.g.dart';

/// How well a student knows a topic, as decided by the backend.
///
/// Never computed in the app: always read from `status` in the response.
/// New values from the backend become [unknown] instead of crashing.
enum TopicStatus {
  @JsonValue('strong')
  strong,
  @JsonValue('good')
  good,
  @JsonValue('developing')
  developing,
  @JsonValue('weak')
  weak,
  @JsonValue('very_weak')
  veryWeak,
  @JsonValue('insufficient_data')
  insufficientData,
  @JsonValue('not_attempted')
  notAttempted,
  @JsonValue('unknown')
  unknown,
}

/// Kind of study resource. New values become [unknown] (generic icon).
enum ResourceType {
  @JsonValue('video')
  video,
  @JsonValue('article')
  article,
  @JsonValue('pdf')
  pdf,
  @JsonValue('notes')
  notes,
  @JsonValue('website')
  website,
  @JsonValue('unknown')
  unknown,
}

/// Response of `GET /insights/topics`.
@freezed
abstract class TopicInsights with _$TopicInsights {
  const TopicInsights._();

  const factory TopicInsights({
    /// Set when only one attempt was analysed (`?attempt_id=`).
    String? attemptId,
    @Default(0) int attemptsAnalysed,

    /// Below this many valid answers a topic is not [TopicResult.reliable].
    @Default(5) int minQuestionsPerTopic,
    required OverallResult overall,

    /// Ranked weakest first by the backend. Keep this order.
    @Default(<TopicResult>[]) List<TopicResult> topics,

    /// Topic names (not ids).
    @Default(<String>[]) List<String> weakTopics,

    /// Topic names (not ids).
    @Default(<String>[]) List<String> insufficientDataTopics,
    @Default(<TopicFeedback>[]) List<TopicFeedback> feedback,
    @Default(<GradeBand>[]) List<GradeBand> gradeBands,
    @Default('') String note,
  }) = _TopicInsights;

  factory TopicInsights.fromJson(Map<String, dynamic> json) =>
      _$TopicInsightsFromJson(json);

  /// True when the student has no finished answers yet.
  bool get isEmpty => overall.attempted == 0;

  /// Finds a topic by its [TopicResult.key].
  TopicResult? topicByKey(String key) {
    for (final topic in topics) {
      if (topic.key == key) return topic;
    }
    return null;
  }

  /// Finds a topic by its name (used for [weakTopics] and
  /// [insufficientDataTopics], which only hold names).
  TopicResult? topicByName(String name) {
    for (final topic in topics) {
      if (topic.topic == name) return topic;
    }
    return null;
  }

  /// The feedback for [topic]: matched by `topic_id`, or by the topic name
  /// when the id is null (the "General" group).
  TopicFeedback? feedbackFor(TopicResult topic) {
    for (final item in feedback) {
      final sameId = topic.topicId != null && item.topicId == topic.topicId;
      final sameName =
          topic.topicId == null &&
          item.topicId == null &&
          item.topic == topic.topic;
      if (sameId || sameName) return item;
    }
    return null;
  }

  /// Units in the order they first appear in [topics].
  List<String> get unitsInOrder {
    final units = <String>[];
    for (final topic in topics) {
      if (!units.contains(topic.unitName)) units.add(topic.unitName);
    }
    return units;
  }

  /// The topics of one unit, in server order.
  List<TopicResult> topicsInUnit(String unit) =>
      topics.where((t) => t.unitName == unit).toList();

  /// How many topics have each status (for the summary row).
  Map<TopicStatus, int> get statusCounts {
    final counts = <TopicStatus, int>{};
    for (final topic in topics) {
      counts[topic.status] = (counts[topic.status] ?? 0) + 1;
    }
    return counts;
  }

  /// The last reliable topic. [topics] is ranked weakest first, so this is
  /// the strongest one the backend is confident about.
  TopicResult? get strongestTopic {
    for (final topic in topics.reversed) {
      if (topic.reliable && topic.percent != null) return topic;
    }
    return null;
  }

  /// The first entry of [weakTopics], if it matches a topic.
  TopicResult? get weakestTopic {
    for (final name in weakTopics) {
      final topic = topicByName(name);
      if (topic != null) return topic;
    }
    return null;
  }
}

/// Totals across every topic.
@freezed
abstract class OverallResult with _$OverallResult {
  const factory OverallResult({
    @Default(0) int correct,
    @Default(0) int attempted,
    @Default(0) int unanswered,
    @Default(0) int excluded,

    /// Null when nothing was attempted. Show "Not attempted", never 0 %.
    double? percent,
    String? grade,
    String? gradeLabel,
  }) = _OverallResult;

  factory OverallResult.fromJson(Map<String, dynamic> json) =>
      _$OverallResultFromJson(json);
}

/// One topic's result.
@freezed
abstract class TopicResult with _$TopicResult {
  const TopicResult._();

  const factory TopicResult({
    /// Null for the "General" group (questions without a syllabus topic).
    String? topicId,
    required String topic,
    String? topicNumber,
    String? unit,
    @Default(0) int correct,
    @Default(0) int attempted,
    @Default(0) int unanswered,

    /// Null when nothing was attempted. Show "Not attempted", never 0 %.
    double? percent,
    String? grade,
    String? gradeLabel,
    @JsonKey(unknownEnumValue: TopicStatus.unknown)
    @Default(TopicStatus.unknown)
    TopicStatus status,
    String? understanding,

    /// False when there are fewer than `min_questions_per_topic` answers.
    @Default(false) bool reliable,
  }) = _TopicResult;

  factory TopicResult.fromJson(Map<String, dynamic> json) =>
      _$TopicResultFromJson(json);

  /// Stable id for navigation: the topic id, or the name when it is null.
  String get key => topicId ?? 'name:$topic';

  /// The unit name, or "Other" when the backend sends none.
  String get unitName => (unit == null || unit!.isEmpty) ? 'Other' : unit!;

  /// How many more answers are needed before the result is reliable.
  int questionsNeeded(int minQuestionsPerTopic) {
    final needed = minQuestionsPerTopic - attempted;
    return needed < 0 ? 0 : needed;
  }
}

/// What the backend says about one topic and what to do next.
@freezed
abstract class TopicFeedback with _$TopicFeedback {
  const factory TopicFeedback({
    String? topicId,
    required String topic,
    @Default(0) int correct,
    @Default(0) int attempted,
    double? percent,
    String? grade,
    @JsonKey(unknownEnumValue: TopicStatus.unknown)
    @Default(TopicStatus.unknown)
    TopicStatus status,
    @Default('') String summary,
    @Default('') String action,
    @Default(<ReviewQuestion>[]) List<ReviewQuestion> reviewQuestions,
    @Default(<Misconception>[]) List<Misconception> misconceptions,
    @Default(<StudyResource>[]) List<StudyResource> resources,
  }) = _TopicFeedback;

  factory TopicFeedback.fromJson(Map<String, dynamic> json) =>
      _$TopicFeedbackFromJson(json);
}

/// A question the student got wrong and should look at again.
@freezed
abstract class ReviewQuestion with _$ReviewQuestion {
  const factory ReviewQuestion({
    required String questionId,
    required String question,
    String? modelAnswer,
  }) = _ReviewQuestion;

  factory ReviewQuestion.fromJson(Map<String, dynamic> json) =>
      _$ReviewQuestionFromJson(json);
}

/// A common wrong idea linked to the topic.
@freezed
abstract class Misconception with _$Misconception {
  const factory Misconception({
    required String id,
    required String title,
    String? description,
  }) = _Misconception;

  factory Misconception.fromJson(Map<String, dynamic> json) =>
      _$MisconceptionFromJson(json);
}

/// A link to revise from (video, article...).
@freezed
abstract class StudyResource with _$StudyResource {
  const factory StudyResource({
    required String id,
    required String title,
    required String url,
    @JsonKey(unknownEnumValue: ResourceType.unknown)
    @Default(ResourceType.unknown)
    ResourceType resourceType,
  }) = _StudyResource;

  factory StudyResource.fromJson(Map<String, dynamic> json) =>
      _$StudyResourceFromJson(json);
}

/// One grade boundary, e.g. A = 75 % and above.
@freezed
abstract class GradeBand with _$GradeBand {
  const factory GradeBand({
    required String grade,
    required String label,
    @Default(0) double minPercent,

    /// Null for the top band.
    double? maxPercent,
  }) = _GradeBand;

  factory GradeBand.fromJson(Map<String, dynamic> json) =>
      _$GradeBandFromJson(json);
}
