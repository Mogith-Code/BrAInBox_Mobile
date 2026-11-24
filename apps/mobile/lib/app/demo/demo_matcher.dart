import 'demo_seed.dart';

/// Picks the saved demo item that best fits what the student typed.
///
/// Prompts are normalised (lower case, no punctuation, simple plurals
/// removed), then scored against each candidate's title, aliases, keywords,
/// topic and unit. A small typo still matches a long word. The same input
/// always gives the same result (ties go to the lowest id).
class DemoMatcher {
  DemoMatcher(DemoSeed seed) : _seed = seed {
    for (final u in seed.units) {
      _lexicon.addAll(tokens(u.title));
      for (final t in u.topics) {
        _lexicon.addAll(tokens(t.title));
      }
    }
    for (final a in seed.asks) {
      _lexicon.addAll(a.keywords.expand(tokens));
    }
    for (final v in seed.visuals) {
      _lexicon.addAll(v.keywords.expand(tokens));
    }
    _lexicon
      ..addAll(_biologyWords.expand(tokens))
      ..removeAll(_notBiologyOnly);
  }

  final DemoSeed _seed;
  final Set<String> _lexicon = {};

  /// Below this a match is "weak": the closest example is shown with a note.
  static const strongScore = 4.0;

  static const closestNote = 'Showing the closest saved example.';

  static final _nonWord = RegExp(r'[^a-z0-9]+');

  /// Lower case words without punctuation, plurals or filler words.
  static List<String> tokens(String text) => [
    for (final raw in text.toLowerCase().split(_nonWord))
      if (raw.isNotEmpty && !_stopWords.contains(raw)) singular(raw),
  ];

  static String normalize(String text) => tokens(text).join(' ');

  /// "cells" -> "cell", "arteries" -> "artery", "glucose" stays.
  static String singular(String word) {
    if (word.length <= 3) return word;
    if (word.endsWith('ies')) return '${word.substring(0, word.length - 3)}y';
    if (word.endsWith('sses') ||
        word.endsWith('xes') ||
        word.endsWith('ches') ||
        word.endsWith('shes')) {
      return word.substring(0, word.length - 2);
    }
    if (word.endsWith('s') &&
        !word.endsWith('ss') &&
        !word.endsWith('us') &&
        !word.endsWith('is')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  /// True when [a] and [b] are the same word or one typo apart (6+ letters,
  /// so short words such as "night" and "light" stay different).
  static bool similar(String a, String b) {
    if (a == b) return true;
    if (a.length < 6 || b.length < 6) return false;
    if ((a.length - b.length).abs() > 1) return false;
    return _distance(a, b) <= 1;
  }

  static int _distance(String a, String b) {
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        cur[j] = [
          prev[j] + 1,
          cur[j - 1] + 1,
          prev[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      prev = cur;
    }
    return prev[b.length];
  }

  /// False when no word of [prompt] is a Biology word.
  bool isBiology(String prompt) {
    final words = tokens(prompt);
    if (words.isEmpty) return false;
    for (final w in words) {
      if (_lexicon.contains(w)) return true;
      if (w.length >= 5 && _lexicon.any((l) => similar(w, l))) return true;
    }
    return false;
  }

  /// Score of one candidate. [topicCode] / [unitNumber] are what the screen
  /// selected, if anything.
  double score(
    String prompt, {
    required String title,
    List<String> aliases = const [],
    List<String> keywords = const [],
    String? candidateTopic,
    String? topicCode,
    int? unitNumber,
  }) {
    final query = tokens(prompt);
    final normal = query.join(' ');
    var total = 0.0;
    if (normal.isNotEmpty &&
        [title, ...aliases].any((t) => normalize(t) == normal)) {
      total += 20;
    }
    final topic = candidateTopic == null
        ? null
        : _seed.topicsByCode[candidateTopic];
    final weighted = <(Set<String>, double)>[
      (keywords.expand(tokens).toSet(), 3),
      ({...tokens(title), ...aliases.expand(tokens)}, 2),
      (topic == null ? <String>{} : tokens(topic.title).toSet(), 1.5),
      (topic == null ? <String>{} : tokens(topic.unitTitle).toSet(), 0.5),
    ];
    for (final word in query.toSet()) {
      var best = 0.0;
      for (final (words, weight) in weighted) {
        if (words.contains(word)) {
          if (weight > best) best = weight;
        } else if (weight / 2 > best && words.any((w) => similar(word, w))) {
          best = weight / 2;
        }
      }
      total += best;
    }
    if (topicCode != null && candidateTopic == topicCode) total += 4;
    if (unitNumber != null && topic?.unitNumber == unitNumber) total += 1.5;
    return total;
  }

  /// The best of [items] for [prompt], or null when [items] is empty.
  DemoMatch<T>? best<T extends DemoItem>(
    String prompt,
    Iterable<T> items, {
    required String Function(T) title,
    List<String> Function(T)? aliases,
    List<String> Function(T)? keywords,
    String? topicCode,
    int? unitNumber,
  }) {
    DemoMatch<T>? top;
    final sorted = items.toList()..sort((a, b) => a.id.compareTo(b.id));
    for (final item in sorted) {
      final s = score(
        prompt,
        title: title(item),
        aliases: aliases?.call(item) ?? const [],
        keywords: keywords?.call(item) ?? const [],
        candidateTopic: item.topicCode,
        topicCode: topicCode,
        unitNumber: unitNumber,
      );
      if (top == null || s > top.score) top = DemoMatch(item, s);
    }
    return top;
  }

  /// The topic whose title best fits [text], for tagging a post.
  DemoTopic? bestTopic(String text, {int? unitNumber}) {
    DemoTopic? top;
    var topScore = 0.0;
    final topics = _seed.topicsByCode.values.toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    for (final t in topics) {
      if (unitNumber != null && t.unitNumber != unitNumber) continue;
      final s = score(
        text,
        title: t.title,
        keywords: [
          for (final a in _seed.asks)
            if (a.topicCode == t.code) ...a.keywords,
        ],
        candidateTopic: t.code,
      );
      if (s > topScore) {
        top = t;
        topScore = s;
      }
    }
    return topScore >= 2 ? top : null;
  }

  static const _stopWords = {
    'a',
    'an',
    'the',
    'of',
    'in',
    'on',
    'and',
    'or',
    'to',
    'for',
    'is',
    'are',
    'was',
    'be',
    'by',
    'with',
    'what',
    'why',
    'how',
    'when',
    'which',
    'who',
    'does',
    'do',
    'did',
    'explain',
    'describe',
    'tell',
    'me',
    'about',
    'please',
    'can',
    'you',
    'i',
    'my',
    'it',
    'its',
    'this',
    'that',
    'these',
    'show',
    'draw',
    'make',
    'diagram',
    'picture',
    'image',
    'visual',
    'give',
    'between',
    'from',
    'into',
    'as',
    'at',
    'their',
    'there',
    'some',
    'any',
  };

  /// Common words that are not a sign of Biology on their own.
  static const _notBiologyOnly = {
    'introduction',
    'nature',
    'scope',
    'challenge',
    'facing',
    'level',
    'form',
    'function',
    'basis',
    'applied',
    'technology',
    'type',
    'role',
    'code',
    'system',
    'structure',
    'human',
    'humanity',
    'world',
    'theory',
    'application',
    'management',
    'problem',
    'global',
    'emerging',
    'origin',
    'analysis',
    'evidence',
    'three',
    'sri',
    'lanka',
    'industry',
    'food',
    'control',
    'handling',
    'technique',
    'chemical',
    'element',
    'energy',
  };

  static const _biologyWords = [
    'cell organelle membrane nucleus mitochondria mitochondrion chloroplast',
    'ribosome enzyme protein carbohydrate lipid nucleic acid dna rna gene',
    'allele chromosome mitosis meiosis photosynthesis respiration glucose',
    'atp plant animal leaf root stem xylem phloem heart blood artery vein',
    'kidney nephron neuron hormone insulin digestion lung breathing gas',
    'ecosystem food chain web population species evolution natural',
    'selection bacteria virus fungi microbe pathogen immunity antibody',
    'vaccine disease organism tissue organ biology living genetic mutation',
    'inheritance mendel dominant recessive genotype phenotype osmosis',
    'diffusion transpiration pollination seed flower fruit reproduction',
    'sperm ovum fertilisation embryo muscle bone skeleton nerve synapse',
    'brain eye ear skin liver pancreas stomach intestine villi transcription',
    'translation codon recombinant plasmid cloning pcr biotechnology',
    'fermentation yeast nitrogen carbon cycle pollution biodiversity',
    'classification taxonomy kingdom fungus algae moss fern gymnosperm',
    'angiosperm insect mammal bird reptile fish amphibian water life',
  ];
}

class DemoMatch<T> {
  const DemoMatch(this.item, this.score);

  final T item;
  final double score;

  bool get strong => score >= DemoMatcher.strongScore;
}
