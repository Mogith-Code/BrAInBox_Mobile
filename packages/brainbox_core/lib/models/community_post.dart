import 'package:freezed_annotation/freezed_annotation.dart';

part 'community_post.freezed.dart';
part 'community_post.g.dart';

/// A post in a study group.
///
// TODO(mogith): check these fields against the backend OpenAPI /docs.
@freezed
abstract class CommunityPost with _$CommunityPost {
  const factory CommunityPost({
    required String id,
    required String groupId,
    required String authorId,
    required String authorName,
    required String body,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    DateTime? createdAt,
  }) = _CommunityPost;

  factory CommunityPost.fromJson(Map<String, dynamic> json) =>
      _$CommunityPostFromJson(json);
}
