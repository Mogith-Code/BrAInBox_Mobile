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
  /// Profile setup: onboarding, or an edit with `?edit=all|goals|availability`
  /// (full screen, e.g. from My profile opened on Home).
  static const profileSetup = '/profile/setup';
  static String profileEditPath([String section = 'all']) =>
      _withQuery(profileSetup, {'edit': section});

  /// My profile: stats, achievements and goal (Figma F1), full screen
  /// (opened from the avatar on Home).
  static const myProfile = '/profile';

  // Home (Samni)
  static const home = '/home';

  // Syllabus (Keshomigha) - Learn tab navigation (Samni)
  static const learn = '/learn';
  static const unitDetail = '/learn/unit/:unitId';
  static String unitDetailPath(String unitId) => '/learn/unit/$unitId';
  static const unitTopic = '/learn/unit/:unitId/topic/:topicId';
  static String unitTopicPath(String unitId, String topicId) =>
      '/learn/unit/$unitId/topic/$topicId';

  /// A topic when only its id is known (e.g. links from Home).
  /// Same screen as [unitTopic].
  static const topic = '/learn/topic/:topicId';
  static String topicPath(String topicId) => '/learn/topic/$topicId';

  // Notes (Samni)
  static const topicNotes = '/notes/topics/:topicId';
  static String topicNotesPath(String topicId) => '/notes/topics/$topicId';
  static const shortNotes = '/notes/topics/:topicId/short';
  static String shortNotesPath(String topicId) =>
      '/notes/topics/$topicId/short';

  /// "My library" (B14), inside the Learn tab.
  static const notesLibrary = '/learn/library';

  // Upload (Samni) - "My uploaded notes", inside the Learn tab.
  static const uploads = '/learn/uploads';
  static const uploadDetail = '/learn/uploads/:uploadId';
  static String uploadDetailPath(String uploadId) => '/learn/uploads/$uploadId';

  /// Old path, kept as a redirect to [uploads].
  static const upload = '/learn/upload';

  // Visuals (Mogith)
  /// "My visuals": generate a visual about anything (no topic needed) and
  /// see the ones made on this phone.
  static const myVisuals = '/visuals';
  static const visuals = '/visuals/topics/:topicId';
  static String visualsPath(String topicId) => '/visuals/topics/$topicId';
  static const diagramViewer = '/visuals/view/:visualId';
  static String diagramViewerPath(String visualId) => '/visuals/view/$visualId';

  /// Generate a visual from ANY screen. Both parts are optional:
  /// `topicId` saves it under that topic, `prompt` fills in the question,
  /// e.g. `context.push(AppRoutes.generateVisualPath(prompt: 'Krebs cycle'))`.
  static const generateVisual = '/visuals/generate';
  static String generateVisualPath({String? topicId, String? prompt}) =>
      _withQuery(generateVisual, {'topicId': topicId, 'prompt': prompt});

  // Visuals opened from the Learn tab - full screen.
  // `new` is registered before `:visualId` so it isn't read as an id.
  static const learnVisualNew = '/learn/visual/new';
  static String learnVisualNewPath({String? topicId}) =>
      _withQuery(learnVisualNew, {'topicId': topicId});
  static const learnVisual = '/learn/visual/:visualId';
  static String learnVisualPath(String visualId) => '/learn/visual/$visualId';

  /// [path] plus the non-empty [query] values (none -> just [path]).
  static String _withQuery(String path, Map<String, String?> query) {
    final params = {
      for (final e in query.entries)
        if (e.value != null && e.value!.trim().isNotEmpty) e.key: e.value!,
    };
    return params.isEmpty
        ? path
        : Uri(path: path, queryParameters: params).toString();
  }

  // Ask BrAInBox (AI tutor) - full screen.
  static const ask = '/ask';

  /// `/ask` or `/ask?topicId=...`
  static String askPath({String? topicId}) => Uri(
    path: ask,
    queryParameters: topicId == null ? null : {'topicId': topicId},
  ).toString();

  // Practice (Udith)
  static const practice = '/practice';
  static const quizSetup = '/practice/setup';

  /// Quiz setup for one topic. [mode]: `quick` (10 MCQs) or `weak`.
  /// `mistakes` re-asks questions answered wrongly; [conceptId] limits the
  /// quiz to one concept (from a recommendation).
  static String quizSetupPath({
    String? topicId,
    String? mode,
    String? conceptId,
  }) => _withQuery(quizSetup, {
    'topicId': topicId,
    'mode': mode,
    'conceptId': conceptId,
  });
  static const mcqQuestion = '/practice/quiz';
  static String mcqQuestionPath(String quizId) =>
      _withQuery(mcqQuestion, {'quizId': quizId});
  static const answerFeedback = '/practice/feedback';
  static const quizResult = '/practice/result';
  static String quizResultPath(String quizId) =>
      _withQuery(quizResult, {'quizId': quizId});

  // Diagnostic (Udith) - full screen, outside the bottom nav.
  static const diagnostic = '/diagnostic';
  static const diagnosticQuestions = '/diagnostic/questions';
  static const diagnosticResult = '/diagnostic/result';

  // Exams (Udith)
  static const pastPapers = '/exams';
  static const generatePaper = '/exams/generate';
  static const examAttempt = '/exams/attempt/:paperId';
  static String examAttemptPath(String paperId, {bool hideOutdated = false}) =>
      '/exams/attempt/$paperId${hideOutdated ? '?hide_outdated=true' : ''}';
  static const examResult = '/exams/result';

  // Evaluation (Keshomigha)
  /// Structured and essay questions to practise.
  static const writtenQuestions = '/evaluation';
  static const typedAnswer = '/evaluation/typed/:questionId';
  static String typedAnswerPath(String questionId) =>
      '/evaluation/typed/$questionId';
  static const handwrittenUpload = '/evaluation/handwritten/:questionId';
  static String handwrittenUploadPath(String questionId) =>
      '/evaluation/handwritten/$questionId';
  static const ocrPreview = '/evaluation/ocr-preview';
  static String ocrPreviewPath(String evaluationId) =>
      _withQuery(ocrPreview, {'evaluationId': evaluationId});
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
  static String reassessmentPath(String recommendationId) =>
      _withQuery(reassessment, {'id': recommendationId});

  // Community (Mogith)
  static const community = '/community';
  static const groupFeed = '/community/groups/:groupId';
  static String groupFeedPath(String groupId) => '/community/groups/$groupId';
  static const postDetail = '/community/posts/:postId';
  static String postDetailPath(String postId) => '/community/posts/$postId';
  static const createPost = '/community/create';
  static String createPostPath(String groupId) =>
      _withQuery(createPost, {'groupId': groupId});

  // Notifications (Samni)
  static const notifications = '/notifications';

  // Settings (Samni) - the Settings tab. Its pages open on top inside the
  // tab, so the bottom bar stays.
  static const settings = '/settings';
  static const privacy = '/settings/privacy';

  /// My profile inside the Settings tab (same screen as [myProfile]).
  static const settingsProfile = '/settings/profile';

  /// Profile setup in edit mode inside the Settings tab.
  /// `?edit=all|goals|availability`.
  static const settingsEditProfile = '/settings/edit-profile';
  static String settingsEditProfilePath([String section = 'all']) =>
      _withQuery(settingsEditProfile, {'edit': section});

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
  static const diagnosticRoutes = {
    diagnostic,
    diagnosticQuestions,
    diagnosticResult,
  };

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
    (title: 'My profile', owner: 'Mogith', path: myProfile),
    (title: 'Edit profile', owner: 'Mogith', path: profileSetup),
    (title: 'Home', owner: 'Samni', path: home),
    (title: 'Learn', owner: 'Keshomigha', path: learn),
    (title: 'Unit detail', owner: 'Keshomigha', path: unitDetailPath('unit-6')),
    (
      title: 'Topic',
      owner: 'Keshomigha',
      path: unitTopicPath('unit-6', 't-mendelian'),
    ),
    (
      title: 'Topic (by id)',
      owner: 'Keshomigha',
      path: topicPath('t-dihybrid'),
    ),
    (title: 'Topic notes', owner: 'Samni', path: topicNotesPath('t-mendelian')),
    (title: 'Short notes', owner: 'Samni', path: shortNotesPath('t-mendelian')),
    (title: 'Notes library', owner: 'Samni', path: notesLibrary),
    (title: 'My uploaded notes', owner: 'Samni', path: uploads),
    (title: 'Upload detail', owner: 'Samni', path: uploadDetailPath('demo')),
    // The Diagrams gallery and viewers need real ids: open them from a topic
    // (Learn -> unit -> topic -> Diagrams).
    (title: 'My visuals', owner: 'Mogith', path: myVisuals),
    (title: 'Generate a visual', owner: 'Mogith', path: generateVisual),
    (title: 'New visual (Learn)', owner: 'Mogith', path: learnVisualNew),
    (title: 'Ask BrAInBox', owner: 'TBD', path: ask),
    (title: 'Practice', owner: 'Udith', path: practice),
    (title: 'Quiz setup', owner: 'Udith', path: quizSetup),
    (title: 'MCQ question', owner: 'Udith', path: mcqQuestion),
    (title: 'Answer feedback', owner: 'Udith', path: answerFeedback),
    (title: 'Quiz result', owner: 'Udith', path: quizResult),
    (title: "Let's find your starting point", owner: 'Udith', path: diagnostic),
    (title: 'Diagnostic question', owner: 'Udith', path: diagnosticQuestions),
    (title: 'Your starting point', owner: 'Udith', path: diagnosticResult),
    (title: 'Past papers', owner: 'Udith', path: pastPapers),
    (title: 'Generate model paper', owner: 'Udith', path: generatePaper),
    (title: 'Exam mode', owner: 'Udith', path: examAttemptPath('demo')),
    (title: 'Exam result', owner: 'Udith', path: examResult),
    (title: 'Written practice', owner: 'Keshomigha', path: writtenQuestions),
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
    (title: 'Data & privacy', owner: 'Samni', path: privacy),
    (title: 'My profile (Settings)', owner: 'Mogith', path: settingsProfile),
    (
      title: 'Edit profile (Settings)',
      owner: 'Mogith',
      path: settingsEditProfile,
    ),
  ];
}
