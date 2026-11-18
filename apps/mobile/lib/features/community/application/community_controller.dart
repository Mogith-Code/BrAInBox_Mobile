import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../insights/data/insights_repository.dart';
import '../../insights/domain/insights_models.dart' show TopicStatus;
import '../../insights/domain/unit_insights.dart';
import '../data/community_repository.dart';
import '../domain/community_models.dart';

/// A friendly sentence for a failed community request.
String communityErrorMessage(Object error) {
  // The shared text for ALREADY_REPORTED talks about visuals.
  if (error is ApiException && error.code == 'ALREADY_REPORTED') {
    return 'You already reported this. An admin will check it soon.';
  }
  return ErrorMessages.of(error);
}

// =========================================================================== groups

/// The Community tab: my groups and the groups I can join, weak units first.
class GroupsState {
  const GroupsState({
    this.myGroups = const [],
    this.toJoin = const [],
    this.unitMastery = const {},
    this.busyGroupIds = const {},
  });

  final List<StudyGroup> myGroups;
  final List<StudyGroup> toJoin;

  /// My mastery per unit id (`GET /insights/units`). Empty when it could not
  /// be loaded: the groups then keep the backend's order.
  final Map<String, UnitMastery> unitMastery;

  /// Groups being joined or left right now.
  final Set<String> busyGroupIds;

  /// The weak-unit chip shows for these (the backend's weak / very weak).
  bool isWeak(StudyGroup group) {
    final status = unitMastery[group.unitId]?.status;
    return status == TopicStatus.weak || status == TopicStatus.veryWeak;
  }

  GroupsState copyWith({
    List<StudyGroup>? myGroups,
    List<StudyGroup>? toJoin,
    Set<String>? busyGroupIds,
  }) => GroupsState(
    myGroups: myGroups ?? this.myGroups,
    toJoin: toJoin ?? this.toJoin,
    unitMastery: unitMastery,
    busyGroupIds: busyGroupIds ?? this.busyGroupIds,
  );
}

/// Weak units first: assessed unit groups by mastery (lowest first), then
/// unit groups not assessed yet (unit order), then groups without a unit
/// (General). Only the order changes; every value is the backend's.
List<StudyGroup> weakUnitsFirst(
  List<StudyGroup> groups,
  Map<String, UnitMastery> mastery,
) {
  // No mastery data (new student, or the request failed): backend order.
  if (mastery.isEmpty) return groups;
  int rank(StudyGroup g) {
    if (g.unitId == null) return 2;
    return mastery[g.unitId]?.mastery == null ? 1 : 0;
  }

  final indexed = groups.asMap().entries.toList()
    ..sort((a, b) {
      final x = a.value;
      final y = b.value;
      final byRank = rank(x).compareTo(rank(y));
      if (byRank != 0) return byRank;
      if (rank(x) == 0) {
        final byMastery = mastery[x.unitId]!.mastery!.compareTo(
          mastery[y.unitId]!.mastery!,
        );
        if (byMastery != 0) return byMastery;
      }
      if (rank(x) == 1) {
        final byUnit = (x.unitNumber ?? 99).compareTo(y.unitNumber ?? 99);
        if (byUnit != 0) return byUnit;
      }
      return a.key.compareTo(b.key); // stable
    });
  return [for (final e in indexed) e.value];
}

class GroupsController extends AsyncNotifier<GroupsState> {
  CommunityRepository get _repository => ref.read(communityRepositoryProvider);

  @override
  Future<GroupsState> build() async {
    final repository = ref.watch(communityRepositoryProvider);
    // Both requests run together. Await the groups first: if they fail, the
    // error must reach `state` (mastery never throws, see _loadMastery).
    final mastery = _loadMastery();
    final groups = await repository.fetchGroups();
    return _split(groups, await mastery);
  }

  Future<Map<String, UnitMastery>> _loadMastery() async {
    try {
      final units = await ref
          .read(insightsRepositoryProvider)
          .fetchUnitInsights();
      return {for (final unit in units.units) unit.unitId: unit};
    } on Object {
      // Ordering is a nice-to-have: never block the groups on it.
      return const {};
    }
  }

  GroupsState _split(List<StudyGroup> groups, Map<String, UnitMastery> m) =>
      GroupsState(
        myGroups: weakUnitsFirst([...groups.where((g) => g.isMember)], m),
        toJoin: weakUnitsFirst([...groups.where((g) => !g.isMember)], m),
        unitMastery: m,
      );

  /// Joins or leaves [group]. Returns an error sentence, or null.
  Future<String?> setMember(StudyGroup group, {required bool join}) async {
    final current = state.value;
    if (current == null || current.busyGroupIds.contains(group.id)) {
      return null;
    }
    state = AsyncData(
      current.copyWith(busyGroupIds: {...current.busyGroupIds, group.id}),
    );
    try {
      final updated = join
          ? await _repository.join(group.id)
          : await _repository.leave(group.id);
      final latest = state.value ?? current;
      final all = [
        for (final g in [...latest.myGroups, ...latest.toJoin])
          g.id == updated.id ? updated : g,
      ];
      if (ref.mounted) {
        state = AsyncData(
          _split(
            all,
            latest.unitMastery,
          ).copyWith(busyGroupIds: {...latest.busyGroupIds}..remove(group.id)),
        );
      }
      return null;
    } on Object catch (error) {
      final latest = state.value ?? current;
      if (ref.mounted) {
        state = AsyncData(
          latest.copyWith(
            busyGroupIds: {...latest.busyGroupIds}..remove(group.id),
          ),
        );
      }
      return communityErrorMessage(error);
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Shown by the screen.
    }
  }
}

final groupsProvider =
    AsyncNotifierProvider.autoDispose<GroupsController, GroupsState>(
      GroupsController.new,
    );

/// One group (name, membership) for the feed header.
final groupProvider = FutureProvider.autoDispose.family<StudyGroup, String>(
  (ref, groupId) => ref.watch(communityRepositoryProvider).fetchGroup(groupId),
);

/// Joins [groupId] from its feed, then reloads the header and the group
/// list. Returns an error sentence, or null.
Future<String?> joinGroup(WidgetRef ref, String groupId) async {
  try {
    await ref.read(communityRepositoryProvider).join(groupId);
    ref
      ..invalidate(groupProvider(groupId))
      ..invalidate(groupsProvider);
    return null;
  } on Object catch (error) {
    return communityErrorMessage(error);
  }
}

// =========================================================================== feed

typedef FeedArgs = ({String groupId, FeedSort sort});

class FeedState {
  const FeedState({
    this.posts = const [],
    this.page = 0,
    this.pages = 0,
    this.sort = FeedSort.latest,
    this.loadingMore = false,
    this.loadMoreError,
  });

  /// Every post loaded so far, in the backend's order.
  final List<Post> posts;
  final int page;
  final int pages;
  final FeedSort sort;
  final bool loadingMore;
  final String? loadMoreError;

  bool get hasMore => page < pages;

  /// What the tab shows: Unanswered keeps the posts without replies.
  List<Post> get visible => sort == FeedSort.unanswered
      ? [
          for (final p in posts)
            if (p.replyCount == 0) p,
        ]
      : posts;

  FeedState copyWith({
    List<Post>? posts,
    int? page,
    int? pages,
    bool? loadingMore,
    String? loadMoreError,
  }) => FeedState(
    posts: posts ?? this.posts,
    page: page ?? this.page,
    pages: pages ?? this.pages,
    sort: sort,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: loadMoreError,
  );
}

/// A group's feed for one tab, paged.
class FeedController extends AsyncNotifier<FeedState> {
  FeedController(this.args);

  final FeedArgs args;

  static const pageSize = 20;

  /// Unanswered filters in the app, so it reads a few more pages until it
  /// has something to show.
  static const _maxPagesForUnanswered = 5;

  CommunityRepository get _repository => ref.read(communityRepositoryProvider);

  @override
  Future<FeedState> build() async {
    ref.watch(communityRepositoryProvider);
    var feed = FeedState(sort: args.sort);
    do {
      feed = _append(feed, await _fetch(feed.page + 1));
    } while (args.sort == FeedSort.unanswered &&
        feed.visible.isEmpty &&
        feed.hasMore &&
        feed.page < _maxPagesForUnanswered);
    return feed;
  }

  Future<PostPage> _fetch(int page) => _repository.fetchPosts(
    args.groupId,
    sort: args.sort.apiValue,
    page: page,
    size: pageSize,
  );

  FeedState _append(FeedState feed, PostPage page) {
    final seen = {for (final p in feed.posts) p.id};
    return feed.copyWith(
      posts: [
        ...feed.posts,
        for (final p in page.items)
          if (!seen.contains(p.id)) p,
      ],
      page: page.page,
      pages: page.pages,
    );
  }

  /// Loads the next page (end of the list).
  Future<void> loadMore() async {
    final feed = state.value;
    if (feed == null || feed.loadingMore || !feed.hasMore) return;
    state = AsyncData(feed.copyWith(loadingMore: true));
    try {
      final page = await _fetch(feed.page + 1);
      if (ref.mounted) {
        state = AsyncData(_append(feed, page).copyWith(loadingMore: false));
      }
    } on Object catch (error) {
      if (ref.mounted) {
        state = AsyncData(
          feed.copyWith(
            loadingMore: false,
            loadMoreError: communityErrorMessage(error),
          ),
        );
      }
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Shown by the screen.
    }
  }
}

final feedProvider = AsyncNotifierProvider.autoDispose
    .family<FeedController, FeedState, FeedArgs>(FeedController.new);

// =========================================================================== post

/// One post with its replies, and everything the post page can do.
///
/// Every action returns an error sentence (for a snack bar) or null.
class PostDetailController extends AsyncNotifier<PostDetail> {
  PostDetailController(this.postId);

  final String postId;

  CommunityRepository get _repository => ref.read(communityRepositoryProvider);

  @override
  Future<PostDetail> build() =>
      ref.watch(communityRepositoryProvider).fetchPost(postId);

  /// Pull-to-refresh (the AI-suggested answer arrives a few seconds late).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Shown by the screen.
    }
  }

  Future<String?> _guard(
    Future<void> Function(PostDetail detail) action,
  ) async {
    final detail = state.value;
    if (detail == null) return null;
    try {
      await action(detail);
      return null;
    } on Object catch (error) {
      return communityErrorMessage(error);
    }
  }

  /// Votes on the post, or on [reply] when given. [value] 1 / -1, or 0 to
  /// remove my vote. Shown at once; undone if the server refuses it.
  Future<String?> vote({Reply? reply, required int value}) async {
    final before = state.value;
    if (before == null) return null;
    int newScore(int score, int mine) => score - mine + value;
    state = AsyncData(
      _withVote(before, reply?.id, (score, mine) {
        return (newScore(score, mine), value);
      }),
    );
    try {
      final result = await _repository.vote(
        postId: reply == null ? postId : null,
        replyId: reply?.id,
        value: value,
      );
      final latest = state.value ?? before;
      if (ref.mounted) {
        state = AsyncData(
          _withVote(latest, reply?.id, (_, _) => (result.score, result.myVote)),
        );
      }
      return null;
    } on Object catch (error) {
      if (ref.mounted) state = AsyncData(before);
      return communityErrorMessage(error);
    }
  }

  PostDetail _withVote(
    PostDetail detail,
    String? replyId,
    (int, int) Function(int score, int myVote) change,
  ) {
    if (replyId == null) {
      final (score, mine) = change(detail.post.score, detail.post.myVote);
      return detail.copyWith(
        post: detail.post.copyWith(score: score, myVote: mine),
      );
    }
    return detail.copyWith(
      replies: [
        for (final r in detail.replies)
          if (r.id == replyId)
            () {
              final (score, mine) = change(r.score, r.myVote);
              return r.copyWith(score: score, myVote: mine);
            }()
          else
            r,
      ],
    );
  }

  /// Posts a reply.
  Future<String?> reply(String body) => _guard((detail) async {
    final created = await _repository.createReply(postId, body.trim());
    if (ref.mounted) {
      state = AsyncData(
        (state.value ?? detail).copyWith(
          replies: [...(state.value ?? detail).replies, created],
        ),
      );
    }
  });

  Future<String?> editReply(Reply reply, String body) => _guard((detail) async {
    final updated = await _repository.updateReply(reply.id, body.trim());
    final latest = state.value ?? detail;
    if (ref.mounted) {
      state = AsyncData(
        latest.copyWith(
          replies: [
            for (final r in latest.replies) r.id == reply.id ? updated : r,
          ],
        ),
      );
    }
  });

  Future<String?> deleteReply(Reply reply) => _guard((detail) async {
    await _repository.deleteReply(reply.id);
    // The reply count and accepted answer change too: read it again.
    await refresh();
  });

  /// Marks [reply] as the best answer, or un-marks it when it already is.
  Future<String?> toggleAccepted(Reply reply) => _guard((detail) async {
    final updated = reply.isAccepted
        ? await _repository.unaccept(postId)
        : await _repository.accept(postId, reply.id);
    if (ref.mounted) state = AsyncData(updated);
  });

  Future<String?> editPost({required String title, required String body}) =>
      _guard((detail) async {
        final updated = await _repository.updatePost(
          postId,
          title: title.trim(),
          body: body.trim(),
        );
        if (ref.mounted) {
          state = AsyncData((state.value ?? detail).copyWith(post: updated));
        }
      });

  Future<String?> deletePost() => _guard((_) => _repository.deletePost(postId));

  /// Reports the post, or [reply] when given.
  Future<String?> report({
    Reply? reply,
    required ReportReason reason,
    String? details,
  }) => _guard(
    (_) => reply == null
        ? _repository.reportPost(postId, reason: reason, details: details)
        : _repository.reportReply(reply.id, reason: reason, details: details),
  );
}

final postDetailProvider = AsyncNotifierProvider.autoDispose
    .family<PostDetailController, PostDetail, String>(PostDetailController.new);

// =========================================================================== create

class CreatePostState {
  const CreatePostState({
    this.suggestion,
    this.suggesting = false,
    this.topicId,
    this.topic,
    this.topicFromAi = false,
    this.topicRemoved = false,
    this.submitting = false,
    this.error,
  });

  /// The AI's last suggestion (also when no topic fits).
  final TopicSuggestion? suggestion;
  final bool suggesting;

  /// The topic tag the post will be sent with.
  final String? topicId;
  final String? topic;

  /// True while [topic] is the AI's suggestion (shows the AiBadge).
  final bool topicFromAi;

  /// The student removed the tag: stop suggesting one.
  final bool topicRemoved;
  final bool submitting;
  final String? error;

  CreatePostState copyWith({
    TopicSuggestion? suggestion,
    bool? suggesting,
    String? Function()? topicId,
    String? Function()? topic,
    bool? topicFromAi,
    bool? topicRemoved,
    bool? submitting,
    String? Function()? error,
  }) => CreatePostState(
    suggestion: suggestion ?? this.suggestion,
    suggesting: suggesting ?? this.suggesting,
    topicId: topicId != null ? topicId() : this.topicId,
    topic: topic != null ? topic() : this.topic,
    topicFromAi: topicFromAi ?? this.topicFromAi,
    topicRemoved: topicRemoved ?? this.topicRemoved,
    submitting: submitting ?? this.submitting,
    error: error != null ? error() : this.error,
  );
}

/// Create post: the debounced topic suggestion and sending the post.
class CreatePostController extends Notifier<CreatePostState> {
  /// Wait this long after the last keystroke before asking the AI.
  static const debounce = Duration(milliseconds: 800);

  Timer? _timer;
  int _request = 0;

  CommunityRepository get _repository => ref.read(communityRepositoryProvider);

  @override
  CreatePostState build() {
    ref.onDispose(() => _timer?.cancel());
    return const CreatePostState();
  }

  /// Call on every change of the title or body.
  void draftChanged({
    required String title,
    required String body,
    String? groupId,
  }) {
    _timer?.cancel();
    // A tag the student picked or removed is theirs: keep it.
    if (state.topicRemoved || (state.topicId != null && !state.topicFromAi)) {
      return;
    }
    if (title.trim().length < 3) return;
    _timer = Timer(
      debounce,
      () => _suggest(title: title, body: body, groupId: groupId),
    );
  }

  Future<void> _suggest({
    required String title,
    required String body,
    String? groupId,
  }) async {
    final request = ++_request;
    state = state.copyWith(suggesting: true);
    try {
      final suggestion = await _repository.suggestTopic(
        title: title.trim(),
        body: body.trim(),
        groupId: groupId,
      );
      if (!ref.mounted || request != _request) return;
      final keepMine =
          state.topicRemoved || (state.topicId != null && !state.topicFromAi);
      state = keepMine
          ? state.copyWith(suggestion: suggestion, suggesting: false)
          : state.copyWith(
              suggestion: suggestion,
              suggesting: false,
              topicId: () => suggestion.topicId,
              topic: () => suggestion.topic,
              topicFromAi: suggestion.topicId != null,
            );
    } on Object {
      // A suggestion is optional: posting works without one.
      if (ref.mounted && request == _request) {
        state = state.copyWith(suggesting: false);
      }
    }
  }

  /// The student picked another topic.
  void chooseTopic(TopicOption option) {
    _timer?.cancel();
    _request++;
    state = state.copyWith(
      topicId: () => option.id,
      topic: () => option.title,
      topicFromAi: false,
      topicRemoved: false,
      suggesting: false,
    );
  }

  /// The student removed the topic tag.
  void removeTopic() {
    _timer?.cancel();
    _request++;
    state = state.copyWith(
      topicId: () => null,
      topic: () => null,
      topicFromAi: false,
      topicRemoved: true,
      suggesting: false,
    );
  }

  /// Sends the post. Returns it (check `moderationStatus`), or null on
  /// failure (the error is in `state`).
  Future<Post?> submit({
    required String groupId,
    required String title,
    required String body,
    required bool isQuestion,
  }) async {
    if (state.submitting) return null;
    state = state.copyWith(submitting: true, error: () => null);
    try {
      final post = await _repository.createPost(
        groupId,
        title: title.trim(),
        body: body.trim(),
        isQuestion: isQuestion,
        topicId: state.topicId,
      );
      if (ref.mounted) state = state.copyWith(submitting: false);
      return post;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          submitting: false,
          error: () => communityErrorMessage(error),
        );
      }
      return null;
    }
  }
}

final createPostProvider =
    NotifierProvider.autoDispose<CreatePostController, CreatePostState>(
      CreatePostController.new,
    );

/// The topics a unit group's post can be tagged with.
final unitTopicsProvider = FutureProvider.autoDispose
    .family<List<TopicOption>, int>(
      (ref, unitNumber) =>
          ref.watch(communityRepositoryProvider).fetchUnitTopics(unitNumber),
    );

/// My groups (members only can post), for Create post without a group.
final myGroupsProvider = FutureProvider.autoDispose<List<StudyGroup>>(
  (ref) async => [
    for (final g in await ref.watch(communityRepositoryProvider).fetchGroups())
      if (g.isMember) g,
  ],
);
