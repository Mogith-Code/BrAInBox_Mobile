import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/content_review_repository.dart';
import '../domain/content_review_models.dart';

part 'content_review_controller.freezed.dart';
part 'content_review_controller.g.dart';

/// The tab and the filters above the table.
@freezed
abstract class ContentFilter with _$ContentFilter {
  const factory ContentFilter({
    ContentType? type, // null = All
    String? status, // null = Any
    int? unit, // null = All
  }) = _ContentFilter;
}

@riverpod
class ContentFilterController extends _$ContentFilterController {
  @override
  ContentFilter build() => const ContentFilter();

  void set(ContentFilter filter) => state = filter;
}

/// The Content library rows for the current filter.
@riverpod
class ContentReviewController extends _$ContentReviewController {
  @override
  Future<List<ContentItem>> build() {
    final f = ref.watch(contentFilterControllerProvider);
    return ref
        .watch(contentReviewRepositoryProvider)
        .items(type: f.type, status: f.status, unit: f.unit);
  }

  /// Approve / Reject, then show the new status in the row.
  Future<ContentItem?> review(
    String id, {
    required bool approve,
    String? note,
  }) => _update(
    () => ref
        .read(contentReviewRepositoryProvider)
        .review(id, approve: approve, note: note),
  );

  /// Saves an edited note body.
  Future<ContentItem?> edit(String id, String body) =>
      _update(() => ref.read(contentReviewRepositoryProvider).edit(id, body));

  Future<ContentItem?> _update(Future<ContentItem> Function() call) async {
    try {
      final saved = await call();
      final now = state.value;
      if (ref.mounted && now != null) {
        state = AsyncData([for (final i in now) i.id == saved.id ? saved : i]);
      }
      return saved;
    } catch (_) {
      return null;
    }
  }
}
