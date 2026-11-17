/// Evaluation accuracy (admin): AI-estimated marks against a teacher's marks.
///
/// Backend: `api/modules/evaluation/schemas.py` (`AccuracyReport`,
/// `AdminEvaluationOut`, `ManualMarksIn`), routes under `/admin/evaluations`.
library;

double? _double(Object? v) => v is num ? v.toDouble() : null;

/// `GET /admin/evaluations/accuracy`: over every answer a teacher marked.
///
/// The numbers are null until at least one answer has teacher marks, so the
/// screen never shows a made-up 0.
class AccuracyReport {
  const AccuracyReport({
    this.samples = 0,
    this.meanAbsoluteError,
    this.withinOneMark,
    this.correlation,
    this.note = '',
  });

  factory AccuracyReport.fromJson(Map<String, dynamic> json) => AccuracyReport(
    samples: (json['samples'] as num?)?.toInt() ?? 0,
    meanAbsoluteError: _double(json['mean_absolute_error']),
    withinOneMark: _double(json['within_one_mark']),
    correlation: _double(json['correlation']),
    note: json['note'] as String? ?? '',
  );

  /// How many answers have both AI and teacher marks.
  final int samples;

  /// Average gap between AI and teacher marks, in marks.
  final double? meanAbsoluteError;

  /// Share (0-1) of answers where the AI was within one mark.
  final double? withinOneMark;

  /// -1..1, how well the AI marks follow the teacher marks.
  final double? correlation;

  /// One sentence from the backend about the numbers.
  final String note;
}

/// One row of `GET /admin/evaluations` (an answer the AI marked).
class AdminEvaluation {
  const AdminEvaluation({
    required this.id,
    required this.question,
    required this.createdAt,
    this.answerText,
    this.estimatedMarks,
    this.maxMarks,
    this.manualMarks,
    this.difference,
  });

  factory AdminEvaluation.fromJson(Map<String, dynamic> json) =>
      AdminEvaluation(
        id: '${json['id']}',
        question: json['question'] as String? ?? '',
        answerText: json['answer_text'] as String?,
        estimatedMarks: _double(json['estimated_marks']),
        maxMarks: _double(json['max_marks']),
        manualMarks: _double(json['manual_marks']),
        difference: _double(json['difference']),
        createdAt:
            DateTime.tryParse('${json['created_at']}')?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  final String id;

  /// The question stem.
  final String question;
  final String? answerText;
  final double? estimatedMarks;
  final double? maxMarks;

  /// The teacher's marks; null = not marked by a teacher yet.
  final double? manualMarks;

  /// estimated - manual (null until both exist).
  final double? difference;
  final DateTime createdAt;

  /// The highest mark a teacher may enter (the backend allows 0-100 when the
  /// question has no maximum).
  double get markLimit => maxMarks ?? 100;
}

/// `Page[AdminEvaluationOut]`.
class EvaluationPage {
  const EvaluationPage({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 1,
  });

  factory EvaluationPage.fromJson(Map<String, dynamic> json) => EvaluationPage(
    items: [
      for (final e in json['items'] as List? ?? const [])
        AdminEvaluation.fromJson(Map<String, dynamic>.from(e as Map)),
    ],
    total: (json['total'] as num?)?.toInt() ?? 0,
    page: (json['page'] as num?)?.toInt() ?? 1,
    pages: (json['pages'] as num?)?.toInt() ?? 1,
  );

  final List<AdminEvaluation> items;
  final int total;
  final int page;
  final int pages;

  EvaluationPage replace(AdminEvaluation row) => EvaluationPage(
    items: [for (final e in items) e.id == row.id ? row : e],
    total: total,
    page: page,
    pages: pages,
  );
}

/// Which evaluations the table lists.
class EvaluationQuery {
  const EvaluationQuery({this.page = 1, this.onlyManual = false});

  static const pageSize = 10;

  final int page;

  /// Only the ones a teacher already marked.
  final bool onlyManual;

  Map<String, dynamic> toQuery() => {
    'page': page,
    'size': pageSize,
    if (onlyManual) 'only_manual': true,
  };

  @override
  bool operator ==(Object other) =>
      other is EvaluationQuery &&
      other.page == page &&
      other.onlyManual == onlyManual;

  @override
  int get hashCode => Object.hash(page, onlyManual);
}

/// How the AI's marks compare with the teacher's, for the Difference column.
enum MarkGap {
  close('Within 1 mark'),
  higher('AI higher'),
  lower('AI lower');

  const MarkGap(this.label);

  final String label;

  /// Null when there is nothing to compare yet.
  static MarkGap? of(double? difference) {
    if (difference == null) return null;
    if (difference.abs() <= 1) return close;
    return difference > 0 ? higher : lower;
  }
}
