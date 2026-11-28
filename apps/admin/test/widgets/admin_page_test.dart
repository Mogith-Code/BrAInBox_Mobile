import 'package:brainbox_admin/features/auth/data/auth_repository.dart';
import 'package:brainbox_admin/widgets/admin_page.dart';
import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthRepository {}

void main() {
  test('a missing endpoint is not the same as a missing item', () {
    const route = ApiException(
      code: 'http_404',
      message: 'Not Found',
      statusCode: 404,
    );
    const item = ApiException(
      code: 'QUESTION_NOT_FOUND',
      message: 'No such question',
      statusCode: 404,
    );
    expect(isEndpointMissing(route), isTrue);
    expect(isEndpointMissing(item), isFalse);
    expect(isEndpointMissing(Exception('x')), isFalse);
  });

  test('review status reads the backend values', () {
    expect(ReviewStatus.fromApi('pending_review'), ReviewStatus.pendingReview);
    expect(ReviewStatus.fromApi('approved'), ReviewStatus.approved);
    expect(ReviewStatus.fromApi('something_new'), ReviewStatus.draft);
    expect(ReviewStatus.pendingReview.apiValue, 'pending_review');
  });

  testWidgets('header, badges and the not-connected state render', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const AdminPageHeader(
                  eyebrow: '8 items',
                  title: 'Question bank',
                ),
                reviewBadge(ReviewStatus.pendingReview, aiGenerated: true),
                Expanded(
                  child: AdminLoadError(
                    error: const ApiException(
                      code: 'http_404',
                      message: 'Not Found',
                      statusCode: 404,
                    ),
                    onRetry: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Question bank'), findsOneWidget);
    expect(find.text('AI-generated · pending review'), findsOneWidget);
    expect(find.text('Not connected yet'), findsOneWidget);
  });

  group('adminErrorMessage', () {
    test('uses the backend sentence for admin errors', () {
      expect(
        adminErrorMessage(
          const ApiException(
            code: 'GROUP_NAME_TAKEN',
            message: "A group called 'Unit 6' already exists",
            statusCode: 409,
          ),
        ),
        "A group called 'Unit 6' already exists",
      );
    });

    test('403 = not an admin, 401 = sign in again', () {
      expect(
        adminErrorMessage(
          const ApiException(
            code: 'FORBIDDEN',
            message: 'You do not have permission to do this',
            statusCode: 403,
          ),
        ),
        'This account is not an admin.',
      );
      expect(
        adminErrorMessage(
          const ApiException(
            code: 'UNAUTHORIZED',
            message: 'Missing bearer token',
            statusCode: 401,
          ),
        ),
        'Your sign-in has expired. Log out and sign in again.',
      );
    });

    test('validation errors name the fields', () {
      expect(
        adminErrorMessage(
          const ApiException(
            code: 'VALIDATION_ERROR',
            message: 'Request data is invalid',
            statusCode: 422,
            details: {
              'details': [
                {'field': 'body.name', 'message': 'too short'},
              ],
            },
          ),
        ),
        'Check these values: name: too short.',
      );
      expect(
        adminErrorMessage(const FormatException('unit number')),
        'That is not a valid number.',
      );
    });
  });

  for (final (status, code, title) in [
    (403, 'FORBIDDEN', 'This account is not an admin.'),
    (401, 'UNAUTHORIZED', 'Please sign in again'),
  ]) {
    testWidgets('a $status on a page offers Log out, not a raw error', (
      tester,
    ) async {
      final auth = _MockAuth();
      when(auth.signOut).thenAnswer((_) async {});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(auth)],
          child: MaterialApp(
            home: Scaffold(
              body: AdminLoadError(
                error: ApiException(
                  code: code,
                  message: 'Missing bearer token',
                  statusCode: status,
                ),
                onRetry: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text(title), findsOneWidget);
      expect(find.text('Missing bearer token'), findsNothing);
      await tester.tap(find.text('Log out'));
      verify(auth.signOut).called(1);
    });
  }
}
