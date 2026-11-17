import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recommendations_models.dart';

/// Data layer for the Recommendations feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class RecommendationsRepository {
  RecommendationsRepository(this.api);

  final ApiClient api;

  /// `GET /recommendations`
  Future<NextSteps> fetchNextSteps() async {
    final json = await api.get<Map<String, dynamic>>('/recommendations');
    return NextSteps.fromJson(json);
  }

  /// `PATCH /recommendations/{id}` - `in_progress`, `done` or `dismissed`.
  Future<void> setStatus(String id, String status) =>
      api.patch<dynamic>('/recommendations/$id', data: {'status': status});

  /// `GET /recommendations/{id}/outcome`
  Future<Outcome> fetchOutcome(String id) async {
    final json = await api.get<Map<String, dynamic>>(
      '/recommendations/$id/outcome',
    );
    return Outcome.fromJson(json);
  }

  /// `GET /study-plan`
  Future<StudyPlan> fetchPlan() async {
    final json = await api.get<Map<String, dynamic>>('/study-plan');
    return StudyPlan.fromJson(json);
  }

  /// `POST /study-plan/regenerate`
  Future<StudyPlan> regeneratePlan() async {
    final json = await api.post<Map<String, dynamic>>('/study-plan/regenerate');
    return StudyPlan.fromJson(json);
  }

  /// `PATCH /study-plan/items/{id}`
  Future<void> setItemDone(String itemId, {required bool done}) =>
      api.patch<dynamic>('/study-plan/items/$itemId', data: {'is_done': done});

  /// `PUT /study-plan/order` - the new order of one day's items.
  Future<StudyPlan> reorder(List<String> itemIds) async {
    final json = await api.put<Map<String, dynamic>>(
      '/study-plan/order',
      data: {'item_ids': itemIds},
    );
    return StudyPlan.fromJson(json);
  }
}

final recommendationsRepositoryProvider = Provider<RecommendationsRepository>(
  (ref) => RecommendationsRepository(ref.watch(apiClientProvider)),
);
