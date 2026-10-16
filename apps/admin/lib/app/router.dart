import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/analytics/presentation/analytics_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/content_review/presentation/content_review_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/knowledge_base/presentation/knowledge_base_screen.dart';
import '../features/mcq_mapping/presentation/mcq_mapping_screen.dart';
import '../features/moderation/presentation/moderation_screen.dart';
import '../features/past_papers/presentation/past_papers_screen.dart';
import '../features/quality_review/presentation/quality_review_screen.dart';
import '../features/question_bank/presentation/question_bank_screen.dart';
import '../features/rag_sources/presentation/rag_sources_screen.dart';
import '../features/syllabus_manager/presentation/syllabus_manager_screen.dart';
import '../features/users/presentation/users_screen.dart';
import 'admin_shell.dart';

part 'router.g.dart';

/// Every route in the admin portal.
abstract final class AdminRoutes {
  static const login = '/login'; // Mogith
  static const dashboard = '/dashboard'; // Samni
  static const syllabus = '/syllabus'; // Keshomigha
  static const contentReview = '/content-review'; // Samni
  static const questionBank = '/question-bank'; // Udith
  static const mcqMapping = '/mcq-mapping'; // Udith
  static const qualityReview = '/quality-review'; // Udith
  static const pastPapers = '/past-papers'; // Udith
  static const knowledgeBase = '/knowledge-base'; // Keshomigha
  static const ragSources = '/rag-sources'; // Samni
  static const moderation = '/moderation'; // Mogith
  static const users = '/users'; // Mogith
  static const analytics = '/analytics'; // Keshomigha
}

/// The admin portal router.
///
/// Guard: only signed-in users with role "admin" can open pages other than
/// the login page (see [_adminGuard]).
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Tells GoRouter to re-run the guard when the user signs in or out.
  final authChanges = ValueNotifier<int>(0);
  ref.listen(currentUserProvider, (_, _) => authChanges.value++);

  final router = GoRouter(
    initialLocation: AdminRoutes.dashboard,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: authChanges,
    redirect: (context, state) => _adminGuard(ref, state),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AdminRoutes.dashboard),
      GoRoute(
        path: AdminRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      // Every page below is shown inside the sidebar + top bar layout.
      ShellRoute(
        builder: (context, state, child) =>
            AdminShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AdminRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AdminRoutes.syllabus,
            builder: (context, state) => const SyllabusManagerScreen(),
          ),
          GoRoute(
            path: AdminRoutes.contentReview,
            builder: (context, state) => const ContentReviewScreen(),
          ),
          GoRoute(
            path: AdminRoutes.questionBank,
            builder: (context, state) => const QuestionBankScreen(),
          ),
          GoRoute(
            path: AdminRoutes.mcqMapping,
            builder: (context, state) => const McqMappingScreen(),
          ),
          GoRoute(
            path: AdminRoutes.qualityReview,
            builder: (context, state) => const QualityReviewScreen(),
          ),
          GoRoute(
            path: AdminRoutes.pastPapers,
            builder: (context, state) => const PastPapersScreen(),
          ),
          GoRoute(
            path: AdminRoutes.knowledgeBase,
            builder: (context, state) => const KnowledgeBaseScreen(),
          ),
          GoRoute(
            path: AdminRoutes.ragSources,
            builder: (context, state) => const RagSourcesScreen(),
          ),
          GoRoute(
            path: AdminRoutes.moderation,
            builder: (context, state) => const ModerationScreen(),
          ),
          GoRoute(
            path: AdminRoutes.users,
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: AdminRoutes.analytics,
            builder: (context, state) => const AnalyticsScreen(),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authChanges.dispose();
  });
  return router;
}

/// Returns a path to redirect to, or `null` to stay.
String? _adminGuard(Ref ref, GoRouterState state) {
  // The guard is OFF when Firebase is not configured (nobody could sign in)
  // or when running with --dart-define=DISABLE_AUTH_GUARD=true (debug only).
  if (!FirebaseSetup.isReady || Env.disableAuthGuard) return null;

  final user = ref.read(currentUserProvider);
  if (user.isLoading) return null; // still checking

  final isAdmin = user.value?.isAdmin ?? false;
  final onLogin = state.matchedLocation == AdminRoutes.login;

  // Signed out, or signed in WITHOUT the admin role -> login page.
  // TODO(mogith): show "This account is not an admin" on the login page.
  if (!isAdmin) return onLogin ? null : AdminRoutes.login;
  if (onLogin) return AdminRoutes.dashboard;
  return null;
}
