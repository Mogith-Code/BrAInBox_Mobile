/// Plain models for the paper endpoints (`GET /papers`, `GET /papers/{id}`,
/// `POST /papers/generate`). Field names follow the backend's
/// `api/modules/exams/schemas.py`.
library;

/// Question types a paper can contain.
enum PaperQuestionType {
  mcq('mcq', 'Part I · MCQ'),
  structured('structured', 'Part II · Structured'),
  essay('essay', 'Essay');

  const PaperQuestionType(this.api, this.label);

  final String api;
  final String label;

  static PaperQuestionType fromApi(String? value) => values.firstWhere(
    (t) => t.api == value,
    orElse: () => PaperQuestionType.mcq,
  );
}

int? _int(Object? v) => v is num ? v.toInt() : null;

/// One row of `GET /papers`.
class PaperSummary {
  const PaperSummary({
    required this.id,
    required this.title,
    this.paperType = 'past_paper',
    this.year,
    this.questionTypes = const [],
    this.questionCount = 0,
    this.outdatedCount = 0,
    this.totalMarks,
    this.durationMinutes,
  });

  factory PaperSummary.fromJson(Map<String, dynamic> json) => PaperSummary(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Paper',
    paperType: json['paper_type'] as String? ?? 'past_paper',
    year: _int(json['year']),
    questionTypes: [
      for (final t in (json['question_types'] as List? ?? const []))
        PaperQuestionType.fromApi(t as String?),
    ],
    questionCount: _int(json['question_count']) ?? 0,
    outdatedCount: _int(json['outdated_count']) ?? 0,
    totalMarks: _int(json['total_marks']),
    durationMinutes: _int(json['duration_minutes']),
  );

  final String id;
  final String title;
  final String paperType;
  final int? year;
  final List<PaperQuestionType> questionTypes;
  final int questionCount;
  final int outdatedCount;
  final int? totalMarks;
  final int? durationMinutes;
}

/// One question as the student sees it on a paper (no answer).
class PaperQuestion {
  const PaperQuestion({
    required this.id,
    required this.position,
    required this.type,
    required this.stem,
    this.topicId,
    this.topic = '',
    this.marks = 1,
    this.options = const [],
    this.isOutdated = false,
  });

  factory PaperQuestion.fromJson(Map<String, dynamic> json) => PaperQuestion(
    id: json['id'] as String,
    position: _int(json['position']) ?? 0,
    type: PaperQuestionType.fromApi(json['question_type'] as String?),
    stem: json['stem'] as String? ?? '',
    topicId: json['topic_id'] as String?,
    topic: json['topic'] as String? ?? '',
    marks: _int(json['marks']) ?? 1,
    options: [
      for (final o in (json['options'] as List? ?? const []))
        (
          label: (o as Map)['label'] as String? ?? '',
          text: o['text'] as String? ?? '',
        ),
    ],
    isOutdated: json['is_outdated'] as bool? ?? false,
  );

  final String id;
  final int position;
  final PaperQuestionType type;
  final String stem;
  final String? topicId;
  final String topic;
  final int marks;
  final List<({String label, String text})> options;
  final bool isOutdated;
}

/// `GET /papers/{id}`.
class PaperDetail {
  const PaperDetail({
    required this.id,
    required this.title,
    this.paperType = 'past_paper',
    this.year,
    this.durationMinutes,
    this.totalMarks,
    this.hiddenOutdated = 0,
    this.questions = const [],
  });

  factory PaperDetail.fromJson(Map<String, dynamic> json) => PaperDetail(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Paper',
    paperType: json['paper_type'] as String? ?? 'past_paper',
    year: _int(json['year']),
    durationMinutes: _int(json['duration_minutes']),
    totalMarks: _int(json['total_marks']),
    hiddenOutdated: _int(json['hidden_outdated']) ?? 0,
    questions: [
      for (final q in (json['questions'] as List? ?? const []))
        PaperQuestion.fromJson(q as Map<String, dynamic>),
    ]..sort((a, b) => a.position.compareTo(b.position)),
  );

  final String id;
  final String title;
  final String paperType;
  final int? year;
  final int? durationMinutes;
  final int? totalMarks;
  final int hiddenOutdated;
  final List<PaperQuestion> questions;

  bool get isAiGenerated => paperType == 'ai_generated';

  List<PaperQuestion> ofType(PaperQuestionType type) =>
      questions.where((q) => q.type == type).toList();
}

/// Body of `POST /papers/generate`.
class PaperBlueprint {
  const PaperBlueprint({
    required this.unitNumbers,
    this.mcqCount = 20,
    this.structuredCount = 0,
    this.essayCount = 0,
    this.timeLimitMinutes,
    this.title,
  });

  final List<int> unitNumbers;
  final int mcqCount;
  final int structuredCount;
  final int essayCount;
  final int? timeLimitMinutes;
  final String? title;

  int get total => mcqCount + structuredCount + essayCount;

  Map<String, dynamic> toJson() => {
    'unit_numbers': unitNumbers,
    'mcq_count': mcqCount,
    'structured_count': structuredCount,
    'essay_count': essayCount,
    'time_limit_minutes': ?timeLimitMinutes,
    if (title != null && title!.isNotEmpty) 'title': title,
  };
}

/// 202 of `POST /papers/generate`.
class PaperJob {
  const PaperJob({required this.jobId, this.fromBank = 0, this.toGenerate = 0});

  factory PaperJob.fromJson(Map<String, dynamic> json) => PaperJob(
    jobId: json['job_id'] as String,
    fromBank: _int(json['from_bank']) ?? 0,
    toGenerate: _int(json['to_generate']) ?? 0,
  );

  final String jobId;
  final int fromBank;
  final int toGenerate;
}
