import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/past_papers_repository.dart';
import '../domain/past_papers_models.dart';

part 'past_papers_controller.g.dart';

/// The papers table. Uploading adds the new paper at the top.
@riverpod
class PastPapersController extends _$PastPapersController {
  @override
  Future<List<PastPaper>> build() =>
      ref.watch(pastPapersRepositoryProvider).papers();

  Future<bool> upload({
    required List<int> bytes,
    required String fileName,
    required int year,
    required PaperType type,
  }) async {
    try {
      final paper = await ref
          .read(pastPapersRepositoryProvider)
          .upload(bytes: bytes, fileName: fileName, year: year, type: type);
      if (ref.mounted) state = AsyncData([paper, ...?state.value]);
      return true;
    } catch (_) {
      return false;
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

  Future<bool> save(String paperId, PaperQuestion q) async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(pastPapersRepositoryProvider).saveAnswer(q),
    );
    if (!ref.mounted) return false;
    state = next.whenData((_) {});
    if (next.hasValue) ref.invalidate(paperQuestionsProvider(paperId));
    return next.hasValue;
  }
}
