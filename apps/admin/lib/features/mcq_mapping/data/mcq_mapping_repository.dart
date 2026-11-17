import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/mcq_mapping_models.dart';

/// AI misconception suggestions + confirming one option (admin). Loading
/// and saving the question goes through the question bank's repository.
abstract interface class McqMappingRepository {
  /// `POST /admin/questions/{id}/misconception-suggestions` (202 + job),
  /// waits for the MAP_MISCONCEPTIONS job and returns `result.suggestions`.
  Future<List<MisconceptionSuggestion>> suggest(String questionId);

  /// `PUT /admin/options/{option_id}/misconception` with `{misconception}`.
  Future<SavedOptionMisconception> confirm(
    String optionId,
    String misconception,
  );
}

class ApiMcqMappingRepository implements McqMappingRepository {
  ApiMcqMappingRepository(this.api, this.jobs);

  final ApiClient api;
  final JobPoller jobs;

  @override
  Future<List<MisconceptionSuggestion>> suggest(String questionId) async {
    final started = await api.post<Map<String, dynamic>>(
      '/admin/questions/$questionId/misconception-suggestions',
    );
    final job = await jobs.waitFor('${started['job_id']}');
    if (job.status != AiJobStatus.succeeded) {
      throw ApiException(
        code: job.errorCode ?? 'job_failed',
        message: job.error ?? 'The AI could not suggest misconceptions.',
      );
    }
    return [
      for (final e in job.result?['suggestions'] as List? ?? const [])
        MisconceptionSuggestion.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
  }

  @override
  Future<SavedOptionMisconception> confirm(
    String optionId,
    String misconception,
  ) async => SavedOptionMisconception.fromJson(
    await api.put<Map<String, dynamic>>(
      '/admin/options/$optionId/misconception',
      data: {'misconception': misconception},
    ),
  );
}

/// DEBUG ONLY (`USE_FAKE_API=true`), also used by the tests. Suggestions
/// for the fake question bank's Q-4822 (labels A, B, D, E are wrong).
class FakeMcqMappingRepository implements McqMappingRepository {
  final confirmed = <(String, String)>[];

  @override
  Future<List<MisconceptionSuggestion>> suggest(String questionId) async => [
    const MisconceptionSuggestion(
      optionId: 'opt-a',
      label: 'A',
      optionText: '9 : 3 : 3 : 1',
      current: 'Assumes independent assortment for linked genes',
      suggested: 'Assumes independent assortment for linked genes',
      misconceptionId: 'm1',
      isNew: false,
      similarity: 0.97,
    ),
    const MisconceptionSuggestion(
      optionId: 'opt-b',
      label: 'B',
      optionText: '1 : 1 : 1 : 1',
      current: 'Assumes independent assortment for linked genes',
      suggested: 'Treats a test cross of linked genes like unlinked genes',
    ),
    const MisconceptionSuggestion(
      optionId: 'opt-e',
      label: 'E',
      optionText: 'Only parental types — no recombinants',
      current: 'Forgets recombinants are the minority',
      suggested: 'Thinks linked genes never cross over',
      misconceptionId: 'm7',
      isNew: false,
      similarity: 0.88,
    ),
  ];

  @override
  Future<SavedOptionMisconception> confirm(
    String optionId,
    String misconception,
  ) async {
    confirmed.add((optionId, misconception));
    return SavedOptionMisconception(
      label: optionId.substring(optionId.length - 1).toUpperCase(),
      misconception: misconception,
    );
  }
}

final mcqMappingRepositoryProvider = Provider<McqMappingRepository>(
  (ref) => Env.useFakeApi
      ? FakeMcqMappingRepository()
      : ApiMcqMappingRepository(
          ref.watch(apiClientProvider),
          ref.watch(jobPollerProvider),
        ),
);
