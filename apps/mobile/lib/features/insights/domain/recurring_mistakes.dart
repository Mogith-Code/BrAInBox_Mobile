/// Models for `GET /mistakes/recurring` (plain classes, no codegen).
library;

/// Compared with the window before: more, fewer or the same hits.
enum MistakeTrend {
  up('up'),
  down('down'),
  same('same');

  const MistakeTrend(this.apiValue);

  final String apiValue;

  /// Unknown values read as [same].
  static MistakeTrend parse(Object? value) => MistakeTrend.values.firstWhere(
    (t) => t.apiValue == value,
    orElse: () => MistakeTrend.same,
  );
}

/// A misconception the student keeps hitting.
class RecurringMistake {
  const RecurringMistake({
    required this.misconceptionId,
    required this.title,
    required this.count,
    required this.previousCount,
    required this.trend,
    this.description,
    this.correction,
    this.lastAt,
    this.conceptId,
    this.concept,
    this.topicId,
    this.topic,
  });

  factory RecurringMistake.fromJson(Map<String, dynamic> json) =>
      RecurringMistake(
        misconceptionId: '${json['misconception_id']}',
        title: '${json['title'] ?? ''}',
        description: json['description'] as String?,
        correction: json['correction'] as String?,
        count: (json['count'] as num?)?.round() ?? 0,
        previousCount: (json['previous_count'] as num?)?.round() ?? 0,
        trend: MistakeTrend.parse(json['trend']),
        lastAt: DateTime.tryParse('${json['last_at'] ?? ''}'),
        conceptId: json['concept_id'] as String?,
        concept: json['concept'] as String?,
        topicId: json['topic_id'] as String?,
        topic: json['topic'] as String?,
      );

  final String misconceptionId;
  final String title;
  final String? description;

  /// How to fix it (markdown from the backend, shown as plain text).
  final String? correction;

  /// Hits in the last [RecurringMistakes.windowDays] days.
  final int count;

  /// Hits in the window before that.
  final int previousCount;
  final MistakeTrend trend;
  final DateTime? lastAt;
  final String? conceptId;
  final String? concept;
  final String? topicId;
  final String? topic;
}

/// Response of `GET /mistakes/recurring`.
class RecurringMistakes {
  const RecurringMistakes({
    this.items = const [],
    this.windowDays = 14,
    this.minCount = 3,
  });

  factory RecurringMistakes.fromJson(Map<String, dynamic> json) =>
      RecurringMistakes(
        items: [
          if (json['items'] is List)
            for (final item in json['items'] as List)
              if (item is Map<String, dynamic>) RecurringMistake.fromJson(item),
        ],
        windowDays: (json['window_days'] as num?)?.round() ?? 14,
        minCount: (json['min_count'] as num?)?.round() ?? 3,
      );

  final List<RecurringMistake> items;
  final int windowDays;
  final int minCount;
}
