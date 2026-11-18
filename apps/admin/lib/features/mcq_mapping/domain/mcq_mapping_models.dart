// MCQ -> misconception mapping (admin).
//
// The question itself (stem, five options, correct answer, explanation,
// unit / topic / concept) is the question bank's `QuestionDetail`
// (`GET / PUT /admin/questions/{id}`), re-exported here. This file adds the
// AI suggestions: `POST /admin/questions/{id}/misconception-suggestions`
// (a MAP_MISCONCEPTIONS job) and `PUT /admin/options/{option_id}/misconception`.
// Backend: `api/modules/questions/schemas.py`.

export '../../question_bank/domain/question_bank_models.dart'
    show
        OptionDraft,
        QuestionDetail,
        QuestionFilter,
        QuestionKind,
        QuestionPage,
        QuestionRow;

/// One AI proposal for one wrong option (`MisconceptionSuggestion`).
/// Nothing is saved until the admin accepts it.
class MisconceptionSuggestion {
  const MisconceptionSuggestion({
    required this.optionId,
    required this.label,
    required this.optionText,
    required this.suggested,
    this.current,
    this.misconceptionId,
    this.isNew = true,
    this.similarity,
  });

  factory MisconceptionSuggestion.fromJson(Map<String, dynamic> json) =>
      MisconceptionSuggestion(
        optionId: '${json['option_id']}',
        label: json['label'] as String? ?? '',
        optionText: json['option_text'] as String? ?? '',
        current: json['current_misconception'] as String?,
        suggested: json['suggested_misconception'] as String? ?? '',
        misconceptionId: json['misconception_id'] == null
            ? null
            : '${json['misconception_id']}',
        isNew: json['is_new'] as bool? ?? true,
        similarity: (json['similarity'] as num?)?.toDouble(),
      );

  final String optionId;

  /// "A".."E".
  final String label;
  final String optionText;

  /// What is linked now, if anything.
  final String? current;
  final String suggested;

  /// Set when the AI reuses a misconception that is already in the bank.
  final String? misconceptionId;
  final bool isNew;

  /// 0-1, how close a reused one is.
  final double? similarity;

  /// The AI proposes what is already linked.
  bool get isUnchanged => (current ?? '').trim() == suggested.trim();
}

/// `OptionMisconceptionOut`: what `PUT /admin/options/{id}/misconception`
/// saved.
class SavedOptionMisconception {
  const SavedOptionMisconception({required this.label, this.misconception});

  factory SavedOptionMisconception.fromJson(Map<String, dynamic> json) =>
      SavedOptionMisconception(
        label: json['label'] as String? ?? '',
        misconception: json['misconception'] as String?,
      );

  final String label;
  final String? misconception;
}

/// What happened to each suggestion in this session.
enum SuggestionDecision { open, accepted, dismissed }

/// The "Suggest with AI" panel.
class SuggestionsState {
  const SuggestionsState({
    this.running = false,
    this.items,
    this.error,
    this.decisions = const {},
    this.saving = const {},
  });

  final bool running;

  /// Null = not asked yet.
  final List<MisconceptionSuggestion>? items;
  final String? error;

  /// By option id.
  final Map<String, SuggestionDecision> decisions;

  /// Option ids being saved right now.
  final Set<String> saving;

  SuggestionDecision decisionOf(MisconceptionSuggestion s) =>
      decisions[s.optionId] ?? SuggestionDecision.open;

  SuggestionsState copyWith({
    bool? running,
    List<MisconceptionSuggestion>? items,
    String? error,
    bool clearError = false,
    Map<String, SuggestionDecision>? decisions,
    Set<String>? saving,
  }) => SuggestionsState(
    running: running ?? this.running,
    items: items ?? this.items,
    error: clearError ? null : error ?? this.error,
    decisions: decisions ?? this.decisions,
    saving: saving ?? this.saving,
  );
}
