import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The three totals on the sign-in page.
class ConsoleStats {
  const ConsoleStats({
    required this.aiItemsToReview,
    required this.students,
    this.evalAccuracyPercent,
  });

  factory ConsoleStats.fromJson(Map<String, dynamic> json) => ConsoleStats(
    aiItemsToReview: (json['ai_items_to_review'] as num).toInt(),
    students: (json['students'] as num).toInt(),
    evalAccuracyPercent: (json['eval_accuracy_percent'] as num?)?.toDouble(),
  );

  final int aiItemsToReview;

  /// All student accounts that aren't suspended.
  final int students;

  /// Null until there is an evaluation accuracy to report.
  final double? evalAccuracyPercent;
}

/// `GET /public/console-stats` (no login needed).
///
/// Doesn't retry: if it fails, the sign-in page simply shows dashes.
final consoleStatsProvider = FutureProvider.autoDispose<ConsoleStats>(
  (ref) async => ConsoleStats.fromJson(
    await ref
        .watch(apiClientProvider)
        .get<Map<String, dynamic>>('/public/console-stats'),
  ),
  retry: (_, _) => null,
);
