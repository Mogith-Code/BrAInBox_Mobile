import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import 'heatmap_screen.dart';
import 'topic_insight_screen.dart';

/// Navigation for the Insights feature.
///
// TODO(keshomigha): ask Samni to add `AppRoutes.insightsTopic`
// ('/insights/topics/:topicKey') and `AppRoutes.insightsAttempt`
// ('/insights/attempts/:attemptId'), then replace the Navigator pushes and
// the `attempt_id` query below with them.
abstract final class InsightsNav {
  static const _attemptParam = 'attempt_id';

  /// Location for the single-attempt overview, for the practice and exam
  /// result screens: `context.push(InsightsNav.attemptLocation(id))`.
  static String attemptLocation(String attemptId) => Uri(
    path: AppRoutes.insights,
    queryParameters: {_attemptParam: attemptId},
  ).toString();

  /// The `attempt_id` of the current route, if any.
  static String? attemptIdFromRoute(BuildContext context) {
    if (GoRouter.maybeOf(context) == null) return null;
    final id = GoRouterState.of(context).uri.queryParameters[_attemptParam];
    return (id == null || id.isEmpty) ? null : id;
  }

  /// Opens the Topic detail page.
  static Future<void> openTopic(
    BuildContext context, {
    required String topicKey,
    String? attemptId,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          TopicInsightScreen(topicKey: topicKey, attemptId: attemptId),
    ),
  );

  /// Opens the mastery map (heatmap).
  static Future<void> openHeatmap(BuildContext context, {String? attemptId}) {
    if (attemptId == null && GoRouter.maybeOf(context) != null) {
      return context.push(AppRoutes.heatmap);
    }
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HeatmapScreen(attemptId: attemptId),
      ),
    );
  }

  /// Goes to the Practice tab.
  static void goToPractice(BuildContext context) =>
      GoRouter.maybeOf(context)?.go(AppRoutes.practice);

  /// Goes to profile setup (backend says the user is not registered).
  static void goToProfileSetup(BuildContext context) =>
      GoRouter.maybeOf(context)?.go(AppRoutes.profileSetup);

  /// Back to the previous screen, or to the Insights tab.
  static void back(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      GoRouter.maybeOf(context)?.go(AppRoutes.insights);
    }
  }
}
