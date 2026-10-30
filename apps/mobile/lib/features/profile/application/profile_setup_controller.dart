import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/session_controller.dart';
import '../data/profile_repository.dart';
import '../domain/profile_models.dart';

part 'profile_setup_controller.g.dart';

/// Everything the 3 setup steps show. The draft values stay here while the
/// student moves back and forth between steps.
class ProfileSetupState {
  const ProfileSetupState({
    required this.options,
    this.step = 0,
    this.stream,
    this.subject,
    this.examYear,
    this.targetGrade,
    this.confidence = 50,
    this.studyDays = const {},
    this.hoursPerDay = 2,
    this.preferredTime,
    this.saving = false,
    this.error,
  });

  final ProfileOptions options;

  /// 0, 1 or 2 (shown as "1/3" ... "3/3").
  final int step;

  // Step 1 - what are you studying?
  final String? stream;
  final String? subject;

  // Step 2 - set your goal
  final int? examYear;
  final String? targetGrade;
  final int confidence; // 0 - 100

  // Step 3 - when can you study?
  final Set<String> studyDays;
  final double hoursPerDay;
  final String? preferredTime;

  final bool saving;
  final String? error;

  static const steps = 3;

  bool get stepComplete => switch (step) {
    0 => stream != null && subject != null,
    1 => examYear != null && targetGrade != null,
    _ => studyDays.isNotEmpty && preferredTime != null,
  };

  /// Computed live: days x hours.
  double get weeklyHours => studyDays.length * hoursPerDay;

  ProfileSetupState copyWith({
    int? step,
    String? stream,
    String? subject,
    int? examYear,
    String? targetGrade,
    int? confidence,
    Set<String>? studyDays,
    double? hoursPerDay,
    String? preferredTime,
    bool? saving,
    String? error,
    bool clearError = false,
  }) => ProfileSetupState(
    options: options,
    step: step ?? this.step,
    stream: stream ?? this.stream,
    subject: subject ?? this.subject,
    examYear: examYear ?? this.examYear,
    targetGrade: targetGrade ?? this.targetGrade,
    confidence: confidence ?? this.confidence,
    studyDays: studyDays ?? this.studyDays,
    hoursPerDay: hoursPerDay ?? this.hoursPerDay,
    preferredTime: preferredTime ?? this.preferredTime,
    saving: saving ?? this.saving,
    error: clearError ? null : (error ?? this.error),
  );

  /// The fields of the current step, as `PATCH /profile` expects them.
  Map<String, dynamic> get stepFields => switch (step) {
    0 => {'stream': stream, 'subject': subject},
    1 => {
      'exam_year': examYear,
      'target_grade': targetGrade,
      'confidence': confidence,
    },
    _ => {
      'study_days': [
        for (final d in const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'])
          if (studyDays.contains(d)) d,
      ],
      'hours_per_day': hoursPerDay,
      'preferred_time': preferredTime,
    },
  };
}

/// Profile setup (3 steps): loads the options and the saved profile, starts
/// at the first incomplete step, saves each step with `PATCH /profile` and
/// finishes with `POST /profile/complete`.
@riverpod
class ProfileSetupController extends _$ProfileSetupController {
  @override
  Future<ProfileSetupState> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    final (options, profile) = await (repo.options(), repo.profile()).wait;
    return _fromSaved(options, profile);
  }

  static ProfileSetupState _fromSaved(ProfileOptions options, Profile p) {
    // Sensible defaults when nothing is saved yet: the only stream, the
    // first available subject, and next year's exam if it's offered.
    final firstSubject = options.subjects
        .where((s) => s.available)
        .map((s) => s.id)
        .firstOrNull;
    final nextYear = DateTime.now().year + 1;
    final defaultYear = options.examYears.contains(nextYear)
        ? nextYear
        : options.examYears.firstOrNull;

    final state = ProfileSetupState(
      options: options,
      stream:
          p.stream ??
          (options.streams.length == 1 ? options.streams.first.id : null),
      subject: p.subject ?? firstSubject,
      examYear: p.examYear ?? defaultYear,
      targetGrade: p.targetGrade,
      confidence: p.confidence ?? 50,
      studyDays: p.studyDays.toSet(),
      hoursPerDay: p.hoursPerDay ?? 2,
      preferredTime: p.preferredTime,
    );

    // Resume at the first step that isn't saved yet.
    final savedStep1 = p.stream != null && p.subject != null;
    final savedStep2 =
        p.examYear != null && p.targetGrade != null && p.confidence != null;
    final step = !savedStep1 ? 0 : (!savedStep2 ? 1 : 2);
    return state.copyWith(step: step);
  }

  ProfileSetupState? get _current => state.value;

  void _update(ProfileSetupState Function(ProfileSetupState s) change) {
    final s = _current;
    if (s == null || s.saving) return;
    state = AsyncData(change(s).copyWith(clearError: true));
  }

  // ---- edits (kept in memory until Continue) ----
  void selectStream(String id) => _update((s) => s.copyWith(stream: id));

  void selectSubject(SubjectOption subject) {
    if (!subject.available) return; // "Coming soon" can't be picked
    _update((s) => s.copyWith(subject: subject.id));
  }

  void setExamYear(int year) => _update((s) => s.copyWith(examYear: year));
  void setTargetGrade(String g) => _update((s) => s.copyWith(targetGrade: g));
  void setConfidence(int v) => _update((s) => s.copyWith(confidence: v));
  void setStudyDays(Set<String> d) => _update((s) => s.copyWith(studyDays: d));
  void setHoursPerDay(double h) => _update((s) => s.copyWith(hoursPerDay: h));
  void setPreferredTime(String id) =>
      _update((s) => s.copyWith(preferredTime: id));

  /// Back arrow: previous step, values kept. Returns false on step 1.
  bool back() {
    final s = _current;
    if (s == null || s.step == 0) return false;
    _update((s) => s.copyWith(step: s.step - 1));
    return true;
  }

  /// Continue / Finish setup: saves this step; on the last step also
  /// completes the profile and refreshes the session (the router then goes
  /// to "Let's find your starting point"). Returns true when finished.
  Future<bool> next() async {
    final s = _current;
    if (s == null || s.saving || !s.stepComplete) return false;
    final repo = ref.read(profileRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    final isLast = s.step == ProfileSetupState.steps - 1;

    state = AsyncData(s.copyWith(saving: true, clearError: true));
    try {
      await repo.update(s.stepFields);
      if (isLast) {
        await repo.complete();
        await session.refresh();
      }
      if (!ref.mounted) return isLast;
      state = AsyncData(
        s.copyWith(saving: false, step: isLast ? s.step : s.step + 1),
      );
      return isLast;
    } catch (e) {
      if (ref.mounted) {
        state = AsyncData(
          s.copyWith(saving: false, error: ErrorMessages.of(e)),
        );
      }
      return false;
    }
  }
}
