import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/notifications_repository.dart';
import '../domain/notifications_models.dart';

part 'notifications_controller.g.dart';

/// The Notification center. Marking read updates the list at once.
@riverpod
class NotificationsController extends _$NotificationsController {
  @override
  Future<List<AppNotification>> build() =>
      ref.watch(notificationsRepositoryProvider).notifications();

  Future<void> markRead(String id) async {
    _set((n) => n.id == id ? n.copyWith(read: true) : n);
    try {
      await ref.read(notificationsRepositoryProvider).markRead(id);
    } catch (_) {
      // Not critical: it shows as unread again after the next refresh.
    }
  }

  /// Returns false when it failed (the dots come back).
  Future<bool> markAllRead() async {
    final before = state.value;
    _set((n) => n.copyWith(read: true));
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
      return true;
    } catch (_) {
      if (ref.mounted && before != null) state = AsyncData(before);
      return false;
    }
  }

  void _set(AppNotification Function(AppNotification) change) {
    final now = state.value;
    if (now != null) state = AsyncData([for (final n in now) change(n)]);
  }
}
