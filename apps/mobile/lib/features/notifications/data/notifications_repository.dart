import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/notifications_models.dart';

part 'notifications_repository.g.dart';

/// Notification center. Only this layer calls the API.
abstract interface class NotificationsRepository {
  /// `GET /notifications` - newest first.
  Future<List<AppNotification>> notifications();

  /// `PATCH /notifications/{id}` with `{read: true}`.
  Future<void> markRead(String id);

  /// `POST /notifications/read-all`
  Future<void> markAllRead();
}

class ApiNotificationsRepository implements NotificationsRepository {
  ApiNotificationsRepository(this.api);

  final ApiClient api;

  @override
  Future<List<AppNotification>> notifications() async {
    final json = await api.get<Map<String, dynamic>>('/notifications');
    return [
      for (final item in json['items'] as List<dynamic>)
        AppNotification.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> markRead(String id) =>
      api.patch<Object?>('/notifications/$id', data: {'read': true});

  @override
  Future<void> markAllRead() => api.post<Object?>('/notifications/read-all');
}

/// DEBUG ONLY (`USE_FAKE_API=true`): the list from the Figma F4 screen.
class FakeNotificationsRepository implements NotificationsRepository {
  late final _items = <AppNotification>[
    _n(
      'n1',
      NotificationKind.reminder,
      'Time for today\'s plan',
      '3 tasks · 30 min. Start with Dihybrid crosses.',
      0,
    ),
    _n(
      'n2',
      NotificationKind.recommendation,
      'New next step for you',
      'You missed 3 Nephron MCQs — a 10-min set is ready.',
      3,
      ai: true,
    ),
    _n(
      'n3',
      NotificationKind.community,
      'Ms. Tharushi replied',
      '"Good AI answer. Add: the left ventricle must..."',
      5,
    ),
    _n(
      'n4',
      NotificationKind.achievement,
      'Badge unlocked: Genetics fixer',
      'You moved Genetics from Weak to Strong.',
      24,
      read: true,
    ),
    _n(
      'n5',
      NotificationKind.community,
      '12 students upvoted your answer',
      'On "Why does the Calvin cycle stop..."',
      26,
      read: true,
    ),
    _n(
      'n6',
      NotificationKind.streak,
      "Don't break your 11-day streak!",
      'One quick quiz keeps it alive.',
      72,
      read: true,
    ),
  ];

  static AppNotification _n(
    String id,
    NotificationKind type,
    String title,
    String body,
    int hoursAgo, {
    bool read = false,
    bool ai = false,
  }) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: DateTime.now().subtract(Duration(hours: hoursAgo)),
    read: read,
    aiGenerated: ai,
  );

  @override
  Future<List<AppNotification>> notifications() async => List.of(_items);

  @override
  Future<void> markRead(String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i >= 0) _items[i] = _items[i].copyWith(read: true);
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
  }
}

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) => Env.useFakeApi
    ? FakeNotificationsRepository()
    : ApiNotificationsRepository(ref.watch(apiClientProvider));
