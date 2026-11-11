import 'package:brainbox_mobile/features/notifications/data/notifications_repository.dart';
import 'package:brainbox_mobile/features/notifications/domain/notifications_models.dart';
import 'package:brainbox_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(
          FakeNotificationsRepository(),
        ),
      ],
      child: const MaterialApp(home: NotificationsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// The unread dots (the tile merges their label into the row's).
final _unreadDots = find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == 'Unread',
);

void main() {
  test('unknown types from the backend become "other"', () {
    final n = AppNotification.fromJson({
      'id': 'x',
      'type': 'brand_new',
      'title': 'T',
    });
    expect(n.type, NotificationKind.other);
    expect(NotificationFilter.all.matches(n), isTrue);
    expect(NotificationFilter.community.matches(n), isFalse);
  });

  testWidgets('lists notifications with unread dots and filters', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text("Time for today's plan"), findsOneWidget);
    expect(_unreadDots, findsNWidgets(3));

    final community = find.widgetWithText(ChoiceChip, 'Community');
    await tester.ensureVisible(community);
    await tester.tap(community);
    await tester.pumpAndSettle();
    expect(find.text('Ms. Tharushi replied'), findsOneWidget);
    expect(find.text("Time for today's plan"), findsNothing);
  });

  testWidgets('tap marks one read; Mark all read clears the rest', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text("Time for today's plan"));
    await tester.pumpAndSettle();
    expect(_unreadDots, findsNWidgets(2));

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    expect(_unreadDots, findsNothing);
  });
}
