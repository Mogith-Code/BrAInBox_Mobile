import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/notifications_models.dart';

part 'notifications_repository.g.dart';

/// Data layer for the Notifications feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class NotificationsRepository {
  NotificationsRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Notifications screen.
  Future<NotificationsSummary> fetchSummary() async {
    // TODO(samni): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/notifications');
    // return NotificationsSummary.fromJson(json);
    return const NotificationsSummary(
      title: 'Notifications',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  // TODO(samni): add one method per endpoint, e.g.
  //   POST /notifications/{notification_id}/read  ->  Mark as read
}

@riverpod
NotificationsRepository notificationsRepository(Ref ref) =>
    NotificationsRepository(ref.watch(apiClientProvider));
