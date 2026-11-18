// Test-only sample responses for `GET /insights/topics`.
// Never used by the app itself.

/// A full response: weakest topic first, a "General" group (null topic id),
/// a topic without enough data, one never attempted, and an unknown status.
Map<String, dynamic> sampleInsightsJson() => {
  'attempt_id': null,
  'attempts_analysed': 3,
  'min_questions_per_topic': 5,
  'overall': {
    'correct': 21,
    'attempted': 34,
    'unanswered': 2,
    'excluded': 0,
    'percent': 61.76,
    'grade': 'C',
    'grade_label': 'Credit Pass',
  },
  'topics': [
    _topic(
      id: 't-dihybrid',
      name: 'Dihybrid crosses',
      number: '6.2',
      unit: 'Genetics',
      correct: 2,
      attempted: 9,
      unanswered: 1,
      percent: 22.22,
      grade: 'F',
      gradeLabel: 'Fail',
      status: 'very_weak',
    ),
    _topic(
      id: 't-photo',
      name: 'Photosynthesis',
      number: '3.1',
      unit: 'Plant biology',
      correct: 4,
      attempted: 8,
      percent: 50,
      grade: 'S',
      gradeLabel: 'Ordinary/Simple Pass',
      status: 'weak',
    ),
    _topic(
      id: 't-sex',
      name: 'Sex linkage',
      number: '6.4',
      unit: 'Genetics',
      correct: 1,
      attempted: 2,
      percent: 50,
      grade: 'S',
      gradeLabel: 'Ordinary/Simple Pass',
      status: 'insufficient_data',
      reliable: false,
    ),
    _topic(
      id: null,
      name: 'General',
      unit: null,
      correct: 3,
      attempted: 5,
      percent: 60,
      grade: 'C',
      gradeLabel: 'Credit Pass',
      status: 'developing',
    ),
    _topic(
      id: 't-new',
      name: 'Gene technology',
      number: '7.1',
      unit: 'Genetics',
      correct: 4,
      attempted: 6,
      percent: 66.67,
      grade: 'B',
      gradeLabel: 'Very Good Pass',
      status: 'brand_new_status',
    ),
    _topic(
      id: 't-enzymes',
      name: 'Enzymes',
      number: '2.3',
      unit: 'Cell biology',
      correct: 7,
      attempted: 8,
      percent: 87.5,
      grade: 'A',
      gradeLabel: 'Distinction Pass',
      status: 'strong',
    ),
    _topic(
      id: 't-cell',
      name: 'Cell structure',
      number: '1.1',
      unit: 'Cell biology',
      correct: 0,
      attempted: 0,
      percent: null,
      grade: null,
      gradeLabel: null,
      status: 'not_attempted',
      reliable: false,
    ),
  ],
  'weak_topics': ['Dihybrid crosses', 'Photosynthesis'],
  'insufficient_data_topics': ['Sex linkage'],
  'feedback': [
    {
      'topic_id': 't-dihybrid',
      'topic': 'Dihybrid crosses',
      'correct': 2,
      'attempted': 9,
      'percent': 22.22,
      'grade': 'F',
      'status': 'very_weak',
      'summary': 'You are mixing up the 9:3:3:1 ratio.',
      'action': 'Revise independent assortment, then retry 5 questions.',
      'review_questions': [
        {
          'question_id': 'q1',
          'question': 'What ratio does a dihybrid cross give?',
          'model_answer': '9:3:3:1 in the F2 generation.',
        },
        {
          'question_id': 'q2',
          'question': 'Which law explains it?',
          'model_answer': null,
        },
      ],
      'misconceptions': [
        {
          'id': 'm1',
          'title': 'Linked genes assort independently',
          'description': 'Only genes on different chromosomes do.',
        },
      ],
      'resources': [
        {
          'id': 'r1',
          'title': 'Dihybrid crosses explained',
          'url': 'https://example.org/dihybrid',
          'resource_type': 'video',
        },
        {
          'id': 'r2',
          'title': 'Genetics podcast',
          'url': 'https://example.org/podcast',
          'resource_type': 'podcast',
        },
      ],
    },
    {
      'topic_id': null,
      'topic': 'General',
      'correct': 3,
      'attempted': 5,
      'percent': 60,
      'grade': 'C',
      'status': 'developing',
      'summary': 'General questions are going fine.',
      'action': '',
      'review_questions': [],
      'misconceptions': [],
      'resources': [],
    },
  ],
  'grade_bands': [
    {
      'grade': 'A',
      'label': 'Distinction Pass',
      'min_percent': 75.0,
      'max_percent': null,
    },
    {
      'grade': 'B',
      'label': 'Very Good Pass',
      'min_percent': 65.0,
      'max_percent': 75.0,
    },
    {
      'grade': 'C',
      'label': 'Credit Pass',
      'min_percent': 55.0,
      'max_percent': 65.0,
    },
    {
      'grade': 'S',
      'label': 'Ordinary/Simple Pass',
      'min_percent': 35.0,
      'max_percent': 55.0,
    },
    {'grade': 'F', 'label': 'Fail', 'min_percent': 0.0, 'max_percent': 35.0},
  ],
  'note':
      'Grades use project-configured A/L-style thresholds; '
      'not official examination grades.',
};

/// A student with no finished answers yet.
Map<String, dynamic> emptyInsightsJson() => {
  'attempt_id': null,
  'attempts_analysed': 0,
  'min_questions_per_topic': 5,
  'overall': {
    'correct': 0,
    'attempted': 0,
    'unanswered': 0,
    'excluded': 0,
    'percent': null,
    'grade': null,
    'grade_label': null,
  },
  'topics': [],
  'weak_topics': [],
  'insufficient_data_topics': [],
  'feedback': [],
  'grade_bands': [],
  'note': 'Not official examination grades.',
};

/// Only topics without enough answers.
Map<String, dynamic> insufficientOnlyJson() => {
  ...emptyInsightsJson(),
  'attempts_analysed': 1,
  'overall': {
    'correct': 1,
    'attempted': 2,
    'unanswered': 0,
    'excluded': 0,
    'percent': 50.0,
    'grade': 'S',
    'grade_label': 'Ordinary/Simple Pass',
  },
  'topics': [
    _topic(
      id: 't-sex',
      name: 'Sex linkage',
      number: '6.4',
      unit: 'Genetics',
      correct: 1,
      attempted: 2,
      percent: 50,
      grade: 'S',
      gradeLabel: 'Ordinary/Simple Pass',
      status: 'insufficient_data',
      reliable: false,
    ),
  ],
  'insufficient_data_topics': ['Sex linkage'],
};

Map<String, dynamic> _topic({
  required String? id,
  required String name,
  String? number,
  required String? unit,
  required int correct,
  required int attempted,
  int unanswered = 0,
  required num? percent,
  required String? grade,
  required String? gradeLabel,
  required String status,
  bool reliable = true,
}) => {
  'topic_id': id,
  'topic': name,
  'topic_number': number,
  'unit': unit,
  'correct': correct,
  'attempted': attempted,
  'unanswered': unanswered,
  'percent': percent,
  'grade': grade,
  'grade_label': gradeLabel,
  'status': status,
  'understanding': status,
  'reliable': reliable,
};

/// A `GET /insights/units` response: two assessed units and one never
/// measured (mastery null, status not_attempted).
Map<String, dynamic> sampleUnitsJson() => {
  'units': [
    _unit(1, 'Introduction to Biology', 88, 'strong', changeWeek: 4),
    _unit(2, 'Chemical & Cellular Basis of Life', 41, 'weak'),
    _unit(3, 'Evolution & Diversity of Organisms', null, 'not_attempted'),
  ],
  'assessed_units': 2,
  'total_units': 3,
  'average_mastery': 64.5,
  'strongest': {
    'unit_id': 'u-1',
    'number': 1,
    'title': 'Introduction to Biology',
    'mastery': 88,
  },
  'weakest': {
    'unit_id': 'u-2',
    'number': 2,
    'title': 'Chemical & Cellular Basis of Life',
    'mastery': 41,
  },
  'grade_bands': <Object>[],
  'note': 'Practice indicator, not an official exam grade.',
};

/// A new student: no unit measured yet.
Map<String, dynamic> unassessedUnitsJson() => {
  'units': [_unit(1, 'Introduction to Biology', null, 'not_attempted')],
  'assessed_units': 0,
  'total_units': 1,
  'average_mastery': null,
  'strongest': null,
  'weakest': null,
  'grade_bands': <Object>[],
  'note': '',
};

Map<String, dynamic> _unit(
  int number,
  String title,
  int? mastery,
  String status, {
  int? changeWeek,
}) => {
  'unit_id': 'u-$number',
  'number': number,
  'title': title,
  'topic_count': 4,
  'mastery': mastery,
  'grade': null,
  'grade_label': null,
  'status': status,
  'understanding': status,
  'change_week': changeWeek,
  'source': mastery == null ? null : 'quiz',
  'measured_at': mastery == null ? null : '2026-11-10T08:00:00Z',
};

/// A `GET /insights/overview` response: 2 h 5 min this week, accuracy on
/// three days (one day without valid answers has `accuracy: null`).
Map<String, dynamic> sampleOverviewJson() => {
  'overall_mastery': 58,
  'mastery_change_week': 4,
  'streak_days': 3,
  'study_minutes_week': 125,
  'study_time': [
    for (final (day, minutes) in [
      (11, 20),
      (12, 0),
      (13, 35),
      (14, 0),
      (15, 30),
      (16, 15),
      (17, 25),
    ])
      {'date': '2026-11-$day', 'minutes': minutes},
  ],
  'accuracy_trend': [
    {'date': '2026-11-05', 'answered': 10, 'accuracy': 40},
    {'date': '2026-11-09', 'answered': 2, 'accuracy': null},
    {'date': '2026-11-13', 'answered': 12, 'accuracy': 58},
    {'date': '2026-11-17', 'answered': 8, 'accuracy': 75},
  ],
  'mastery_history': [
    {'date': '2026-11-17', 'mastery': 58},
  ],
};

/// A new student: no study time, no answers.
Map<String, dynamic> emptyOverviewJson() => {
  'overall_mastery': null,
  'mastery_change_week': null,
  'streak_days': 0,
  'study_minutes_week': 0,
  'study_time': [
    for (var day = 11; day <= 17; day++) {'date': '2026-11-$day', 'minutes': 0},
  ],
  'accuracy_trend': <Object>[],
  'mastery_history': <Object>[],
};

/// A `GET /insights/heatmap` response: two units, one topic not practised.
Map<String, dynamic> sampleHeatmapJson() => {
  'units': [
    {
      'unit_id': 'u-1',
      'number': 1,
      'title': 'Introduction to Biology',
      'topics': [
        _heatTopic('t-1-1', '1.1', 'Nature of biology', 82, 'mastered'),
        _heatTopic('t-1-2', '1.2', 'Life processes', null, 'not_started'),
      ],
    },
    {
      'unit_id': 'u-6',
      'number': 6,
      'title': 'Genetics',
      'topics': [
        _heatTopic('t-6-2', '6.2', 'Deviations from Mendel', 23, 'weak'),
        _heatTopic('t-6-3', '6.3', 'Linkage', 47, 'improving'),
      ],
    },
  ],
};

Map<String, dynamic> _heatTopic(
  String id,
  String number,
  String title,
  int? mastery,
  String level,
) => {
  'topic_id': id,
  'code': null,
  'number': number,
  'title': title,
  'mastery': mastery,
  'level': level,
  'concepts_practised': mastery == null ? 0 : 2,
  'concepts_total': 4,
};
