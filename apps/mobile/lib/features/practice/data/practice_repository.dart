import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/practice_models.dart';

/// Data layer for the Practice feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class PracticeRepository {
  PracticeRepository(this.api);

  final ApiClient api;

  /// `GET /practice/hub`
  Future<PracticeHub> fetchHub() async {
    final json = await api.get<Map<String, dynamic>>('/practice/hub');
    return PracticeHub.fromJson(json);
  }

  /// `GET /units` - the units to choose from in the quiz setup.
  Future<List<PracticeUnit>> fetchUnits() async {
    final data = await api.get<dynamic>('/units');
    final list = data is Map ? (data['items'] as List? ?? const []) : data;
    return [
      for (final item in list as List)
        PracticeUnit.fromJson(Map<String, dynamic>.from(item as Map)),
    ]..sort((a, b) => a.number.compareTo(b.number));
  }

  /// `POST /quizzes`
  Future<Quiz> startQuiz(QuizSetup setup) async {
    final json = await api.post<Map<String, dynamic>>(
      '/quizzes',
      data: setup.toJson(),
    );
    return Quiz.fromJson(json);
  }

  /// `GET /quizzes/{id}` - resume a quiz.
  Future<Quiz> fetchQuiz(String quizId) async {
    final json = await api.get<Map<String, dynamic>>('/quizzes/$quizId');
    return Quiz.fromJson(json);
  }

  /// `POST /quizzes/{id}/responses` - answer one question, get feedback.
  Future<AnswerFeedback> answer({
    required String quizId,
    required String questionId,
    required String optionId,
    int? timeSpentSeconds,
  }) async {
    final json = await api.post<Map<String, dynamic>>(
      '/quizzes/$quizId/responses',
      data: {
        'question_id': questionId,
        'option_id': optionId,
        'time_spent_seconds': ?timeSpentSeconds,
      },
    );
    return AnswerFeedback.fromJson(json);
  }

  /// `PATCH /quizzes/{id}/questions/{qid}/flag`
  Future<void> flag({
    required String quizId,
    required String questionId,
    required bool flagged,
  }) => api.patch<dynamic>(
    '/quizzes/$quizId/questions/$questionId/flag',
    data: {'flagged': flagged},
  );

  /// `POST /quizzes/{id}/submit`
  Future<QuizResult> submit(String quizId) async {
    final json = await api.post<Map<String, dynamic>>(
      '/quizzes/$quizId/submit',
    );
    return QuizResult.fromJson(json);
  }

  /// `GET /quizzes/{id}/result`
  Future<QuizResult> fetchResult(String quizId) async {
    final json = await api.get<Map<String, dynamic>>('/quizzes/$quizId/result');
    return QuizResult.fromJson(json);
  }

  /// `POST /questions/{id}/report`
  Future<void> reportQuestion(String questionId, String reason) => api
      .post<dynamic>('/questions/$questionId/report', data: {'reason': reason});
}

final practiceRepositoryProvider = Provider<PracticeRepository>(
  (ref) => PracticeRepository(ref.watch(apiClientProvider)),
);
