import 'package:brainbox_admin/widgets/admin_page.dart';
import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const AdminPageHeader(eyebrow: '8 items', title: 'Question bank'),
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
    );

    expect(find.text('Question bank'), findsOneWidget);
    expect(find.text('AI-generated · pending review'), findsOneWidget);
    expect(find.text('Not connected yet'), findsOneWidget);
  });
}
