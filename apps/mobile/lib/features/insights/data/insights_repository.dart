import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/insights_models.dart';
import '../domain/insights_summary.dart';

part 'insights_repository.g.dart';

/// Why loading insights failed. The screens show a different state for each.
sealed class InsightsFailure implements Exception {
  const InsightsFailure(this.message);

  /// Safe to show to the student.
  final String message;

  @override
  String toString() => message;
}

/// 401 `USER_NOT_REGISTERED`: signed in to Firebase but no backend profile.
final class InsightsNotRegistered extends InsightsFailure {
  const InsightsNotRegistered()
    : super('Finish setting up your profile to see your results.');
}

/// 403 / 404: the attempt belongs to someone else or does not exist.
final class InsightsUnavailable extends InsightsFailure {
  const InsightsUnavailable() : super("This result isn't available.");
}

/// 404 on an endpoint the backend has not shipped yet (e.g.
/// `/insights/summary`). The card shows "Coming soon".
final class InsightsNotAvailableYet extends InsightsFailure {
  const InsightsNotAvailableYet() : super('Coming soon');
}

/// No connection or a timeout.
final class InsightsOffline extends InsightsFailure {
  const InsightsOffline(super.message);
}

/// 422, 5xx and anything else.
final class InsightsServerError extends InsightsFailure {
  const InsightsServerError(super.message);
}

/// Data layer for the Insights feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class InsightsRepository {
  InsightsRepository(this.api);

  final ApiClient api;

  static const _genericMessage = 'Something went wrong. Please try again.';

  /// `GET /insights/topics`: per-topic results for all finished attempts, or
  /// only for [attemptId] when it is given.
  ///
  /// Throws an [InsightsFailure].
  Future<TopicInsights> fetchTopicInsights({String? attemptId}) async {
    try {
      final json = await api.get<Map<String, dynamic>>(
        '/insights/topics',
        query: attemptId == null ? null : {'attempt_id': attemptId},
      );
      return TopicInsights.fromJson(json);
    } on ApiException catch (e) {
      throw _mapError(e, attemptId);
    }
  }

  /// `GET /insights/summary?period=`: mastery ring, study time, accuracy
  /// trend and unit mastery for [period].
  ///
  /// Throws an [InsightsFailure]; a 404 is [InsightsNotAvailableYet].
  Future<InsightsSummary> fetchSummary({required InsightsPeriod period}) async {
    try {
      final json = await api.get<Map<String, dynamic>>(
        '/insights/summary',
        query: {'period': period.apiValue},
      );
      return InsightsSummary.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) throw const InsightsNotAvailableYet();
      throw _mapError(e, null);
    }
  }

  InsightsFailure _mapError(ApiException e, String? attemptId) {
    final status = e.statusCode;
    if (status == 401 && e.code == 'USER_NOT_REGISTERED') {
      return const InsightsNotRegistered();
    }
    if (status == 403 || status == 404) return const InsightsUnavailable();
    if (status == 422) {
      // The app built a bad request (e.g. a malformed attempt id): a bug.
      debugPrint(
        'BUG insights: 422 for attempt_id=$attemptId '
        '(${e.code}: ${e.message})',
      );
      return const InsightsServerError(_genericMessage);
    }
    if (e.code == 'network' || e.code == 'timeout') {
      return InsightsOffline(e.message);
    }
    return InsightsServerError(status == null ? _genericMessage : e.message);
  }

  // TODO(keshomigha): needs GET /mistakes for the mistake journal (backend
  // not built yet).
}

@riverpod
InsightsRepository insightsRepository(Ref ref) =>
    InsightsRepository(ref.watch(apiClientProvider));
