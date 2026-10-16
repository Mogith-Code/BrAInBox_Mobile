import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';
import '../features/community/presentation/create_post_screen.dart';
import '../features/community/presentation/group_feed_screen.dart';
import '../features/community/presentation/groups_screen.dart';
import '../features/community/presentation/post_detail_screen.dart';
import '../features/evaluation/presentation/evaluation_feedback_screen.dart';
import '../features/evaluation/presentation/handwritten_upload_screen.dart';
import '../features/evaluation/presentation/ocr_preview_screen.dart';
import '../features/evaluation/presentation/typed_answer_screen.dart';
import '../features/exams/presentation/exam_attempt_screen.dart';
import '../features/exams/presentation/generate_paper_screen.dart';
import '../features/exams/presentation/past_papers_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/insights/presentation/heatmap_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/insights/presentation/mistake_journal_screen.dart';
import '../features/notes/presentation/library_screen.dart';
import '../features/notes/presentation/short_notes_screen.dart';
import '../features/notes/presentation/topic_notes_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/practice/presentation/answer_feedback_screen.dart';
import '../features/practice/presentation/diagnostic_screen.dart';
import '../features/practice/presentation/mcq_question_screen.dart';
import '../features/practice/presentation/practice_hub_screen.dart';
import '../features/practice/presentation/quiz_result_screen.dart';
import '../features/practice/presentation/quiz_setup_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/recommendations/presentation/next_steps_screen.dart';
import '../features/recommendations/presentation/reassessment_screen.dart';
import '../features/recommendations/presentation/study_plan_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/syllabus/presentation/syllabus_screen.dart';
import '../features/syllabus/presentation/topic_screen.dart';
import '../features/syllabus/presentation/unit_detail_screen.dart';
import '../features/upload/presentation/upload_screen.dart';
import '../features/visuals/presentation/diagram_gallery_screen.dart';
import '../features/visuals/presentation/diagram_viewer_screen.dart';
import '../features/visuals/presentation/generate_visual_screen.dart';
import 'dev_menu_screen.dart';
import 'routes.dart';
import 'shell_scaffold.dart';

part 'router.g.dart';

/// The app's router (go_router).
///
/// - Screens inside the [StatefulShellRoute] show the bottom navigation bar.
/// - Other screens open full-screen on top of it.
/// - The auth guard (see [_authRedirect]) sends signed-out users to login.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Tells GoRouter to re-run the redirect when the user signs in or out.
  final authChanges = ValueNotifier<int>(0);
  ref.listen(currentUserProvider, (_, _) => authChanges.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: authChanges,
    redirect: (context, state) => _authRedirect(ref, state),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.topicNotes,
        builder: (context, state) =>
            TopicNotesScreen(topicId: state.pathParameters['topicId']!),
      ),
      GoRoute(
        path: AppRoutes.shortNotes,
        builder: (context, state) =>
            ShortNotesScreen(topicId: state.pathParameters['topicId']!),
      ),
      GoRoute(
        path: AppRoutes.notesLibrary,
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: AppRoutes.upload,
        builder: (context, state) => const UploadScreen(),
      ),
      GoRoute(
        path: AppRoutes.visuals,
        builder: (context, state) => const DiagramGalleryScreen(),
      ),
      GoRoute(
        path: AppRoutes.diagramViewer,
        builder: (context, state) =>
            DiagramViewerScreen(visualId: state.pathParameters['visualId']!),
      ),
      GoRoute(
        path: AppRoutes.generateVisual,
        builder: (context, state) => const GenerateVisualScreen(),
      ),
      GoRoute(
        path: AppRoutes.pastPapers,
        builder: (context, state) => const PastPapersScreen(),
      ),
      GoRoute(
        path: AppRoutes.generatePaper,
        builder: (context, state) => const GeneratePaperScreen(),
      ),
      GoRoute(
        path: AppRoutes.examAttempt,
        builder: (context, state) =>
            ExamAttemptScreen(paperId: state.pathParameters['paperId']!),
      ),
      GoRoute(
        path: AppRoutes.typedAnswer,
        builder: (context, state) =>
            TypedAnswerScreen(questionId: state.pathParameters['questionId']!),
      ),
      GoRoute(
        path: AppRoutes.handwrittenUpload,
        builder: (context, state) => HandwrittenUploadScreen(
          questionId: state.pathParameters['questionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.ocrPreview,
        builder: (context, state) => const OcrPreviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.evaluationFeedback,
        builder: (context, state) => EvaluationFeedbackScreen(
          evaluationId: state.pathParameters['evaluationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.nextSteps,
        builder: (context, state) => const NextStepsScreen(),
      ),
      GoRoute(
        path: AppRoutes.studyPlan,
        builder: (context, state) => const StudyPlanScreen(),
      ),
      GoRoute(
        path: AppRoutes.reassessment,
        builder: (context, state) => const ReassessmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.devMenu,
        builder: (context, state) => const DevMenuScreen(),
      ),

      // Bottom navigation: Home, Learn, Practice, Insights, Community.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          // Tab: /home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Tab: /learn
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.learn,
                builder: (context, state) => const SyllabusScreen(),
              ),
              GoRoute(
                path: AppRoutes.unitDetail,
                builder: (context, state) =>
                    UnitDetailScreen(unitId: state.pathParameters['unitId']!),
              ),
              GoRoute(
                path: AppRoutes.topic,
                builder: (context, state) =>
                    TopicScreen(topicId: state.pathParameters['topicId']!),
              ),
            ],
          ),
          // Tab: /practice
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.practice,
                builder: (context, state) => const PracticeHubScreen(),
              ),
              GoRoute(
                path: AppRoutes.quizSetup,
                builder: (context, state) => const QuizSetupScreen(),
              ),
              GoRoute(
                path: AppRoutes.mcqQuestion,
                builder: (context, state) => const McqQuestionScreen(),
              ),
              GoRoute(
                path: AppRoutes.answerFeedback,
                builder: (context, state) => const AnswerFeedbackScreen(),
              ),
              GoRoute(
                path: AppRoutes.quizResult,
                builder: (context, state) => const QuizResultScreen(),
              ),
              GoRoute(
                path: AppRoutes.diagnostic,
                builder: (context, state) => const DiagnosticScreen(),
              ),
            ],
          ),
          // Tab: /insights
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.insights,
                builder: (context, state) => const InsightsScreen(),
              ),
              GoRoute(
                path: AppRoutes.heatmap,
                builder: (context, state) => const HeatmapScreen(),
              ),
              GoRoute(
                path: AppRoutes.mistakeJournal,
                builder: (context, state) => const MistakeJournalScreen(),
              ),
            ],
          ),
          // Tab: /community
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.community,
                builder: (context, state) => const GroupsScreen(),
              ),
              GoRoute(
                path: AppRoutes.groupFeed,
                builder: (context, state) =>
                    GroupFeedScreen(groupId: state.pathParameters['groupId']!),
              ),
              GoRoute(
                path: AppRoutes.postDetail,
                builder: (context, state) =>
                    PostDetailScreen(postId: state.pathParameters['postId']!),
              ),
              GoRoute(
                path: AppRoutes.createPost,
                builder: (context, state) => const CreatePostScreen(),
              ),
            ],
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
String? _authRedirect(Ref ref, GoRouterState state) {
  // The guard is OFF when Firebase is not configured (nobody could sign in)
  // or when running with --dart-define=DISABLE_AUTH_GUARD=true (debug only).
  if (!FirebaseSetup.isReady || Env.disableAuthGuard) return null;

  final user = ref.read(currentUserProvider);
  if (user.isLoading) return null; // still checking - stay where we are

  final signedIn = user.value != null;
  final location = state.matchedLocation;
  final isPublic = AppRoutes.publicRoutes.contains(location);

  if (!signedIn && !isPublic) return AppRoutes.login;
  if (signedIn &&
      (location == AppRoutes.login || location == AppRoutes.signup)) {
    return AppRoutes.home;
  }
  // TODO(mogith): send unverified users to AppRoutes.verifyEmail and users
  // without a profile to AppRoutes.profileSetup.
  return null;
}
