import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/evaluation_models.dart';

/// Evaluation accuracy (admin). Only this layer calls the API.
abstract interface class EvaluationsRepository {
  /// `GET /admin/evaluations/accuracy`
  Future<AccuracyReport> accuracy();

  /// `GET /admin/evaluations?page=&size=&only_manual=`
  Future<EvaluationPage> evaluations(EvaluationQuery query);

  /// `PATCH /admin/evaluations/{id}` with `{manual_marks}`.
  Future<AdminEvaluation> setManualMarks(String id, double marks);
}

class ApiEvaluationsRepository implements EvaluationsRepository {
  ApiEvaluationsRepository(this.api);

  final ApiClient api;

  @override
  Future<AccuracyReport> accuracy() async => AccuracyReport.fromJson(
    await api.get<Map<String, dynamic>>('/admin/evaluations/accuracy'),
  );

  @override
  Future<EvaluationPage> evaluations(EvaluationQuery query) async =>
      EvaluationPage.fromJson(
        await api.get<Map<String, dynamic>>(
          '/admin/evaluations',
          query: query.toQuery(),
        ),
      );

  @override
  Future<AdminEvaluation> setManualMarks(String id, double marks) async =>
      AdminEvaluation.fromJson(
        await api.patch<Map<String, dynamic>>(
          '/admin/evaluations/$id',
          data: {'manual_marks': marks},
        ),
      );
}

/// DEBUG ONLY (`USE_FAKE_API=true`), also used by the tests.
class FakeEvaluationsRepository implements EvaluationsRepository {
  final _rows = <AdminEvaluation>[
    AdminEvaluation(
      id: 'e1',
      question: 'Explain the role of ADH in water reabsorption.',
      answerText: 'ADH makes the collecting duct more permeable to water...',
      estimatedMarks: 6,
      maxMarks: 8,
      manualMarks: 7,
      difference: -1,
      createdAt: DateTime(2026, 10, 6, 9, 30),
    ),
    AdminEvaluation(
      id: 'e2',
      question: 'Describe how linkage affects dihybrid ratios.',
      answerText: 'Linked genes are inherited together so the ratio...',
      estimatedMarks: 9,
      maxMarks: 10,
      manualMarks: 6,
      difference: 3,
      createdAt: DateTime(2026, 10, 5, 14),
    ),
    AdminEvaluation(
      id: 'e3',
      question: 'Outline the light-independent reactions.',
      answerText: 'The Calvin cycle fixes carbon dioxide...',
      estimatedMarks: 5,
      maxMarks: 8,
      createdAt: DateTime(2026, 10, 5, 11),
    ),
  ];

  @override
  Future<AccuracyReport> accuracy() async {
    final marked = _rows.where((r) => r.difference != null).toList();
    if (marked.isEmpty) {
      return const AccuracyReport(note: 'No teacher marks yet.');
    }
    final gaps = [for (final r in marked) r.difference!.abs()];
    return AccuracyReport(
      samples: marked.length,
      meanAbsoluteError: gaps.reduce((a, b) => a + b) / gaps.length,
      withinOneMark: gaps.where((g) => g <= 1).length / gaps.length,
      correlation: 0.82,
      note: 'Based on ${marked.length} answers with teacher marks.',
    );
  }

  @override
  Future<EvaluationPage> evaluations(EvaluationQuery query) async {
    final rows = [
      for (final r in _rows)
        if (!query.onlyManual || r.manualMarks != null) r,
    ];
    return EvaluationPage(items: rows, total: rows.length);
  }

  @override
  Future<AdminEvaluation> setManualMarks(String id, double marks) async {
    final i = _rows.indexWhere((r) => r.id == id);
    if (i < 0) {
      throw const ApiException(
        code: 'EVALUATION_NOT_FOUND',
        message: 'Evaluation not found',
        statusCode: 404,
      );
    }
    final r = _rows[i];
    if (r.maxMarks != null && marks > r.maxMarks!) {
      throw ApiException(
        code: 'MARKS_TOO_HIGH',
        message:
            'This question has only ${r.maxMarks!.toStringAsFixed(0)} marks.',
        statusCode: 422,
      );
    }
    return _rows[i] = AdminEvaluation(
      id: r.id,
      question: r.question,
      answerText: r.answerText,
      estimatedMarks: r.estimatedMarks,
      maxMarks: r.maxMarks,
      manualMarks: marks,
      difference: r.estimatedMarks == null ? null : r.estimatedMarks! - marks,
      createdAt: r.createdAt,
    );
  }
}

final evaluationsRepositoryProvider = Provider<EvaluationsRepository>(
  (ref) => Env.useFakeApi
      ? FakeEvaluationsRepository()
      : ApiEvaluationsRepository(ref.watch(apiClientProvider)),
);
