import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/community_models.dart';

/// Data layer for the Community feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class CommunityRepository {
  CommunityRepository(this.api);

  final ApiClient api;

  // ---------------------------------------------------------------- groups

  /// `GET /groups` - General first, then the unit groups.
  Future<List<StudyGroup>> fetchGroups() async {
    final json = await api.get<List<dynamic>>('/groups');
    return [
      for (final item in json)
        StudyGroup.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  /// `GET /groups/{id}` - [groupId] is the UUID or the slug ("unit-6").
  Future<StudyGroup> fetchGroup(String groupId) async => StudyGroup.fromJson(
    await api.get<Map<String, dynamic>>('/groups/$groupId'),
  );

  /// `POST /groups/{id}/join` (safe to repeat).
  Future<StudyGroup> join(String groupId) async => StudyGroup.fromJson(
    await api.post<Map<String, dynamic>>('/groups/$groupId/join'),
  );

  /// `DELETE /groups/{id}/join` (safe to repeat).
  Future<StudyGroup> leave(String groupId) async => StudyGroup.fromJson(
    await api.delete<Map<String, dynamic>>('/groups/$groupId/join'),
  );

  // ---------------------------------------------------------------- posts

  /// `GET /groups/{id}/posts?sort=new|top&page=&size=`
  Future<PostPage> fetchPosts(
    String groupId, {
    required String sort,
    int page = 1,
    int size = 20,
  }) async => PostPage.fromJson(
    await api.get<Map<String, dynamic>>(
      '/groups/$groupId/posts',
      query: {'sort': sort, 'page': page, 'size': size},
    ),
  );

  /// `POST /groups/{id}/posts`. The created post's `moderation_status` is
  /// `flagged` when the AI holds it back for an admin.
  Future<Post> createPost(
    String groupId, {
    required String title,
    required String body,
    required bool isQuestion,
    String? topicId,
  }) async => Post.fromJson(
    await api.post<Map<String, dynamic>>(
      '/groups/$groupId/posts',
      data: {
        'title': title,
        'body': body,
        'is_question': isQuestion,
        'topic_id': ?topicId,
      },
    ),
  );

  /// `POST /posts/suggest-topic` - the AI's topic tag for a draft.
  Future<TopicSuggestion> suggestTopic({
    required String title,
    required String body,
    String? groupId,
  }) async => TopicSuggestion.fromJson(
    await api.post<Map<String, dynamic>>(
      '/posts/suggest-topic',
      data: {'title': title, 'body': body, 'group_id': ?groupId},
    ),
  );

  /// `GET /units/{u6}/topics` - the topics a unit group's post can be tagged
  /// with.
  Future<List<TopicOption>> fetchUnitTopics(int unitNumber) async {
    final json = await api.get<Map<String, dynamic>>(
      '/units/u$unitNumber/topics',
    );
    return [
      for (final item in (json['topics'] as List? ?? const []))
        TopicOption.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  /// `GET /posts/{id}` - the post with its replies.
  Future<PostDetail> fetchPost(String postId) async => PostDetail.fromJson(
    await api.get<Map<String, dynamic>>('/posts/$postId'),
  );

  /// `PATCH /posts/{id}` - only the author.
  Future<Post> updatePost(
    String postId, {
    required String title,
    required String body,
  }) async => Post.fromJson(
    await api.patch<Map<String, dynamic>>(
      '/posts/$postId',
      data: {'title': title, 'body': body},
    ),
  );

  /// `DELETE /posts/{id}` - the author (or an admin).
  Future<void> deletePost(String postId) =>
      api.delete<Object?>('/posts/$postId');

  // ---------------------------------------------------------------- replies

  /// `POST /posts/{id}/replies` - members of the post's group.
  Future<Reply> createReply(String postId, String body) async => Reply.fromJson(
    await api.post<Map<String, dynamic>>(
      '/posts/$postId/replies',
      data: {'body': body},
    ),
  );

  /// `PATCH /replies/{id}` - only the author.
  Future<Reply> updateReply(String replyId, String body) async =>
      Reply.fromJson(
        await api.patch<Map<String, dynamic>>(
          '/replies/$replyId',
          data: {'body': body},
        ),
      );

  /// `DELETE /replies/{id}` - the author (or an admin).
  Future<void> deleteReply(String replyId) =>
      api.delete<Object?>('/replies/$replyId');

  /// `POST /posts/{id}/accept/{reply}` - the post's author marks the best
  /// answer.
  Future<PostDetail> accept(String postId, String replyId) async =>
      PostDetail.fromJson(
        await api.post<Map<String, dynamic>>('/posts/$postId/accept/$replyId'),
      );

  /// `DELETE /posts/{id}/accept` - un-marks the best answer.
  Future<PostDetail> unaccept(String postId) async => PostDetail.fromJson(
    await api.delete<Map<String, dynamic>>('/posts/$postId/accept'),
  );

  // ---------------------------------------------------------------- votes + reports

  /// `POST /votes` - [value] 1 / -1, or 0 to remove my vote. Exactly one of
  /// [postId] / [replyId].
  Future<VoteResult> vote({
    String? postId,
    String? replyId,
    required int value,
  }) async => VoteResult.fromJson(
    await api.post<Map<String, dynamic>>(
      '/votes',
      data: {'post_id': ?postId, 'reply_id': ?replyId, 'value': value},
    ),
  );

  /// `POST /posts/{id}/report`
  Future<void> reportPost(
    String postId, {
    required ReportReason reason,
    String? details,
  }) => api.post<Object?>(
    '/posts/$postId/report',
    data: _report(reason, details),
  );

  /// `POST /replies/{id}/report`
  Future<void> reportReply(
    String replyId, {
    required ReportReason reason,
    String? details,
  }) => api.post<Object?>(
    '/replies/$replyId/report',
    data: _report(reason, details),
  );

  static Map<String, dynamic> _report(ReportReason reason, String? details) => {
    'reason': reason.apiValue,
    if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
  };
}

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(ref.watch(apiClientProvider)),
);
