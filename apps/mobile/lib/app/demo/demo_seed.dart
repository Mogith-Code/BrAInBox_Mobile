import 'dart:convert';

import 'package:flutter/services.dart';

/// Saved AI outputs bundled with the app for demo mode (`DEMO_AI=true`).
///
/// Files live in `assets/demo/`:
/// - `manifest.json`: versions, the real syllabus units and topic codes
///   (copied from the backend's `data/syllabus/learn_biology_2025.json`) and
///   the list of unit files.
/// - `units/u1.json` .. `units/u10.json`: notes, MCQs, written questions,
///   Ask answers, upload summaries and visuals for one unit.
/// - `viva.json`: the polished viva examples and the OCR sample.
///
/// Every item carries `source` (`captured`, `repo` or `authored`) and
/// `reviewed` (only a human may set it to `true`).
class DemoSeed {
  DemoSeed({
    required this.schemaVersion,
    required this.contentVersion,
    required this.units,
    required this.notes,
    required this.mcqs,
    required this.written,
    required this.asks,
    required this.uploads,
    required this.visuals,
    required this.ocr,
  });

  static const manifestPath = 'assets/demo/manifest.json';

  /// The only schema this app version reads.
  static const supportedSchema = 1;

  final int schemaVersion;
  final String contentVersion;
  final List<DemoUnit> units;
  final List<DemoNote> notes;
  final List<DemoMcq> mcqs;
  final List<DemoWritten> written;
  final List<DemoAsk> asks;
  final List<DemoUploadSeed> uploads;
  final List<DemoVisualSeed> visuals;
  final DemoOcrSample ocr;

  /// Loads every demo file from [bundle] (the app's assets).
  static Future<DemoSeed> load(AssetBundle bundle) async {
    Future<Map<String, dynamic>> read(String path) async =>
        jsonDecode(await bundle.loadString(path)) as Map<String, dynamic>;
    final manifest = await read(manifestPath);
    final unitFiles = [
      for (final path in (manifest['unit_files'] as List)) await read('$path'),
    ];
    final viva = await read('${manifest['viva_file']}');
    return DemoSeed.fromJson(manifest, unitFiles, viva);
  }

  factory DemoSeed.fromJson(
    Map<String, dynamic> manifest,
    List<Map<String, dynamic>> unitFiles,
    Map<String, dynamic> viva,
  ) {
    final units = [
      for (final u in (manifest['units'] as List))
        DemoUnit.fromJson(Map<String, dynamic>.from(u as Map)),
    ];
    List<T> all<T>(String key, T Function(Map<String, dynamic>) parse) => [
      for (final file in [...unitFiles, viva])
        for (final item in (file[key] as List? ?? const []))
          parse(Map<String, dynamic>.from(item as Map)),
    ];
    return DemoSeed(
      schemaVersion: (manifest['schema_version'] as num).toInt(),
      contentVersion: '${manifest['content_version']}',
      units: units,
      notes: all('notes', DemoNote.fromJson),
      mcqs: all('mcqs', DemoMcq.fromJson),
      written: all('written', DemoWritten.fromJson),
      asks: all('ask', DemoAsk.fromJson),
      uploads: all('uploads', DemoUploadSeed.fromJson),
      visuals: all('visuals', DemoVisualSeed.fromJson),
      ocr: DemoOcrSample.fromJson(
        Map<String, dynamic>.from(viva['ocr'] as Map),
      ),
    );
  }

  late final Map<String, DemoTopic> topicsByCode = {
    for (final u in units)
      for (final t in u.topics) t.code: t,
  };

  DemoUnit? unit(int number) {
    for (final u in units) {
      if (u.number == number) return u;
    }
    return null;
  }

  /// Every problem with the seed data; empty when it is valid. The seed
  /// tests also parse each item through the app's real models.
  List<String> validate({Set<String> assetPaths = const {}}) {
    final problems = <String>[];
    if (schemaVersion != supportedSchema) {
      problems.add('schema_version $schemaVersion is not $supportedSchema');
    }
    final ids = <String>{};
    void item(DemoItem i) {
      if (!i.id.startsWith('demo-')) {
        problems.add('${i.id}: id must start with "demo-"');
      }
      if (!ids.add(i.id)) problems.add('${i.id}: duplicated id');
      if (!const {'captured', 'repo', 'authored'}.contains(i.source)) {
        problems.add('${i.id}: unknown source "${i.source}"');
      }
      final code = i.topicCode;
      if (code != null && !topicsByCode.containsKey(code)) {
        problems.add('${i.id}: unknown topic code "$code"');
      }
    }

    for (final n in notes) {
      item(n);
      if (n.full.isEmpty || n.short.isEmpty) {
        problems.add('${n.id}: needs full and short blocks');
      }
    }
    for (final q in mcqs) {
      item(q);
      // Case matters: genotypes such as XCXc and XcXc are different options.
      final distinct = q.options.map((o) => o.trim()).toSet();
      if (q.options.length < 4 || distinct.length != q.options.length) {
        problems.add('${q.id}: needs 4-5 different options');
      }
      if (q.answer < 0 || q.answer >= q.options.length) {
        problems.add('${q.id}: answer index ${q.answer} is not an option');
      }
      if (q.explanation.trim().isEmpty) {
        problems.add('${q.id}: missing explanation');
      }
    }
    for (final w in written) {
      item(w);
      if (w.points.isEmpty) problems.add('${w.id}: rubric has no points');
      final total = w.points.fold<double>(0, (s, p) => s + p.marks);
      if ((total - w.marks).abs() > 0.01) {
        problems.add('${w.id}: rubric marks $total != ${w.marks}');
      }
      for (final p in w.points) {
        if (p.keywords.isEmpty) problems.add('${w.id}: point without keywords');
      }
    }
    asks.forEach(item);
    uploads.forEach(item);
    for (final v in visuals) {
      item(v);
      if (assetPaths.isNotEmpty && !assetPaths.contains(v.image)) {
        problems.add('${v.id}: missing image ${v.image}');
      }
    }
    if (assetPaths.isNotEmpty && !assetPaths.contains(ocr.image)) {
      problems.add('ocr: missing image ${ocr.image}');
    }
    return problems;
  }
}

class DemoUnit {
  const DemoUnit({
    required this.number,
    required this.code,
    required this.title,
    required this.topics,
  });

  factory DemoUnit.fromJson(Map<String, dynamic> json) {
    final number = (json['number'] as num).toInt();
    final title = '${json['title']}';
    return DemoUnit(
      number: number,
      code: '${json['code']}',
      title: title,
      topics: [
        for (final t in (json['topics'] as List))
          DemoTopic(
            code: '${(t as Map)['code']}',
            title: '${t['title']}',
            unitNumber: number,
            unitTitle: title,
          ),
      ],
    );
  }

  final int number;
  final String code;
  final String title;
  final List<DemoTopic> topics;
}

class DemoTopic {
  const DemoTopic({
    required this.code,
    required this.title,
    required this.unitNumber,
    required this.unitTitle,
  });

  /// Stable public code, e.g. `bio-6.1` (the backend accepts it as an id).
  final String code;
  final String title;
  final int unitNumber;
  final String unitTitle;
}

/// Fields every seed item has.
abstract class DemoItem {
  String get id;
  String? get topicCode;
  String get source;
  bool get reviewed;
}

/// Shared parsing of the common fields.
class _Meta {
  _Meta(Map<String, dynamic> json)
    : id = '${json['id']}',
      topicCode = json['topic_code'] as String?,
      source = '${json['source'] ?? 'authored'}',
      reviewed = json['reviewed'] == true,
      aliases = _strings(json['aliases']),
      keywords = _strings(json['keywords']);

  final String id;
  final String? topicCode;
  final String source;
  final bool reviewed;
  final List<String> aliases;
  final List<String> keywords;
}

List<String> _strings(Object? value) => [
  for (final v in (value as List? ?? const [])) '$v',
];

List<Map<String, dynamic>> _maps(Object? value) => [
  for (final v in (value as List? ?? const []))
    Map<String, dynamic>.from(v as Map),
];

/// Full and short notes for one topic, as Learn note blocks.
class DemoNote implements DemoItem {
  DemoNote._(this._m, this.full, this.short, this.fullMinutes);

  factory DemoNote.fromJson(Map<String, dynamic> json) => DemoNote._(
    _Meta(json),
    _maps(json['full']),
    _maps(json['short']),
    (json['read_minutes'] as num?)?.toInt() ?? 5,
  );

  final _Meta _m;
  final List<Map<String, dynamic>> full;
  final List<Map<String, dynamic>> short;
  final int fullMinutes;

  @override
  String get id => _m.id;
  @override
  String get topicCode => _m.topicCode!;
  @override
  String get source => _m.source;
  @override
  bool get reviewed => _m.reviewed;
}

class DemoMcq implements DemoItem {
  DemoMcq._(this._m, this.stem, this.options, this.answer, this.explanation);

  factory DemoMcq.fromJson(Map<String, dynamic> json) => DemoMcq._(
    _Meta(json),
    '${json['stem']}',
    _strings(json['options']),
    (json['answer'] as num).toInt(),
    '${json['explanation'] ?? ''}',
  );

  final _Meta _m;
  final String stem;
  final List<String> options;

  /// Index of the one correct option.
  final int answer;
  final String explanation;

  int get unitNumber => int.parse(topicCode.split('-').last.split('.').first);

  @override
  String get id => _m.id;
  @override
  String get topicCode => _m.topicCode!;
  @override
  String get source => _m.source;
  @override
  bool get reviewed => _m.reviewed;
}

class DemoRubricPoint {
  const DemoRubricPoint({
    required this.text,
    required this.marks,
    required this.keywords,
  });

  factory DemoRubricPoint.fromJson(Map<String, dynamic> json) =>
      DemoRubricPoint(
        text: '${json['text']}',
        marks: (json['marks'] as num).toDouble(),
        keywords: _strings(json['keywords']),
      );

  final String text;
  final double marks;

  /// Words or short phrases; a phrase counts when all its words appear.
  final List<String> keywords;
}

/// A structured or essay question with its marking rubric.
class DemoWritten implements DemoItem {
  DemoWritten._(
    this._m,
    this.type,
    this.stem,
    this.marks,
    this.modelAnswer,
    this.points,
    this.samples,
  );

  factory DemoWritten.fromJson(Map<String, dynamic> json) => DemoWritten._(
    _Meta(json),
    '${json['type']}',
    '${json['stem']}',
    (json['marks'] as num).toDouble(),
    '${json['model_answer'] ?? ''}',
    [for (final p in _maps(json['points'])) DemoRubricPoint.fromJson(p)],
    {
      for (final e in Map<String, dynamic>.from(
        json['samples'] as Map? ?? const {},
      ).entries)
        e.key: '${e.value}',
    },
  );

  final _Meta _m;

  /// `structured` or `essay`.
  final String type;
  final String stem;
  final double marks;
  final String modelAnswer;
  final List<DemoRubricPoint> points;

  /// Viva samples: `good`, `partial`, `poor`.
  final Map<String, String> samples;

  int get unitNumber => int.parse(topicCode.split('-').last.split('.').first);

  @override
  String get id => _m.id;
  @override
  String get topicCode => _m.topicCode!;
  @override
  String get source => _m.source;
  @override
  bool get reviewed => _m.reviewed;
}

/// One saved Ask BrAInBox answer.
class DemoAsk implements DemoItem {
  DemoAsk._(this._m, this.question, this.answer, this.sources);

  factory DemoAsk.fromJson(Map<String, dynamic> json) => DemoAsk._(
    _Meta(json),
    '${json['question']}',
    '${json['answer']}',
    _maps(json['sources']),
  );

  final _Meta _m;
  final String question;
  final String answer;

  /// `{title, page?}`; only references that can be checked.
  final List<Map<String, dynamic>> sources;

  List<String> get aliases => _m.aliases;
  List<String> get keywords => _m.keywords;

  @override
  String get id => _m.id;
  @override
  String get topicCode => _m.topicCode!;
  @override
  String get source => _m.source;
  @override
  bool get reviewed => _m.reviewed;
}

/// A saved summary of an uploaded file.
class DemoUploadSeed implements DemoItem {
  DemoUploadSeed._(this._m, this.title, this.summary, this.keyPoints);

  factory DemoUploadSeed.fromJson(Map<String, dynamic> json) =>
      DemoUploadSeed._(
        _Meta(json),
        '${json['title']}',
        '${json['summary']}',
        _strings(json['key_points']),
      );

  final _Meta _m;
  final String title;
  final String summary;
  final List<String> keyPoints;

  List<String> get aliases => _m.aliases;
  List<String> get keywords => _m.keywords;

  @override
  String get id => _m.id;
  @override
  String? get topicCode => _m.topicCode;
  @override
  String get source => _m.source;
  @override
  bool get reviewed => _m.reviewed;
}

/// A bundled visual: a PNG in `assets/demo/visuals/` plus its labels.
class DemoVisualSeed implements DemoItem {
  DemoVisualSeed._(this._m, this.json);

  factory DemoVisualSeed.fromJson(Map<String, dynamic> json) =>
      DemoVisualSeed._(_Meta(json), json);

  final _Meta _m;
  final Map<String, dynamic> json;

  String get title => '${json['title']}';
  String get image => '${json['image']}';
  List<String> get aliases => _m.aliases;
  List<String> get keywords => _m.keywords;

  @override
  String get id => _m.id;
  @override
  String? get topicCode => _m.topicCode;
  @override
  String get source => _m.source;
  @override
  bool get reviewed => _m.reviewed;
}

/// The prepared handwriting sample. Demo OCR always returns [text]; it
/// does not read the photo.
class DemoOcrSample {
  const DemoOcrSample({
    required this.questionId,
    required this.image,
    required this.text,
  });

  factory DemoOcrSample.fromJson(Map<String, dynamic> json) => DemoOcrSample(
    questionId: '${json['question_id']}',
    image: '${json['image']}',
    text: '${json['text']}',
  );

  final String questionId;
  final String image;
  final String text;
}
