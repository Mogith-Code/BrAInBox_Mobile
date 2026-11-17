/// Models of the Community feature, matching the backend's `/groups`,
/// `/posts`, `/replies` and `/votes` responses (`api/modules/community`).
library;

int _int(Object? value) => value is num ? value.round() : 0;
double _double(Object? value) => value is num ? value.toDouble() : 0;
String? _string(Object? value) => value == null ? null : '$value';
DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse('$value')?.toLocal();

/// Moderation state of a post or reply. The author also sees their own
/// `pending` / `flagged` content; everyone else only sees `approved`.
enum ModerationStatus {
  pending,
  approved,
  flagged,
  removed;

  static ModerationStatus parse(Object? value) => ModerationStatus.values
      .firstWhere((s) => s.name == value, orElse: () => approved);
}

/// A study group as the signed-in student sees it (`StudyGroupOut`).
class StudyGroup {
  const StudyGroup({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.unitId,
    this.isDefault = false,
    this.isPrivate = false,
    this.memberCount = 0,
    this.isMember = false,
    this.myRole,
  });

  factory StudyGroup.fromJson(Map<String, dynamic> json) => StudyGroup(
    id: '${json['id']}',
    name: '${json['name'] ?? ''}',
    slug: _string(json['slug']),
    description: _string(json['description']),
    unitId: _string(json['unit_id']),
    isDefault: json['is_default'] == true,
    isPrivate: json['is_private'] == true,
    memberCount: _int(json['member_count']),
    isMember: json['is_member'] == true,
    myRole: _string(json['my_role']),
  );

  final String id;
  final String name;

  /// "general", "unit-6"...
  final String? slug;
  final String? description;

  /// Null for groups not tied to a unit (e.g. General).
  final String? unitId;

  /// The "General" group.
  final bool isDefault;
  final bool isPrivate;
  final int memberCount;
  final bool isMember;
  final String? myRole;

  /// 6 for the "unit-6" group, null otherwise.
  int? get unitNumber {
    final match = RegExp(r'^unit-(\d+)$').firstMatch(slug ?? '');
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  StudyGroup copyWith({bool? isMember, int? memberCount}) => StudyGroup(
    id: id,
    name: name,
    slug: slug,
    description: description,
    unitId: unitId,
    isDefault: isDefault,
    isPrivate: isPrivate,
    memberCount: memberCount ?? this.memberCount,
    isMember: isMember ?? this.isMember,
    myRole: myRole,
  );
}

/// The author of a post or reply. Only the display name is sent, never an
/// email address.
class Author {
  const Author({required this.id, required this.name});

  factory Author.fromJson(Map<String, dynamic> json) =>
      Author(id: '${json['id']}', name: '${json['name'] ?? 'Student'}');

  final String id;
  final String name;
}

Author? _author(Object? value) =>
    value is Map ? Author.fromJson(Map<String, dynamic>.from(value)) : null;

/// A post in a group feed (`PostOut`, no replies).
class Post {
  const Post({
    required this.id,
    required this.title,
    required this.body,
    this.groupId,
    this.tags = const [],
    this.topicId,
    this.topic,
    this.unitId,
    this.isQuestion = true,
    this.author,
    this.isMine = false,
    this.moderationStatus = ModerationStatus.approved,
    this.score = 0,
    this.myVote = 0,
    this.replyCount = 0,
    this.acceptedReplyId,
    this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: '${json['id']}',
    title: '${json['title'] ?? ''}',
    body: '${json['body'] ?? ''}',
    groupId: _string(json['group_id']),
    tags: [for (final tag in (json['tags'] as List? ?? const [])) '$tag'],
    topicId: _string(json['topic_id']),
    topic: _string(json['topic']),
    unitId: _string(json['unit_id']),
    isQuestion: json['is_question'] != false,
    author: _author(json['author']),
    isMine: json['is_mine'] == true,
    moderationStatus: ModerationStatus.parse(json['moderation_status']),
    score: _int(json['score']),
    myVote: _int(json['my_vote']),
    replyCount: _int(json['reply_count']),
    acceptedReplyId: _string(json['accepted_reply_id']),
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String title;
  final String body;
  final String? groupId;
  final List<String> tags;
  final String? topicId;

  /// The topic's title, shown as the topic tag.
  final String? topic;
  final String? unitId;
  final bool isQuestion;

  /// Null when the author deleted their account.
  final Author? author;
  final bool isMine;
  final ModerationStatus moderationStatus;
  final int score;

  /// My vote: 1, -1 or 0 (none).
  final int myVote;
  final int replyCount;
  final String? acceptedReplyId;
  final DateTime? createdAt;

  Post copyWith({int? score, int? myVote}) => Post(
    id: id,
    title: title,
    body: body,
    groupId: groupId,
    tags: tags,
    topicId: topicId,
    topic: topic,
    unitId: unitId,
    isQuestion: isQuestion,
    author: author,
    isMine: isMine,
    moderationStatus: moderationStatus,
    score: score ?? this.score,
    myVote: myVote ?? this.myVote,
    replyCount: replyCount,
    acceptedReplyId: acceptedReplyId,
    createdAt: createdAt,
  );
}

/// A reply to a post (`ReplyOut`).
class Reply {
  const Reply({
    required this.id,
    required this.body,
    this.author,
    this.isMine = false,
    this.isAiSuggested = false,
    this.isAccepted = false,
    this.moderationStatus = ModerationStatus.approved,
    this.score = 0,
    this.myVote = 0,
    this.createdAt,
  });

  factory Reply.fromJson(Map<String, dynamic> json) => Reply(
    id: '${json['id']}',
    body: '${json['body'] ?? ''}',
    author: _author(json['author']),
    isMine: json['is_mine'] == true,
    isAiSuggested: json['is_ai_suggested'] == true,
    isAccepted: json['is_accepted'] == true,
    moderationStatus: ModerationStatus.parse(json['moderation_status']),
    score: _int(json['score']),
    myVote: _int(json['my_vote']),
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String body;

  /// Null for an AI-suggested answer or a deleted account.
  final Author? author;
  final bool isMine;
  final bool isAiSuggested;
  final bool isAccepted;
  final ModerationStatus moderationStatus;
  final int score;
  final int myVote;
  final DateTime? createdAt;

  Reply copyWith({int? score, int? myVote}) => Reply(
    id: id,
    body: body,
    author: author,
    isMine: isMine,
    isAiSuggested: isAiSuggested,
    isAccepted: isAccepted,
    moderationStatus: moderationStatus,
    score: score ?? this.score,
    myVote: myVote ?? this.myVote,
    createdAt: createdAt,
  );
}

/// One post with its replies (`PostDetailOut`).
class PostDetail {
  const PostDetail({required this.post, this.replies = const []});

  factory PostDetail.fromJson(Map<String, dynamic> json) => PostDetail(
    post: Post.fromJson(json),
    replies: [
      for (final reply in (json['replies'] as List? ?? const []))
        Reply.fromJson(Map<String, dynamic>.from(reply as Map)),
    ],
  );

  final Post post;
  final List<Reply> replies;

  /// The order the post page shows: the AI-suggested answer first, then the
  /// accepted answer, then the rest by score (highest first).
  List<Reply> get orderedReplies {
    final ai = [
      for (final r in replies)
        if (r.isAiSuggested) r,
    ];
    final accepted = [
      for (final r in replies)
        if (!r.isAiSuggested && r.isAccepted) r,
    ];
    final rest = [
      for (final r in replies)
        if (!r.isAiSuggested && !r.isAccepted) r,
    ];
    // Stable: equal scores keep the backend's order.
    final indexed = rest.asMap().entries.toList()
      ..sort((a, b) {
        final byScore = b.value.score.compareTo(a.value.score);
        return byScore != 0 ? byScore : a.key.compareTo(b.key);
      });
    return [...ai, ...accepted, for (final e in indexed) e.value];
  }

  PostDetail copyWith({Post? post, List<Reply>? replies}) =>
      PostDetail(post: post ?? this.post, replies: replies ?? this.replies);
}

/// One page of a feed (`Page[PostOut]`).
class PostPage {
  const PostPage({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 0,
  });

  factory PostPage.fromJson(Map<String, dynamic> json) => PostPage(
    items: [
      for (final item in (json['items'] as List? ?? const []))
        Post.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
    total: _int(json['total']),
    page: _int(json['page']),
    pages: _int(json['pages']),
  );

  final List<Post> items;
  final int total;
  final int page;
  final int pages;

  bool get hasMore => page < pages;
}

/// The result of `POST /votes`.
class VoteResult {
  const VoteResult({required this.myVote, required this.score});

  factory VoteResult.fromJson(Map<String, dynamic> json) =>
      VoteResult(myVote: _int(json['my_vote']), score: _int(json['score']));

  final int myVote;
  final int score;
}

/// The AI-suggested topic tag for a draft post
/// (`POST /posts/suggest-topic`).
class TopicSuggestion {
  const TopicSuggestion({
    this.topicId,
    this.topic,
    this.unitNumber,
    this.confidence = 0,
    this.aiGenerated = true,
  });

  factory TopicSuggestion.fromJson(Map<String, dynamic> json) =>
      TopicSuggestion(
        topicId: _string(json['topic_id']),
        topic: _string(json['topic']),
        unitNumber: json['unit_number'] == null
            ? null
            : _int(json['unit_number']),
        confidence: _double(json['confidence']),
        aiGenerated: json['ai_generated'] != false,
      );

  /// Null when no topic fits.
  final String? topicId;
  final String? topic;
  final int? unitNumber;
  final double confidence;
  final bool aiGenerated;
}

/// A topic of a unit, to pick a different topic tag
/// (`GET /units/{u6}/topics`, camelCase keys).
class TopicOption {
  const TopicOption({
    required this.id,
    required this.code,
    required this.title,
  });

  factory TopicOption.fromJson(Map<String, dynamic> json) => TopicOption(
    // The backend's `uuid` is what `topic_id` expects; `id` is "bio-6.1".
    id: '${json['uuid']}',
    code: '${json['code'] ?? ''}',
    title: '${json['title'] ?? ''}',
  );

  final String id;
  final String code;
  final String title;
}

/// Why a post or reply is reported (`ContentReportReason`).
enum ReportReason {
  spam('spam', 'Spam'),
  offensive('offensive', 'Offensive or rude'),
  wrongInfo('wrong_info', 'Wrong information'),
  offTopic('off_topic', 'Off-topic'),
  other('other', 'Something else');

  const ReportReason(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// The three feed tabs. Unanswered is the newest posts with no replies
/// (filtered in the app: the backend has no such sort).
enum FeedSort {
  latest('Latest', 'new'),
  unanswered('Unanswered', 'new'),
  top('Top', 'top');

  const FeedSort(this.label, this.apiValue);

  final String label;
  final String apiValue;
}
