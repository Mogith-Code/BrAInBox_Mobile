import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/learn_repository.dart';

part 'topic_media_controller.g.dart';

/// Stored diagrams for the Diagrams tab.
@riverpod
Future<List<Diagram>> topicDiagrams(Ref ref, String topicId) =>
    ref.watch(learnRepositoryProvider).fetchDiagrams(topicId);

/// Videos for the Videos tab.
@riverpod
Future<List<Video>> topicVideos(Ref ref, String topicId) =>
    ref.watch(learnRepositoryProvider).fetchVideos(topicId);

/// Questions available, accuracy and last attempt for the Practice tab.
@riverpod
Future<PracticeSummary> topicPracticeSummary(Ref ref, String topicId) =>
    ref.watch(learnRepositoryProvider).fetchPracticeSummary(topicId);
