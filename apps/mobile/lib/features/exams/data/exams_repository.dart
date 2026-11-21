import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/exams_models.dart';
import '../domain/paper_models.dart';

/// Data layer for the Exams feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class ExamsRepository {
  ExamsRepository(this.api, this.jobs);

  final ApiClient api;
  final JobPoller jobs;

  /// `GET /papers` - approved past papers, newest year first.
  Future<List<PaperSummary>> listPapers({
    int? year,
    PaperQuestionType? type,
  }) async {
    final json = await api.get<Map<String, dynamic>>(
      '/papers',
      query: {'size': 100, 'year': ?year, 'type': ?type?.api},
    );
    return [
      for (final p in (json['items'] as List? ?? const []))
        PaperSummary.fromJson(p as Map<String, dynamic>),
    ];
  }

  /// `GET /papers/{id}` - questions without answers.
  Future<PaperDetail> fetchPaper(String id, {bool hideOutdated = false}) async {
    final json = await api.get<Map<String, dynamic>>(
      '/papers/$id',
      query: {if (hideOutdated) 'hide_outdated': true},
    );
    return PaperDetail.fromJson(json);
  }

  /// `POST /papers/generate` - 202 with a job id.
  Future<PaperJob> startModelPaper(PaperBlueprint blueprint) async {
    final json = await api.post<Map<String, dynamic>>(
      '/papers/generate',
      data: blueprint.toJson(),
    );
    return PaperJob.fromJson(json);
  }

  /// Polls `GET /jobs/{id}` until the model paper job is done.
  Stream<AiJob> watchJob(String jobId) => jobs.watch(jobId);

  /// `POST /papers/{id}/submit` - MCQ letters and written answers.
  Future<EvalResult> submitPaper({
    required String paperId,
    required List<AnswerItem> answers,
    bool explain = true,
  }) async {
    final response = await api.post<Map<String, dynamic>>(
      '/papers/$paperId/submit',
      data: {
        'answers': answers.map((a) => a.toJson()).toList(),
        'explain': explain,
      },
    );
    return EvalResult.fromJson(response);
  }
}

final examsRepositoryProvider = Provider<ExamsRepository>(
  (ref) => ExamsRepository(
    ref.watch(apiClientProvider),
    ref.watch(jobPollerProvider),
  ),
);
