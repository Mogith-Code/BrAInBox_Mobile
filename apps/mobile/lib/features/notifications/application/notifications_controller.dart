import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/notifications_repository.dart';
import '../domain/notifications_models.dart';

part 'notifications_controller.g.dart';

/// State for the Notifications feature.
///
/// The state is an `AsyncValue<NotificationsSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(notificationsControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class NotificationsController extends _$NotificationsController {
  @override
  Future<NotificationsSummary> build() {
    // TODO(samni): load what the screen needs on open.
    return ref.watch(notificationsRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(notificationsRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(samni): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
}
