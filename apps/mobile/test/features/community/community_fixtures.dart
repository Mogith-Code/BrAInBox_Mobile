// Test-only backend responses for the community API (snake_case, like the
// FastAPI schemas). Never used by the app itself.

Map<String, dynamic> groupJson({
  required String id,
  required String name,
  String? slug,
  String? unitId,
  bool isMember = false,
  bool isDefault = false,
  int members = 10,
}) => {
  'id': id,
  'slug': slug,
  'name': name,
  'description': null,
  'unit_id': unitId,
  'is_default': isDefault,
  'is_private': false,
  'member_count': members,
  'is_member': isMember,
  'my_role': isMember ? 'member' : null,
};

Map<String, dynamic> postJson({
  required String id,
  String title = 'Why is the F2 ratio 9:3:3:1?',
  String body = 'I keep getting 3:1.',
  String? topic = 'Mendelian genetics',
  bool isQuestion = true,
  bool isMine = false,
  String status = 'approved',
  int score = 0,
  int myVote = 0,
  int replyCount = 0,
  String? acceptedReplyId,
  String authorName = 'Nimali',
}) => {
  'id': id,
  'group_id': 'g-6',
  'title': title,
  'body': body,
  'tags': <String>[],
  'topic_id': topic == null ? null : 't-6-1',
  'topic': topic,
  'unit_id': 'u-6',
  'is_question': isQuestion,
  'author': {'id': 'a-$id', 'name': authorName},
  'is_mine': isMine,
  'moderation_status': status,
  'score': score,
  'my_vote': myVote,
  'reply_count': replyCount,
  'accepted_reply_id': acceptedReplyId,
  'created_at': '2026-11-16T08:00:00Z',
};

Map<String, dynamic> replyJson({
  required String id,
  String body = 'Think of it as two 3:1 crosses.',
  bool ai = false,
  bool accepted = false,
  bool isMine = false,
  int score = 0,
  int myVote = 0,
  String? authorName = 'Kasun',
}) => {
  'id': id,
  'body': body,
  'author': ai || authorName == null
      ? null
      : {'id': 'a-$id', 'name': authorName},
  'is_mine': isMine,
  'is_ai_suggested': ai,
  'is_accepted': accepted,
  'moderation_status': 'approved',
  'score': score,
  'my_vote': myVote,
  'created_at': '2026-11-16T09:00:00Z',
};

Map<String, dynamic> pageJson(
  List<Map<String, dynamic>> items, {
  int page = 1,
  int pages = 1,
}) => {
  'items': items,
  'total': items.length,
  'page': page,
  'size': 20,
  'pages': pages,
};

/// A question with an AI answer, an accepted answer and two more replies,
/// sent in the backend's order (accepted first, then by score).
Map<String, dynamic> detailJson({bool isMine = false}) => {
  ...postJson(id: 'p1', isMine: isMine, score: 3, replyCount: 4),
  'accepted_reply_id': 'r-accepted',
  'replies': [
    replyJson(
      id: 'r-accepted',
      body: 'Accepted answer',
      accepted: true,
      score: 1,
    ),
    replyJson(id: 'r-high', body: 'High score reply', score: 5),
    replyJson(id: 'r-ai', body: 'AI answer', ai: true, score: 2),
    replyJson(id: 'r-low', body: 'Low score reply', score: -1, isMine: true),
  ],
};

/// `GET /insights/units`: unit 2 is weak (41), unit 6 is strong (88),
/// unit 3 was never measured.
Map<String, dynamic> unitsJson() => {
  'units': [
    _unit('u-2', 2, 41, 'weak'),
    _unit('u-3', 3, null, 'not_attempted'),
    _unit('u-6', 6, 88, 'strong'),
  ],
  'assessed_units': 2,
  'total_units': 3,
  'average_mastery': 64.5,
  'strongest': null,
  'weakest': null,
  'grade_bands': <Object>[],
  'note': '',
};

Map<String, dynamic> _unit(
  String id,
  int number,
  int? mastery,
  String status,
) => {
  'unit_id': id,
  'number': number,
  'title': 'Unit $number',
  'topic_count': 3,
  'mastery': mastery,
  'status': status,
  'understanding': status,
};
