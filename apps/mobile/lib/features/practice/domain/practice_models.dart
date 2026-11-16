/// Models of the Practice feature (quizzes with instant feedback).
///
/// Plain classes with `fromJson`, matching the backend's `/quizzes` and
/// `/practice/hub` responses field by field.
library;

int _int(Object? value, [int fallback = 0]) =>
    value is num ? value.round() : fallback;

List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) build) => [
  for (final item in (value as List? ?? const []))
    build(Map<String, dynamic>.from(item as Map)),
];

/// A syllabus unit to choose in the quiz setup.
class PracticeUnit {
  const PracticeUnit({
    required this.id,
    required this.number,
    required this.title,
  });

  factory PracticeUnit.fromJson(Map<String, dynamic> json) => PracticeUnit(
    id: '${json['id']}',
    number: _int(json['number']),
    title: '${json['title'] ?? ''}',
  );

  final String id;
  final int number;
  final String title;
}

/// One quiz in a list (`in_progress` or finished).
class QuizBrief {
  const QuizBrief({
    required this.quizId,
    required this.title,
    required this.status,
    required this.total,
    this.score,
    this.percent,
  });

  factory QuizBrief.fromJson(Map<String, dynamic> json) => QuizBrief(
    quizId: '${json['quiz_id']}',
    title: '${json['title'] ?? 'Quiz'}',
    status: '${json['status'] ?? ''}',
    total: _int(json['total']),
    score: json['score'] == null ? null : _int(json['score']),
    percent: json['percent'] == null ? null : _int(json['percent']),
  );

  final String quizId;
  final String title;
  final String status;
  final int total;
  final int? score;
  final int? percent;
}

/// What the Practice tab shows (`GET /practice/hub`).
class PracticeHub {
  const PracticeHub({
    this.inProgress,
    this.recent = const [],
    this.openMistakes = 0,
    this.weakConcepts = 0,
    this.approvedQuestions = 0,
  });

  factory PracticeHub.fromJson(Map<String, dynamic> json) => PracticeHub(
    inProgress: json['in_progress'] == null
        ? null
        : QuizBrief.fromJson(
            Map<String, dynamic>.from(json['in_progress'] as Map),
          ),
    recent: _list(json['recent'], QuizBrief.fromJson),
    openMistakes: _int(json['open_mistakes']),
    weakConcepts: _int(json['weak_concepts']),
    approvedQuestions: _int(json['approved_questions']),
  );

  final QuizBrief? inProgress;
  final List<QuizBrief> recent;
  final int openMistakes;
  final int weakConcepts;
  final int approvedQuestions;
}

/// What the student chose on the quiz setup screen.
class QuizSetup {
  const QuizSetup({
    this.unit,
    this.topic,
    this.conceptId,
    this.count = 10,
    this.difficulty = 'mixed',
    this.timed = false,
    this.focusWeak = false,
    this.mistakesOnly = false,
  });

  final String? unit;
  final String? topic;
  final String? conceptId;
  final int count;

  /// `easy`, `medium`, `hard` or `mixed`.
  final String difficulty;
  final bool timed;
  final bool focusWeak;
  final bool mistakesOnly;

  Map<String, dynamic> toJson() => {
    'unit': ?unit,
    'topic': ?topic,
    'concept_id': ?conceptId,
    'count': count,
    'difficulty': difficulty,
    'timed': timed,
    'focus_weak': focusWeak,
    'mistakes_only': mistakesOnly,
  };
}

class QuizOption {
  const QuizOption({required this.id, required this.label, required this.text});

  factory QuizOption.fromJson(Map<String, dynamic> json) => QuizOption(
    id: '${json['id']}',
    label: '${json['label'] ?? ''}',
    text: '${json['text'] ?? ''}',
  );

  final String id;

  /// "A".."E"
  final String label;
  final String text;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.position,
    required this.stem,
    required this.unitCode,
    required this.topicId,
    required this.topicTitle,
    required this.difficulty,
    required this.options,
    this.selectedOptionId,
    this.correctOptionId,
    this.isCorrect,
    this.flagged = false,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    id: '${json['id']}',
    position: _int(json['position'], 1),
    stem: '${json['stem'] ?? ''}',
    unitCode: '${json['unit_code'] ?? ''}',
    topicId: '${json['topic_id'] ?? ''}',
    topicTitle: '${json['topic_title'] ?? ''}',
    difficulty: '${json['difficulty'] ?? 'medium'}',
    options: _list(json['options'], QuizOption.fromJson),
    selectedOptionId: json['selected_option_id'] as String?,
    correctOptionId: json['correct_option_id'] as String?,
    isCorrect: json['is_correct'] as bool?,
    flagged: json['flagged'] == true,
  );

  final String id;
  final int position;
  final String stem;
  final String unitCode;
  final String topicId;
  final String topicTitle;
  final String difficulty;
  final List<QuizOption> options;
  final String? selectedOptionId;
  final String? correctOptionId;
  final bool? isCorrect;
  final bool flagged;

  bool get isAnswered => selectedOptionId != null;

  QuizQuestion copyWith({
    String? selectedOptionId,
    String? correctOptionId,
    bool? isCorrect,
    bool? flagged,
  }) => QuizQuestion(
    id: id,
    position: position,
    stem: stem,
    unitCode: unitCode,
    topicId: topicId,
    topicTitle: topicTitle,
    difficulty: difficulty,
    options: options,
    selectedOptionId: selectedOptionId ?? this.selectedOptionId,
    correctOptionId: correctOptionId ?? this.correctOptionId,
    isCorrect: isCorrect ?? this.isCorrect,
    flagged: flagged ?? this.flagged,
  );
}

class Quiz {
  const Quiz({
    required this.quizId,
    required this.title,
    required this.status,
    required this.questions,
    this.timeLimitMinutes,
    this.startedAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
    quizId: '${json['quiz_id']}',
    title: '${json['title'] ?? 'Quiz'}',
    status: '${json['status'] ?? 'in_progress'}',
    questions: _list(json['questions'], QuizQuestion.fromJson),
    timeLimitMinutes: json['time_limit_minutes'] == null
        ? null
        : _int(json['time_limit_minutes']),
    startedAt: DateTime.tryParse('${json['started_at'] ?? ''}'),
  );

  final String quizId;
  final String title;
  final String status;
  final List<QuizQuestion> questions;
  final int? timeLimitMinutes;
  final DateTime? startedAt;

  bool get isFinished => status != 'in_progress';
  int get answered => questions.where((q) => q.isAnswered).length;

  Quiz copyWithQuestion(QuizQuestion question) => Quiz(
    quizId: quizId,
    title: title,
    status: status,
    questions: [for (final q in questions) q.id == question.id ? question : q],
    timeLimitMinutes: timeLimitMinutes,
    startedAt: startedAt,
  );
}

/// The misconception behind a wrong option.
class MisconceptionCard {
  const MisconceptionCard({
    required this.title,
    this.description,
    this.correction,
  });

  factory MisconceptionCard.fromJson(Map<String, dynamic> json) =>
      MisconceptionCard(
        title: '${json['title'] ?? ''}',
        description: json['description'] as String?,
        correction: json['correction'] as String?,
      );

  final String title;
  final String? description;
  final String? correction;
}

/// Instant feedback after one answer (`POST /quizzes/{id}/responses`).
class AnswerFeedback {
  const AnswerFeedback({
    required this.questionId,
    required this.selectedOptionId,
    required this.correctOptionId,
    required this.isCorrect,
    this.explanation,
    this.optionExplanation,
    this.misconception,
    this.conceptName,
    this.topicId,
    this.masteryBefore,
    this.masteryAfter,
    this.masteryLevel,
    this.recurring = false,
    this.recurringCount = 0,
  });

  factory AnswerFeedback.fromJson(Map<String, dynamic> json) {
    final concept = json['concept'] as Map?;
    final mastery = json['mastery'] as Map?;
    return AnswerFeedback(
      questionId: '${json['question_id']}',
      selectedOptionId: '${json['selected_option_id']}',
      correctOptionId: '${json['correct_option_id']}',
      isCorrect: json['is_correct'] == true,
      explanation: json['explanation'] as String?,
      optionExplanation: json['option_explanation'] as String?,
      misconception: json['misconception'] == null
          ? null
          : MisconceptionCard.fromJson(
              Map<String, dynamic>.from(json['misconception'] as Map),
            ),
      conceptName: concept?['name'] as String?,
      topicId: concept?['topic_id'] as String?,
      masteryBefore: mastery?['before'] == null
          ? null
          : _int(mastery?['before']),
      masteryAfter: mastery?['after'] == null ? null : _int(mastery?['after']),
      masteryLevel: mastery?['level'] as String?,
      recurring: json['recurring_misconception'] == true,
      recurringCount: _int(json['recurring_count']),
    );
  }

  final String questionId;
  final String selectedOptionId;
  final String correctOptionId;
  final bool isCorrect;
  final String? explanation;
  final String? optionExplanation;
  final MisconceptionCard? misconception;
  final String? conceptName;
  final String? topicId;
  final int? masteryBefore;
  final int? masteryAfter;
  final String? masteryLevel;

  /// The same misconception 3+ times in 14 days.
  final bool recurring;
  final int recurringCount;
}

class TopicAccuracy {
  const TopicAccuracy({
    required this.topicId,
    required this.topic,
    required this.correct,
    required this.total,
    required this.percent,
  });

  factory TopicAccuracy.fromJson(Map<String, dynamic> json) => TopicAccuracy(
    topicId: '${json['topic_id']}',
    topic: '${json['topic'] ?? ''}',
    correct: _int(json['correct']),
    total: _int(json['total']),
    percent: _int(json['percent']),
  );

  final String topicId;
  final String topic;
  final int correct;
  final int total;
  final int percent;
}

class ReviewItem {
  const ReviewItem({
    required this.position,
    required this.stem,
    required this.topic,
    required this.correct,
    required this.isCorrect,
    this.selected,
    this.explanation,
    this.flagged = false,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
    position: _int(json['position'], 1),
    stem: '${json['stem'] ?? ''}',
    topic: '${json['topic'] ?? ''}',
    correct: '${json['correct'] ?? ''}',
    isCorrect: json['is_correct'] == true,
    selected: json['selected'] as String?,
    explanation: json['explanation'] as String?,
    flagged: json['flagged'] == true,
  );

  final int position;
  final String stem;
  final String topic;
  final String correct;
  final bool isCorrect;
  final String? selected;
  final String? explanation;
  final bool flagged;
}

class MisconceptionCount {
  const MisconceptionCount({
    required this.title,
    required this.count,
    this.correction,
  });

  factory MisconceptionCount.fromJson(Map<String, dynamic> json) =>
      MisconceptionCount(
        title: '${json['title'] ?? ''}',
        count: _int(json['count']),
        correction: json['correction'] as String?,
      );

  final String title;
  final int count;
  final String? correction;
}

/// The result screen (`GET /quizzes/{id}/result`).
class QuizResult {
  const QuizResult({
    required this.quizId,
    required this.title,
    required this.score,
    required this.total,
    required this.answered,
    required this.percent,
    required this.timeSeconds,
    required this.byTopic,
    required this.misconceptions,
    required this.review,
    required this.mistakes,
    required this.disclaimer,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
    quizId: '${json['quiz_id']}',
    title: '${json['title'] ?? 'Quiz'}',
    score: _int(json['score']),
    total: _int(json['total']),
    answered: _int(json['answered']),
    percent: _int(json['percent']),
    timeSeconds: _int(json['time_seconds']),
    byTopic: _list(json['by_topic'], TopicAccuracy.fromJson),
    misconceptions: _list(json['misconceptions'], MisconceptionCount.fromJson),
    review: _list(json['review'], ReviewItem.fromJson),
    mistakes: _int(json['mistakes']),
    disclaimer: '${json['disclaimer'] ?? ''}',
  );

  final String quizId;
  final String title;
  final int score;
  final int total;
  final int answered;
  final int percent;
  final int timeSeconds;
  final List<TopicAccuracy> byTopic;
  final List<MisconceptionCount> misconceptions;
  final List<ReviewItem> review;
  final int mistakes;
  final String disclaimer;
}
