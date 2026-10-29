import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dev/fake_backend.dart';
import '../domain/diagnostic_models.dart';
import 'fake_diagnostic_repository.dart';

part 'diagnostic_repository.g.dart';

/// The first-run diagnostic. Only this layer calls the API.
abstract interface class DiagnosticRepository {
  /// `POST /diagnostic/start` - returns the same attempt if one is open.
  /// Throws `NOT_ENOUGH_QUESTIONS` when the bank is too small.
  Future<DiagnosticAttempt> start();

  /// `POST /diagnostic/{attempt_id}/answer`
  Future<AnswerSaved> answer({
    required String attemptId,
    required String questionId,
    required String optionId,
  });

  /// `POST /diagnostic/{attempt_id}/submit`
  Future<DiagnosticResult> submit(String attemptId);

  /// `POST /diagnostic/skip`
  Future<void> skip();

  /// `GET /diagnostic/result` (`DIAGNOSTIC_NOT_FOUND` if none yet).
  Future<DiagnosticResult> result();
}

class ApiDiagnosticRepository implements DiagnosticRepository {
  ApiDiagnosticRepository(this.api);

  final ApiClient api;

  @override
  Future<DiagnosticAttempt> start() async => DiagnosticAttempt.fromJson(
    await api.post<Map<String, dynamic>>('/diagnostic/start'),
  );

  @override
  Future<AnswerSaved> answer({
    required String attemptId,
    required String questionId,
    required String optionId,
  }) async => AnswerSaved.fromJson(
    await api.post<Map<String, dynamic>>(
      '/diagnostic/$attemptId/answer',
      data: {'question_id': questionId, 'option_id': optionId},
    ),
  );

  @override
  Future<DiagnosticResult> submit(String attemptId) async =>
      DiagnosticResult.fromJson(
        await api.post<Map<String, dynamic>>('/diagnostic/$attemptId/submit'),
      );

  @override
  Future<void> skip() => api.post<dynamic>('/diagnostic/skip');

  @override
  Future<DiagnosticResult> result() async => DiagnosticResult.fromJson(
    await api.get<Map<String, dynamic>>('/diagnostic/result'),
  );
}

@Riverpod(keepAlive: true)
DiagnosticRepository diagnosticRepository(Ref ref) => Env.useFakeApi
    ? FakeDiagnosticRepository(ref.watch(fakeBackendProvider))
    : ApiDiagnosticRepository(ref.watch(apiClientProvider));
