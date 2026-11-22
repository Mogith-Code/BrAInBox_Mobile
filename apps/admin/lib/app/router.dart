import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/analytics/presentation/analytics_screen.dart';
import '../features/auth/application/admin_session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/not_admin_screen.dart';
import '../features/auth/presentation/session_screen.dart';
import '../features/content_review/presentation/content_review_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/knowledge_base/presentation/knowledge_base_screen.dart';
import '../features/mcq_mapping/presentation/mcq_mapping_screen.dart';
import '../features/moderation/presentation/moderation_screen.dart';
import '../features/past_papers/presentation/past_papers_screen.dart';
import '../features/quality_review/presentation/quality_review_screen.dart';
import '../features/question_bank/presentation/edit_question_screen.dart';
import '../features/question_bank/presentation/question_bank_screen.dart';
import '../features/rag_sources/presentation/rag_sources_screen.dart';
import '../features/syllabus_manager/presentation/syllabus_manager_screen.dart';
import '../features/users/presentation/users_screen.dart';
import 'admin_shell.dart';

part 'router.g.dart';

/// Every route in the admin portal.
abstract final class AdminRoutes {
  static const login = '/login'; // Mogith
  static const session = '/session'; // "Checking your account" / error
  static const notAdmin = '/not-admin'; // signed in without the admin role
  static const dashboard = '/dashboard'; // Samni
  static const syllabus = '/syllabus'; // Keshomigha
  static const contentReview = '/content-review'; // Samni
  static const questionBank = '/question-bank'; // Udith
  static const questionEdit = '/question-bank/:questionId'; // Udith
  static String questionEditPath(String id) => '/question-bank/$id';
  static const mcqMapping = '/mcq-mapping'; // Udith
  static String mcqMappingPath(String questionId) => Uri(
    path: mcqMapping,
    queryParameters: {'questionId': questionId},
  ).toString();
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
/// Guard: only signed-in admins can open the pages in the shell (see
/// [adminRedirect]).
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Tells GoRouter to re-run the guard when the user signs in or out.
  final authChanges = ValueNotifier<int>(0);
  ref.listen(adminSessionProvider, (_, _) => authChanges.value++);

  final router = GoRouter(
    initialLocation: AdminRoutes.dashboard,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: authChanges,
    redirect: (context, state) =>
        adminRedirect(ref.read(adminSessionProvider), state.uri),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AdminRoutes.dashboard),
      GoRoute(
        path: AdminRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AdminRoutes.session,
        builder: (context, state) => const SessionScreen(),
      ),
      GoRoute(
        path: AdminRoutes.notAdmin,
        builder: (context, state) => const NotAdminScreen(),
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
            path: AdminRoutes.questionEdit,
            builder: (context, state) => EditQuestionScreen(
              questionId: state.pathParameters['questionId']!,
            ),
          ),
          GoRoute(
            path: AdminRoutes.mcqMapping,
            builder: (context, state) => McqMappingScreen(
              questionId: state.uri.queryParameters['questionId'],
            ),
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

/// The pages that are not inside the admin shell.
const _gatePaths = {
  AdminRoutes.login,
  AdminRoutes.session,
  AdminRoutes.notAdmin,
};

/// Where to go for [uri] in [session], or `null` to stay.
///
/// - checking / failed -> the session page (spinner, or the error + Retry)
/// - signed out -> the login page
/// - signed in without the admin role -> "This account is not an admin"
/// - admin on a gate page -> back where they wanted to go, or the dashboard
///
/// The page the user asked for travels along as `?from=`, so a deep link
/// still opens after signing in.
String? adminRedirect(AdminSession session, Uri uri) {
  final path = uri.path;
  final onGate = _gatePaths.contains(path);
  final from = onGate ? _safeFrom(uri.queryParameters['from']) : uri.toString();

  String gate(String to) => Uri(
    path: to,
    queryParameters: from == null || from == AdminRoutes.dashboard
        ? null
        : {'from': from},
  ).toString();

  return switch (session.status) {
    AdminSessionStatus.checking || AdminSessionStatus.failed =>
      path == AdminRoutes.session ? null : gate(AdminRoutes.session),
    AdminSessionStatus.signedOut =>
      path == AdminRoutes.login ? null : gate(AdminRoutes.login),
    AdminSessionStatus.notAdmin =>
      path == AdminRoutes.notAdmin ? null : AdminRoutes.notAdmin,
    AdminSessionStatus.admin => onGate ? from ?? AdminRoutes.dashboard : null,
  };
}

/// Only an in-app path (`/users?page=2`), never another site or a gate page.
String? _safeFrom(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  return _gatePaths.contains(Uri.parse(from).path) ? null : from;
}
