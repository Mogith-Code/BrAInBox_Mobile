/// Every route in the student app, in one place.
///
/// Use these instead of typing paths:
/// ```dart
/// context.push(AppRoutes.quizSetup);
/// context.push(AppRoutes.unitDetailPath(unit.id));
/// ```
/// When you add a screen: add its path here, register it in `router.dart`,
/// and add it to [catalog] so it shows up in the dev menu.
abstract final class AppRoutes {
  /// DEBUG ONLY: list of every screen (see `dev_menu_screen.dart`).
  static const devMenu = '/dev';

  // Splash (Mogith)
  static const splash = '/';

  // Onboarding (Mogith)
  static const onboarding = '/onboarding';

  // Auth (Mogith)
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const forgotPassword = '/auth/forgot-password';

  /// "Check your inbox" after sign up (verify-email mode).
  static const verifyEmail = '/auth/verify-email';

  /// "Check your inbox" after "Forgot password" (reset mode).
  static const resetCode = '/auth/reset-code';
  static const newPassword = '/auth/new-password';

  // Profile (Mogith)
  static const profileSetup = '/profile/setup';

  // Home (Samni)
  static const home = '/home';

  // Syllabus (Keshomigha)
  static const learn = '/learn';
  static const unitDetail = '/learn/units/:unitId';
  static String unitDetailPath(String unitId) => '/learn/units/$unitId';
  static const topic = '/learn/topics/:topicId';
  static String topicPath(String topicId) => '/learn/topics/$topicId';

  // Notes (Samni)
  static const topicNotes = '/notes/topics/:topicId';
  static String topicNotesPath(String topicId) => '/notes/topics/$topicId';
  static const shortNotes = '/notes/topics/:topicId/short';
  static String shortNotesPath(String topicId) =>
      '/notes/topics/$topicId/short';
  static const notesLibrary = '/notes/library';

  // Upload (Samni)
  static const upload = '/upload';

  // Visuals (Mogith)
  static const visuals = '/visuals';
  static const diagramViewer = '/visuals/view/:visualId';
  static String diagramViewerPath(String visualId) => '/visuals/view/$visualId';
  static const generateVisual = '/visuals/generate';

  // Practice (Udith)
  static const practice = '/practice';
  static const quizSetup = '/practice/setup';
  static const mcqQuestion = '/practice/quiz';
  static const answerFeedback = '/practice/feedback';
  static const quizResult = '/practice/result';
  static const diagnostic = '/practice/diagnostic';

  // Exams (Udith)
  static const pastPapers = '/exams';
  static const generatePaper = '/exams/generate';
  static const examAttempt = '/exams/attempt/:paperId';
  static String examAttemptPath(String paperId) => '/exams/attempt/$paperId';

  // Evaluation (Keshomigha)
  static const typedAnswer = '/evaluation/typed/:questionId';
  static String typedAnswerPath(String questionId) =>
      '/evaluation/typed/$questionId';
  static const handwrittenUpload = '/evaluation/handwritten/:questionId';
  static String handwrittenUploadPath(String questionId) =>
      '/evaluation/handwritten/$questionId';
  static const ocrPreview = '/evaluation/ocr-preview';
  static const evaluationFeedback = '/evaluation/feedback/:evaluationId';
  static String evaluationFeedbackPath(String evaluationId) =>
      '/evaluation/feedback/$evaluationId';

  // Insights (Keshomigha)
  static const insights = '/insights';
  static const heatmap = '/insights/heatmap';
  static const mistakeJournal = '/insights/mistakes';

  // Recommendations (Udith)
  static const nextSteps = '/recommendations';
  static const studyPlan = '/recommendations/study-plan';
  static const reassessment = '/recommendations/reassessment';

  // Community (Mogith)
  static const community = '/community';
  static const groupFeed = '/community/groups/:groupId';
  static String groupFeedPath(String groupId) => '/community/groups/$groupId';
  static const postDetail = '/community/posts/:postId';
  static String postDetailPath(String postId) => '/community/posts/$postId';
  static const createPost = '/community/create';

  // Notifications (Samni)
  static const notifications = '/notifications';

  // Settings (Samni)
  static const settings = '/settings';

  /// Routes a signed-OUT student may stay on (used by the redirect).
  static const signedOutRoutes = {
    onboarding,
    login,
    signup,
    forgotPassword,
    resetCode,
    newPassword,
  };

  /// The diagnostic screens (open while the diagnostic isn't done yet).
  static const diagnosticRoutes = {diagnostic};

  /// Every screen with a sample path. Used by the dev menu and router test.
  static final List<({String title, String owner, String path})> catalog = [
    (title: 'Splash', owner: 'Mogith', path: splash),
    (title: 'Onboarding', owner: 'Mogith', path: onboarding),
    (title: 'Log in', owner: 'Mogith', path: login),
    (title: 'Sign up', owner: 'Mogith', path: signup),
    (title: 'Forgot password', owner: 'Mogith', path: forgotPassword),
    (title: 'Check your inbox', owner: 'Mogith', path: verifyEmail),
    (title: 'Check your inbox (reset)', owner: 'Mogith', path: resetCode),
    (title: 'Set a new password', owner: 'Mogith', path: newPassword),
    (title: 'Profile setup', owner: 'Mogith', path: profileSetup),
    (title: 'Home', owner: 'Samni', path: home),
    (title: 'Learn', owner: 'Keshomigha', path: learn),
    (title: 'Unit detail', owner: 'Keshomigha', path: unitDetailPath('demo')),
    (title: 'Topic', owner: 'Keshomigha', path: topicPath('demo')),
    (title: 'Topic notes', owner: 'Samni', path: topicNotesPath('demo')),
    (title: 'Short notes', owner: 'Samni', path: shortNotesPath('demo')),
    (title: 'Notes library', owner: 'Samni', path: notesLibrary),
    (title: 'Upload notes', owner: 'Samni', path: upload),
    (title: 'Diagrams', owner: 'Mogith', path: visuals),
    (title: 'Diagram viewer', owner: 'Mogith', path: diagramViewerPath('demo')),
    (title: 'Generate visual', owner: 'Mogith', path: generateVisual),
    (title: 'Practice', owner: 'Udith', path: practice),
    (title: 'Quiz setup', owner: 'Udith', path: quizSetup),
    (title: 'MCQ question', owner: 'Udith', path: mcqQuestion),
    (title: 'Answer feedback', owner: 'Udith', path: answerFeedback),
    (title: 'Quiz result', owner: 'Udith', path: quizResult),
    (title: 'Diagnostic test', owner: 'Udith', path: diagnostic),
    (title: 'Past papers', owner: 'Udith', path: pastPapers),
    (title: 'Generate model paper', owner: 'Udith', path: generatePaper),
    (title: 'Exam mode', owner: 'Udith', path: examAttemptPath('demo')),
    (title: 'Typed answer', owner: 'Keshomigha', path: typedAnswerPath('demo')),
    (
      title: 'Handwritten answer',
      owner: 'Keshomigha',
      path: handwrittenUploadPath('demo'),
    ),
    (title: 'OCR preview', owner: 'Keshomigha', path: ocrPreview),
    (
      title: 'Answer feedback',
      owner: 'Keshomigha',
      path: evaluationFeedbackPath('demo'),
    ),
    (title: 'Insights', owner: 'Keshomigha', path: insights),
    (title: 'Heatmap', owner: 'Keshomigha', path: heatmap),
    (title: 'Mistake journal', owner: 'Keshomigha', path: mistakeJournal),
    (title: 'Next steps', owner: 'Udith', path: nextSteps),
    (title: 'Study plan', owner: 'Udith', path: studyPlan),
    (title: 'Reassessment', owner: 'Udith', path: reassessment),
    (title: 'Community', owner: 'Mogith', path: community),
    (title: 'Group feed', owner: 'Mogith', path: groupFeedPath('demo')),
    (title: 'Post', owner: 'Mogith', path: postDetailPath('demo')),
    (title: 'Create post', owner: 'Mogith', path: createPost),
    (title: 'Notifications', owner: 'Samni', path: notifications),
    (title: 'Settings', owner: 'Samni', path: settings),
  ];
}
