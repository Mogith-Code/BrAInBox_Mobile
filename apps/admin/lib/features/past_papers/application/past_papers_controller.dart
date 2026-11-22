import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/admin_errors.dart';
import '../data/past_papers_repository.dart';
import '../domain/past_papers_models.dart';

part 'past_papers_controller.g.dart';

/// The papers table. Uploading adds the new paper at the top.
///
/// While a paper's questions are being extracted, the list reloads quietly
/// every [pollEvery], so its progress and final state show by themselves.
@riverpod
class PastPapersController extends _$PastPapersController {
  static const pollEvery = Duration(seconds: 5);

  Timer? _poll;

  @override
  Future<List<PastPaper>> build() async {
    ref.onDispose(() => _poll?.cancel());
    final papers = await ref.watch(pastPapersRepositoryProvider).papers();
    _schedulePoll(papers);
    return papers;
  }

  void _schedulePoll(List<PastPaper> papers) {
    _poll?.cancel();
    if (papers.any((p) => p.extraction == ExtractionStatus.running)) {
      _poll = Timer(pollEvery, _refresh);
    }
  }

  Future<void> _refresh() async {
    if (!ref.mounted) return;
    try {
      final papers = await ref.read(pastPapersRepositoryProvider).papers();
      if (!ref.mounted) return;
      state = AsyncData(papers);
      _schedulePoll(papers);
    } catch (_) {
      // Keep what we show and try again later.
      if (ref.mounted) _poll = Timer(pollEvery, _refresh);
    }
  }

  /// Returns why it failed (e.g. the paper was already uploaded), or null.
  Future<String?> upload({
    required List<int> bytes,
    required String fileName,
    required int year,
    required PaperType type,
  }) async {
    try {
      final paper = await ref
          .read(pastPapersRepositoryProvider)
          .upload(bytes: bytes, fileName: fileName, year: year, type: type);
      if (ref.mounted) {
        final papers = [paper, ...?state.value];
        state = AsyncData(papers);
        _schedulePoll(papers);
      }
      return null;
    } catch (e) {
      return adminErrorMessage(e);
    }
  }
}

/// The extracted questions of one paper.
@riverpod
Future<List<PaperQuestion>> paperQuestions(Ref ref, String paperId) =>
    ref.watch(pastPapersRepositoryProvider).questions(paperId);

/// Saving a model answer + keywords.
@riverpod
class AnswerEditor extends _$AnswerEditor {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns why it failed, or null.
  Future<String?> save(String paperId, PaperQuestion q) async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(pastPapersRepositoryProvider).saveAnswer(q),
    );
    if (!ref.mounted) return null;
    state = next.whenData((_) {});
    if (next.hasValue) ref.invalidate(paperQuestionsProvider(paperId));
    return next.hasError ? adminErrorMessage(next.error) : null;
  }
}
