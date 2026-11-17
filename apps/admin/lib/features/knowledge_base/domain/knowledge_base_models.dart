import '../../../widgets/admin_page.dart';

// Model answers with marking points (admin). Backend:
// `api/modules/knowledge_base/schemas.py` (`ModelAnswerIn`, `ModelAnswerOut`,
// `ModelAnswerKeywordsIn`), routes in `admin/knowledge_admin.py`.

/// One marking point: what earns the marks, and the words the evaluator
/// looks for.
class AnswerPoint {
  const AnswerPoint({
    required this.id,
    required this.text,
    this.marks = 1,
    this.keywords = const [],
  });

  factory AnswerPoint.fromJson(Map<String, dynamic> json) => AnswerPoint(
    id: '${json['id']}',
    text: json['text'] as String? ?? '',
    marks: (json['marks'] as num?)?.toDouble() ?? 1,
    keywords: [for (final k in json['keywords'] as List? ?? const []) '$k'],
  );

  final String id;
  final String text;
  final double marks;
  final List<String> keywords;

  AnswerPoint withKeywords(List<String> keywords) =>
      AnswerPoint(id: id, text: text, marks: marks, keywords: keywords);
}

/// One row of `GET /admin/model-answers`.
class ModelAnswer {
  const ModelAnswer({
    required this.id,
    required this.questionId,
    required this.answerText,
    required this.status,
    required this.updatedAt,
    this.questionCode,
    this.questionStem,
    this.totalMarks = 0,
    this.source,
    this.points = const [],
  });

  factory ModelAnswer.fromJson(Map<String, dynamic> json) => ModelAnswer(
    id: '${json['id']}',
    questionId: '${json['question_id']}',
    questionCode: json['question_code'] as String?,
    questionStem: json['question_stem'] as String?,
    answerText: json['answer_text'] as String? ?? '',
    totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0,
    source: json['source'] as String?,
    status: ReviewStatus.fromApi(json['status'] as String?),
    points: [
      for (final p in json['points'] as List? ?? const [])
        AnswerPoint.fromJson(Map<String, dynamic>.from(p as Map)),
    ],
    updatedAt:
        DateTime.tryParse('${json['updated_at']}')?.toLocal() ?? DateTime(2000),
  );

  final String id;
  final String questionId;
  final String? questionCode;
  final String? questionStem;
  final String answerText;

  /// The sum of the points' marks.
  final double totalMarks;

  /// `marking_scheme | admin | ai`.
  final String? source;
  final ReviewStatus status;
  final List<AnswerPoint> points;
  final DateTime updatedAt;

  bool get isAiWritten => source == 'ai';

  /// Students can only practise (and be marked on) a question whose model
  /// answer is approved and has marking points.
  bool get isPractisable =>
      status == ReviewStatus.approved && points.isNotEmpty;

  ModelAnswer withPoints(List<AnswerPoint> points) => ModelAnswer(
    id: id,
    questionId: questionId,
    questionCode: questionCode,
    questionStem: questionStem,
    answerText: answerText,
    totalMarks: totalMarks,
    source: source,
    status: status,
    points: points,
    updatedAt: updatedAt,
  );
}

/// Where a model answer came from (`ModelAnswerIn.source`).
enum AnswerSource {
  admin('admin', 'Written by an admin'),
  markingScheme('marking_scheme', 'From the marking scheme');

  const AnswerSource(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// One marking point in the "Add model answer" form.
class PointDraft {
  const PointDraft({this.text = '', this.marks = 1, this.keywords = const []});

  final String text;
  final double marks;
  final List<String> keywords;

  Map<String, dynamic> toJson() => {
    'text': text.trim(),
    'marks': marks,
    'keywords': keywords,
  };
}

/// The body of `POST /admin/model-answers`.
class NewModelAnswer {
  const NewModelAnswer({
    required this.questionId,
    required this.answerText,
    this.source = AnswerSource.admin,
    this.approve = false,
    this.points = const [],
  });

  final String questionId;
  final String answerText;
  final AnswerSource source;

  /// true = `status: approved` (students can practise it right away).
  final bool approve;
  final List<PointDraft> points;

  /// What blocks saving (empty = ready).
  List<String> get problems => [
    if (questionId.isEmpty) 'Pick the question.',
    if (answerText.trim().isEmpty) 'Write the model answer.',
    if (points.any((p) => p.text.trim().isEmpty))
      'Every marking point needs its text.',
    if (points.any((p) => p.marks <= 0 || p.marks > 50))
      'Each point is worth more than 0 and at most 50 marks.',
    if (approve && points.isEmpty)
      'Add at least one marking point before approving.',
  ];

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'answer_text': answerText.trim(),
    'source': source.apiValue,
    'status': approve ? 'approved' : 'draft',
    'points': [for (final p in points) p.toJson()],
  };
}

/// A structured or essay question a model answer can be written for
/// (a row of `GET /admin/questions?type=`).
class WrittenQuestion {
  const WrittenQuestion({
    required this.id,
    required this.code,
    required this.stem,
    required this.type,
  });

  factory WrittenQuestion.fromJson(Map<String, dynamic> json) =>
      WrittenQuestion(
        id: '${json['id']}',
        code: json['code'] as String? ?? '',
        stem: json['stem'] as String? ?? '',
        type: json['type'] as String? ?? 'structured',
      );

  final String id;
  final String code;
  final String stem;

  /// `structured | essay`.
  final String type;
}

/// "a, b ,, c" -> ["a", "b", "c"], no repeats (any case), like the backend.
List<String> splitKeywords(String text) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in text.split(',')) {
    final word = raw.trim().split(RegExp(r'\s+')).join(' ');
    if (word.isNotEmpty && seen.add(word.toLowerCase())) out.add(word);
  }
  return out;
}
