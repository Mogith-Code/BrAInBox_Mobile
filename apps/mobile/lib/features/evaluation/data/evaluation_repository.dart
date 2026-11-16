import 'package:brainbox_core/brainbox_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/evaluation_models.dart';

/// One photo of a handwritten page, ready to upload.
typedef AnswerPage = ({List<int> bytes, String name, String mimeType});

/// Data layer for the Evaluation feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class EvaluationRepository {
  EvaluationRepository(this.api, this.jobs);

  final ApiClient api;
  final JobPoller jobs;

  /// `GET /evaluations/questions`
  Future<List<WrittenQuestion>> fetchQuestions({
    String? type,
    bool hideOutdated = false,
  }) async {
    final json = await api.get<Map<String, dynamic>>(
      '/evaluations/questions',
      query: {
        'size': 100,
        'question_type': ?type,
        if (hideOutdated) 'hide_outdated': true,
      },
    );
    return [
      for (final item in (json['items'] as List? ?? const []))
        WrittenQuestion.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  /// `GET /questions/{id}` - the question text for the answer screens.
  Future<String> fetchQuestionStem(String questionId) async {
    final json = await api.get<Map<String, dynamic>>('/questions/$questionId');
    return '${json['stem'] ?? json['question'] ?? ''}';
  }

  /// `GET /evaluations/{id}`
  Future<Evaluation> fetchEvaluation(String evaluationId) async {
    final json = await api.get<Map<String, dynamic>>(
      '/evaluations/$evaluationId',
    );
    return Evaluation.fromJson(json);
  }

  /// Sends a typed (or corrected OCR) answer, waits for the marking job and
  /// returns the evaluation id. Throws [ApiException] with the job's
  /// message when marking failed.
  Future<String> evaluate({
    required String questionId,
    required String answerText,
    String? evaluationId,
  }) async {
    final json = await api.post<Map<String, dynamic>>(
      '/evaluations',
      data: {
        'question_id': questionId,
        'answer_text': answerText,
        'evaluation_id': ?evaluationId,
      },
    );
    final started = EvaluationJob.fromJson(json);
    await _waitFor(started.jobId);
    return started.evaluationId;
  }

  /// Uploads the photos, runs OCR and returns the evaluation id whose
  /// `ocrText` the student can now check.
  Future<String> readHandwriting({
    required String questionId,
    required List<AnswerPage> pages,
  }) async {
    final form = FormData();
    for (final page in pages) {
      form.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(
            page.bytes,
            filename: page.name,
            contentType: DioMediaType.parse(page.mimeType),
          ),
        ),
      );
    }
    final uploaded = await api.upload<Map<String, dynamic>>(
      '/evaluations/pages',
      formData: form,
    );
    final json = await api.post<Map<String, dynamic>>(
      '/evaluations/ocr',
      data: {'question_id': questionId, 'image_paths': uploaded['image_paths']},
    );
    final started = EvaluationJob.fromJson(json);
    await _waitFor(started.jobId);
    return started.evaluationId;
  }

  Future<void> _waitFor(String jobId) async {
    final job = await jobs.waitFor(jobId);
    if (job.status != AiJobStatus.succeeded) {
      throw ApiException(
        code: job.errorCode ?? 'job_failed',
        message: job.error ?? 'Something went wrong. Please try again.',
      );
    }
  }
}

final evaluationRepositoryProvider = Provider<EvaluationRepository>(
  (ref) => EvaluationRepository(
    ref.watch(apiClientProvider),
    ref.watch(jobPollerProvider),
  ),
);
