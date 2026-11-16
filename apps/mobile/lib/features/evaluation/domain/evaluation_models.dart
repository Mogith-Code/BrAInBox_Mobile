/// Models of the Evaluation feature (formative feedback on structured and
/// essay answers), matching the backend's `/evaluations` responses.
library;

double? _double(Object? value) => value is num ? value.toDouble() : null;
int _int(Object? value) => value is num ? value.round() : 0;
List<String> _strings(Object? value) => [
  for (final item in (value as List? ?? const [])) '$item',
];

/// A structured / essay question that can be checked.
class WrittenQuestion {
  const WrittenQuestion({
    required this.id,
    required this.code,
    required this.type,
    required this.stem,
    required this.marks,
    this.year,
    this.isOutdated = false,
    this.topicTitle,
    this.unitNumber,
    this.myAttempts = 0,
    this.myBestMarks,
  });

  factory WrittenQuestion.fromJson(Map<String, dynamic> json) =>
      WrittenQuestion(
        id: '${json['id']}',
        code: '${json['code'] ?? ''}',
        type: '${json['question_type'] ?? 'structured'}',
        stem: '${json['stem'] ?? ''}',
        marks: _double(json['marks']) ?? 0,
        year: json['year'] == null ? null : _int(json['year']),
        isOutdated: json['is_outdated'] == true,
        topicTitle: json['topic_title'] as String?,
        unitNumber: json['unit_number'] == null
            ? null
            : _int(json['unit_number']),
        myAttempts: _int(json['my_attempts']),
        myBestMarks: _double(json['my_best_marks']),
      );

  final String id;
  final String code;

  /// `structured` or `essay`
  final String type;
  final String stem;
  final double marks;
  final int? year;

  /// On a topic removed from the current syllabus.
  final bool isOutdated;
  final String? topicTitle;
  final int? unitNumber;
  final int myAttempts;
  final double? myBestMarks;
}

/// `202 Accepted` from `POST /evaluations` and `POST /evaluations/ocr`.
class EvaluationJob {
  const EvaluationJob({required this.evaluationId, required this.jobId});

  factory EvaluationJob.fromJson(Map<String, dynamic> json) => EvaluationJob(
    evaluationId: '${json['evaluation_id']}',
    jobId: '${json['job_id']}',
  );

  final String evaluationId;
  final String jobId;
}

/// One marking point and how the answer did on it.
class PointResult {
  const PointResult({
    required this.text,
    required this.marks,
    required this.status,
    required this.marksAwarded,
    this.evidence,
    this.matchedKeywords = const [],
  });

  factory PointResult.fromJson(Map<String, dynamic> json) => PointResult(
    text: '${json['text'] ?? ''}',
    marks: _double(json['marks']) ?? 0,
    status: '${json['status'] ?? 'missing'}',
    marksAwarded: _double(json['marks_awarded']) ?? 0,
    evidence: json['evidence'] as String?,
    matchedKeywords: _strings(json['matched_keywords']),
  );

  final String text;
  final double marks;

  /// `covered`, `partial` or `missing`
  final String status;
  final double marksAwarded;
  final String? evidence;
  final List<String> matchedKeywords;
}

/// One checked answer (`GET /evaluations/{id}`).
class Evaluation {
  const Evaluation({
    required this.id,
    required this.questionId,
    required this.question,
    required this.status,
    required this.source,
    this.answerText,
    this.ocrText,
    this.estimatedMarks,
    this.maxMarks,
    this.percent,
    this.covered = 0,
    this.partial = 0,
    this.missing = 0,
    this.points = const [],
    this.modelAnswer,
    this.feedback,
    this.tips = const [],
    this.strengths = const [],
    this.tipsAiGenerated = false,
    this.error,
    this.disclaimer = 'Formative feedback – not an official exam mark.',
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) => Evaluation(
    id: '${json['id']}',
    questionId: '${json['question_id']}',
    question: '${json['question'] ?? ''}',
    status: '${json['status'] ?? 'queued'}',
    source: '${json['source'] ?? 'typed'}',
    answerText: json['answer_text'] as String?,
    ocrText: json['ocr_text'] as String?,
    estimatedMarks: _double(json['estimated_marks']),
    maxMarks: _double(json['max_marks']),
    percent: json['percent'] == null ? null : _int(json['percent']),
    covered: _int(json['covered']),
    partial: _int(json['partial']),
    missing: _int(json['missing']),
    points: [
      for (final item in (json['points'] as List? ?? const []))
        PointResult.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
    modelAnswer: json['model_answer'] as String?,
    feedback: json['feedback'] as String?,
    tips: _strings(json['tips']),
    strengths: _strings(json['strengths']),
    tipsAiGenerated: json['tips_ai_generated'] == true,
    error: json['error'] as String?,
    disclaimer:
        '${json['disclaimer'] ?? 'Formative feedback – not an official exam mark.'}',
  );

  final String id;
  final String questionId;
  final String question;

  /// `queued`, `running`, `ocr_ready`, `succeeded` or `failed`
  final String status;

  /// `typed` or `handwritten`
  final String source;
  final String? answerText;
  final String? ocrText;
  final double? estimatedMarks;
  final double? maxMarks;
  final int? percent;
  final int covered;
  final int partial;
  final int missing;
  final List<PointResult> points;
  final String? modelAnswer;
  final String? feedback;
  final List<String> tips;
  final List<String> strengths;
  final bool tipsAiGenerated;
  final String? error;
  final String disclaimer;

  bool get isMarked => status == 'succeeded';
  bool get isWorking => status == 'queued' || status == 'running';
}

/// Marks without a trailing ".0" ("4", "2.5").
String formatMarks(double? value) {
  if (value == null) return '-';
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
