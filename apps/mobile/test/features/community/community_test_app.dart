import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/community/data/community_repository.dart';
import 'package:brainbox_mobile/features/community/domain/community_models.dart';
import 'package:brainbox_mobile/features/community/presentation/create_post_screen.dart';
import 'package:brainbox_mobile/features/community/presentation/group_feed_screen.dart';
import 'package:brainbox_mobile/features/community/presentation/groups_screen.dart';
import 'package:brainbox_mobile/features/community/presentation/post_detail_screen.dart';
import 'package:brainbox_mobile/features/insights/data/insights_repository.dart';
import 'package:brainbox_mobile/features/insights/domain/unit_insights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'community_fixtures.dart';

class MockCommunityRepository extends Mock implements CommunityRepository {}

class MockInsightsRepository extends Mock implements InsightsRepository {}

/// Insights answering `GET /insights/units` with [unitsJson] (or [error]).
MockInsightsRepository fakeInsights({Object? error}) {
  final insights = MockInsightsRepository();
  when(insights.fetchUnitInsights).thenAnswer(
    (_) => error != null
        ? Future<UnitInsights>.error(error)
        : Future.value(UnitInsights.fromJson(unitsJson())),
  );
  return insights;
}

void registerCommunityFallbacks() {
  registerFallbackValue(ReportReason.spam);
}

/// Pumps the community routes, starting at [location], on a tall phone so
/// whole lists are built.
Future<GoRouter> pumpCommunity(
  WidgetTester tester, {
  required String location,
  required CommunityRepository repository,
  InsightsRepository? insights,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(420, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.community,
        builder: (_, _) => const GroupsScreen(),
      ),
      GoRoute(
        path: AppRoutes.groupFeed,
        builder: (_, state) =>
            GroupFeedScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: AppRoutes.postDetail,
        builder: (_, state) =>
            PostDetailScreen(postId: state.pathParameters['postId']!),
      ),
      GoRoute(
        path: AppRoutes.createPost,
        builder: (_, state) =>
            CreatePostScreen(groupId: state.uri.queryParameters['groupId']),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        communityRepositoryProvider.overrideWithValue(repository),
        insightsRepositoryProvider.overrideWithValue(
          insights ?? fakeInsights(),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return router;
}
