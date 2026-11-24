import 'demo_matcher.dart';
import 'demo_seed.dart';

/// How one rubric point did.
class DemoPointMark {
  const DemoPointMark({
    required this.point,
    required this.status,
    required this.marksAwarded,
    required this.matched,
  });

  final DemoRubricPoint point;

  /// `covered`, `partial` or `missing` (the backend's values).
  final String status;
  final double marksAwarded;
  final List<String> matched;
}

/// Marks a written answer against a seed rubric by keyword and concept
/// coverage. Formative only, like the real marking.
abstract final class DemoMarker {
  /// Answers shorter than this get no marks.
  static const minWords = 3;

  static List<DemoPointMark> mark(DemoWritten question, String answer) {
    final words = DemoMatcher.tokens(answer);
    final tooShort = words.length < minWords;
    return [
      for (final point in question.points)
        _markPoint(point, words.toSet(), tooShort: tooShort),
    ];
  }

  static DemoPointMark _markPoint(
    DemoRubricPoint point,
    Set<String> words, {
    required bool tooShort,
  }) {
    final matched = tooShort
        ? const <String>[]
        : [
            for (final k in point.keywords)
              if (_hasPhrase(k, words)) k,
          ];
    final ratio = point.keywords.isEmpty
        ? 0.0
        : matched.length / point.keywords.length;
    final (status, awarded) = ratio >= 0.6
        ? ('covered', point.marks)
        : ratio >= 0.25
        ? ('partial', _half(point.marks))
        : ('missing', 0.0);
    return DemoPointMark(
      point: point,
      status: status,
      marksAwarded: awarded,
      matched: matched,
    );
  }

  /// Half marks, rounded down to the nearest 0.5.
  static double _half(double marks) => marks.floorToDouble() / 2;

  /// A phrase counts when every one of its words is in the answer
  /// (a one-letter typo in a long word is allowed).
  static bool _hasPhrase(String phrase, Set<String> words) {
    final parts = DemoMatcher.tokens(phrase);
    if (parts.isEmpty) return false;
    return parts.every(
      (p) => words.contains(p) || words.any((w) => DemoMatcher.similar(p, w)),
    );
  }

  static double total(List<DemoPointMark> marks) =>
      marks.fold(0, (sum, m) => sum + m.marksAwarded);
}
