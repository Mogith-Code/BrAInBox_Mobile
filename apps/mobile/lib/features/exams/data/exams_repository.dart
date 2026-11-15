import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/exams_models.dart';

part 'exams_repository.g.dart';

/// Data layer for the Exams feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class ExamsRepository {
  ExamsRepository(this.api);

  final ApiClient api;

  /// Loads the overview / status for the Exams feature.
  Future<ExamsSummary> fetchSummary() async {
    try {
      final json = await api.get<Map<String, dynamic>>('/exams/status');
      return ExamsSummary(
        title: 'A/L Biology Model Papers',
        message: 'Module: ${json['module'] ?? 'exams'} (${json['status'] ?? 'ready'})',
      );
    } catch (_) {
      return const ExamsSummary(
        title: 'A/L Biology Model Papers',
        message: 'Generate customized practice papers from curriculum units.',
      );
    }
  }

  /// Generates an AI model paper by selecting 1..10 syllabus units.
  Future<ExamPaper> generatePaperByUnits({
    required List<int> units,
    required int count,
    String? title,
  }) async {
    final response = await api.post<Map<String, dynamic>>(
      '/papers/generate-by-units',
      data: {
        'subject': 'Biology',
        'units': units,
        'unit_numbers': units,
        'num_questions': count,
        if (title != null && title.isNotEmpty) 'title': title,
      },
    );
    return ExamPaper.fromJson(response);
  }

  /// Generates an AI model paper by selecting specific syllabus topic IDs.
  Future<ExamPaper> generatePaperByTopics({
    required List<String> topicIds,
    required int count,
    String? title,
  }) async {
    final response = await api.post<Map<String, dynamic>>(
      '/papers/generate',
      data: {
        'topic_ids': topicIds,
        'num_questions': count,
        if (title != null && title.isNotEmpty) 'title': title,
      },
    );
    return ExamPaper.fromJson(response);
  }

  /// Submits student answers for evaluation and AI explanations.
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

@riverpod
ExamsRepository examsRepository(Ref ref) =>
    ExamsRepository(ref.watch(apiClientProvider));
