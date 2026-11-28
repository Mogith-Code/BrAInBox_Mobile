import 'package:dio/dio.dart';

import 'demo_marker.dart';
import 'demo_matcher.dart';
import 'demo_seed.dart';

/// How long demo work "takes". Tests use [DemoTiming.instant].
class DemoTiming {
  const DemoTiming({
    this.job = const Duration(seconds: 4),
    this.reply = const Duration(seconds: 3),
    this.now = DateTime.now,
  });

  static const instant = DemoTiming(job: Duration.zero, reply: Duration.zero);

  /// A job goes queued -> running -> finished over this time.
  final Duration job;

  /// Wait before a direct AI answer (Ask BrAInBox, topic suggestion).
  final Duration reply;
  final DateTime Function() now;
}

/// What the interceptor should do with one request.
sealed class DemoAction {
  const DemoAction();
}

/// Answer the request here, without the network.
class DemoServe extends DemoAction {
  const DemoServe(this.status, [this.data]);

  DemoServe.error(this.status, String code, String message)
    : data = {
        'error': {'code': code, 'message': message},
      };

  final int status;
  final Object? data;
}

/// Send the request to the real backend.
class DemoPass extends DemoAction {
  const DemoPass({this.body, this.merge, this.fallback});

  /// A new request body (used to stop a real route from starting AI work).
  final Object? body;

  /// Adds demo items to the real reply.
  final Object? Function(Object? data)? merge;

  /// Used when the real request fails; null keeps the real error.
  final DemoServe? Function()? fallback;
}

/// Reads a real, non-AI backend route (e.g. a topic's code). Returns null
/// when it fails.
typedef DemoRealGet = Future<Map<String, dynamic>?> Function(String path);

/// The in-memory demo backend for every AI route of the student app.
///
/// It answers from [DemoSeed] and keeps what the student makes (jobs,
/// papers, evaluations, uploads, visuals, notes) in memory only, so a
/// restart gives a clean demo. Every id it makes starts with `demo-`.
class DemoEngine {
  DemoEngine(this.seed, {this.timing = const DemoTiming()})
    : matcher = DemoMatcher(seed);

  final DemoSeed seed;
  final DemoTiming timing;
  final DemoMatcher matcher;

  /// Set by the app once the [Dio] exists. Without it, topic ids that are
  /// not codes cannot be resolved and the closest example is used.
  DemoRealGet? realGet;

  /// Objects made or changed here. The offline cache never stores them.
  final Expando<bool> _made = Expando('demo');

  bool isDemoData(Object? value) =>
      value is Map || value is List ? _made[value!] == true : false;

  T _mark<T extends Object>(T value) {
    _made[value] = true;
    return value;
  }

  int _counter = 0;
  String _id(String kind) => 'demo-$kind-${++_counter}';

  final Map<String, _DemoJob> _jobs = {};
  final Map<String, Map<String, dynamic>> _papers = {};
  final Map<String, Map<String, int>> _paperKeys = {};
  final Map<String, _DemoEvaluation> _evaluations = {};
  final Map<String, _DemoUpload> _uploads = {};
  final Map<String, Map<String, dynamic>> _visuals = {};
  final Map<String, List<String>> _visualsByTopic = {};
  final Map<String, Map<String, dynamic>> _notes = {}; // "ref|type" -> note
  final Map<String, ({int attempts, double best})> _writtenStats = {};
  final Map<String, String> _codeOfRef = {}; // topic uuid -> bio-6.1
  final Map<String, String> _uuidOfCode = {};
  int _paperCount = 0;

  static final _topicCode = RegExp(r'^bio-\d+\.\d+$');
  static const notFoundAnswer =
      "I couldn't find this in the approved Biology notes. "
      'Try asking in a different way, or ask your teacher.';
  static const notBiologyVisual = 'I can only draw Biology visuals.';

  // ------------------------------------------------------------------ routing

  /// Decides what happens to [options]. Never throws for a bad body: it
  /// answers with the same error codes as the real API instead.
  Future<DemoAction> handle(RequestOptions options) async {
    final method = options.method.toUpperCase();
    final path = options.path.split('?').first;
    final body = options.data is Map
        ? Map<String, dynamic>.from(options.data as Map)
        : const <String, dynamic>{};
    final query = options.queryParameters;
    final seg = path.split('/').where((s) => s.isNotEmpty).toList();
    bool at(String m, List<String?> pattern) {
      if (m != method || seg.length != pattern.length) return false;
      for (var i = 0; i < pattern.length; i++) {
        if (pattern[i] != null && pattern[i] != seg[i]) return false;
      }
      return true;
    }

    String last(int i) => seg[seg.length - i];
    bool demo(String id) => id.startsWith('demo-');

    // Learn
    if (at('POST', ['learn', 'ask'])) return _ask(body);
    if (at('POST', ['learn', 'topics', null, 'notes', 'generate'])) {
      return _generateNotes(seg[2], body);
    }
    if (at('GET', ['learn', 'jobs', null]) && demo(last(1))) {
      return _learnJob(last(1));
    }
    if (at('GET', ['learn', 'topics', null, 'notes'])) {
      final note = _notes['${seg[2]}|${query['type'] ?? 'full'}'];
      if (note != null) return DemoServe(200, _mark(_copy(note)));
      return const DemoPass();
    }
    if (at('GET', ['learn', 'topics', null])) return _topicDetail(seg[2]);
    if (at('POST', ['learn', 'uploads'])) return _createUpload(options.data);
    if (at('GET', ['learn', 'uploads'])) return _listUploads();
    if (at('GET', ['learn', 'uploads', null]) && demo(last(1))) {
      return _uploadDetail(last(1));
    }
    if (at('POST', ['learn', 'uploads', null, 'save-to-short-notes']) &&
        demo(seg[2])) {
      return _saveUpload(seg[2], body);
    }
    if (at('DELETE', ['learn', 'uploads', null]) && demo(last(1))) {
      _uploads.remove(last(1));
      return const DemoServe(204);
    }

    // Visuals
    if (at('POST', ['visuals', 'generate'])) return _generateVisual(body);
    if (at('GET', ['visuals', null]) && demo(last(1))) {
      final v = _visuals[last(1)];
      return v == null
          ? DemoServe.error(404, 'VISUAL_NOT_FOUND', 'Visual not found.')
          : DemoServe(200, _mark(_copy(v)));
    }
    if (at('POST', ['visuals', null, 'report']) && demo(seg[1])) {
      return const DemoServe(204);
    }
    if (at('GET', ['topics', null, 'visuals'])) return _topicVisuals(seg[1]);

    // AI jobs
    if (at('GET', ['jobs', null]) && demo(last(1))) return _aiJob(last(1));

    // Papers
    if (at('POST', ['papers', 'generate'])) return _generatePaper(body);
    if (at('GET', ['papers', null]) && demo(last(1))) {
      final p = _papers[last(1)];
      return p == null
          ? DemoServe.error(404, 'PAPER_NOT_FOUND', 'Paper not found.')
          : DemoServe(200, _mark(_copy(p)));
    }
    if (at('POST', ['papers', null, 'submit'])) {
      return demo(seg[1]) ? _submitPaper(seg[1], body) : _realSubmit(body);
    }

    // Evaluation
    if (at('GET', ['evaluations', 'questions'])) {
      return _writtenQuestions(query['question_type'] as String?);
    }
    if (at('GET', ['questions', null]) && demo(last(1))) {
      return _questionStem(last(1));
    }
    if (at('POST', ['evaluations'])) return _evaluate(body);
    if (at('GET', ['evaluations', null]) && demo(last(1))) {
      final e = _evaluations[last(1)];
      return e == null
          ? DemoServe.error(404, 'EVALUATION_NOT_FOUND', 'Answer not found.')
          : DemoServe(200, _mark(_evaluationJson(e)));
    }
    if (at('POST', ['evaluations', 'pages'])) {
      final count = options.data is FormData
          ? (options.data as FormData).files.length
          : 1;
      return DemoServe(
        201,
        _mark({
          'image_paths': [
            for (var i = 0; i < (count == 0 ? 1 : count); i++) _id('page'),
          ],
          'pages': count == 0 ? 1 : count,
        }),
      );
    }
    if (at('POST', ['evaluations', 'ocr'])) return _ocr(body);

    // Community
    if (at('POST', ['posts', 'suggest-topic'])) return _suggestTopic(body);

    // Anything else that mentions a demo id must never reach the backend.
    if (path.contains('demo-') || _mentionsDemo(options.data)) {
      return DemoServe.error(
        404,
        'NOT_FOUND',
        'This demo item is no longer available. Please make it again.',
      );
    }
    return const DemoPass();
  }

  /// Learns topic codes from real replies (`{id, code: "bio-6.1"}`).
  void observe(Object? data, [int depth = 0]) {
    if (depth > 4) return;
    if (data is Map) {
      final id = data['id'];
      final code = data['code'];
      if (id is String && code is String && _topicCode.hasMatch(code)) {
        _codeOfRef[id] = code;
        _uuidOfCode[code] = id;
      }
      for (final v in data.values) {
        if (v is Map || v is List) observe(v, depth + 1);
      }
    } else if (data is List) {
      for (final v in data.take(200)) {
        observe(v, depth + 1);
      }
    }
  }

  bool _mentionsDemo(Object? data) => switch (data) {
    final String s => s.startsWith('demo-'),
    final Map<dynamic, dynamic> m => m.values.any(_mentionsDemo),
    final List<dynamic> l => l.any(_mentionsDemo),
    _ => false,
  };

  // ------------------------------------------------------------------ helpers

  Future<void> _wait() => timing.reply == Duration.zero
      ? Future<void>.value()
      : Future<void>.delayed(timing.reply);

  String _now() => timing.now().toUtc().toIso8601String();

  static Map<String, dynamic> _copy(Map<String, dynamic> m) =>
      Map<String, dynamic>.from(m);

  /// The seed topic for a topic id or code, asking the real (non-AI)
  /// backend for the code when only the id is known.
  Future<DemoTopic?> _topic(String? ref) async {
    if (ref == null || ref.isEmpty) return null;
    if (_topicCode.hasMatch(ref)) return seed.topicsByCode[ref];
    final known = _codeOfRef[ref];
    if (known != null) return seed.topicsByCode[known];
    final json = await realGet?.call('/learn/topics/$ref');
    if (json != null) observe(json);
    final code = _codeOfRef[ref];
    return code == null ? null : seed.topicsByCode[code];
  }

  /// The real id of a topic code (null when the backend can't be asked).
  Future<String?> _uuid(String code) async {
    final known = _uuidOfCode[code];
    if (known != null) return known;
    final json = await realGet?.call('/learn/topics/$code');
    if (json != null) observe(json);
    return _uuidOfCode[code];
  }

  /// A job that ends in [result], or fails with [error] / [errorCode].
  _DemoJob _newJob(
    String type,
    Map<String, dynamic>? result, {
    String? error,
    String? errorCode,
  }) {
    final job = _DemoJob(
      id: _id('job'),
      type: type,
      createdAt: timing.now(),
      result: result,
      errorCode: errorCode,
      error: error,
    );
    _jobs[job.id] = job;
    return job;
  }

  /// 0 = queued, 1 = running, 2 = finished.
  int _stage(DateTime createdAt) {
    final total = timing.job.inMilliseconds;
    if (total <= 0) return 2;
    final elapsed = timing.now().difference(createdAt).inMilliseconds;
    if (elapsed >= total) return 2;
    return elapsed < total ~/ 4 ? 0 : 1;
  }

  double _progress(DateTime createdAt) {
    final total = timing.job.inMilliseconds;
    if (total <= 0) return 1;
    final elapsed = timing.now().difference(createdAt).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  // -------------------------------------------------------------------- learn

  Future<DemoAction> _ask(Map<String, dynamic> body) async {
    final question = '${body['question'] ?? ''}'.trim();
    if (question.length < 3) {
      return DemoServe.error(
        422,
        'VALIDATION_ERROR',
        'Type a longer question.',
      );
    }
    await _wait();
    if (!matcher.isBiology(question)) {
      return DemoServe(
        200,
        _mark({'answer': notFoundAnswer, 'grounded': false, 'sources': []}),
      );
    }
    final topic = await _topic(body['topic_id'] as String?);
    final match = matcher.best(
      question,
      seed.asks,
      title: (a) => a.question,
      aliases: (a) => a.aliases,
      keywords: (a) => a.keywords,
      topicCode: topic?.code,
      unitNumber: topic?.unitNumber,
    );
    if (match == null) {
      return DemoServe(
        200,
        _mark({'answer': notFoundAnswer, 'grounded': false, 'sources': []}),
      );
    }
    final a = match.item;
    return DemoServe(
      200,
      _mark({
        'answer': match.strong
            ? a.answer
            : '${a.answer}\n\n${DemoMatcher.closestNote}',
        'grounded': true,
        'sources': [for (final s in a.sources) Map<String, dynamic>.from(s)],
      }),
    );
  }

  Future<DemoAction> _generateNotes(
    String ref,
    Map<String, dynamic> body,
  ) async {
    final type = body['type'] == 'short' ? 'short' : 'full';
    final topic = await _topic(ref);
    var note = topic == null
        ? null
        : seed.notes.where((n) => n.topicCode == topic.code).firstOrNull;
    var closest = false;
    if (note == null) {
      closest = true;
      final match = matcher.best(
        topic?.title ?? ref,
        seed.notes,
        title: (n) => seed.topicsByCode[n.topicCode]?.title ?? '',
        unitNumber: topic?.unitNumber,
      );
      note = match?.item;
    }
    if (note == null) {
      return DemoServe.error(404, 'TOPIC_NOT_FOUND', 'Topic not found.');
    }
    final blocks = [
      if (closest) {'type': 'paragraph', 'text': DemoMatcher.closestNote},
      ...(type == 'short' ? note.short : note.full),
    ];
    final noteId = _id('note');
    final json = <String, dynamic>{
      'id': noteId,
      'topic_id': ref,
      'type': type,
      'depth': body['depth'] ?? 'standard',
      'title': seed.topicsByCode[note.topicCode]?.title ?? 'Notes',
      'blocks': blocks,
      'read_minutes': type == 'short' ? 2 : note.fullMinutes,
      'ai_generated': true,
      'is_own': true,
      'created_at': _now(),
    };
    _notes['$ref|$type'] = json;
    final job = _newJob('notes', {'result_id': noteId})..topicRef = ref;
    return DemoServe(202, _mark({'job_id': job.id, 'status': 'queued'}));
  }

  DemoAction _learnJob(String id) {
    final job = _jobs[id];
    if (job == null) {
      return DemoServe.error(404, 'JOB_NOT_FOUND', 'Job not found.');
    }
    final stage = _stage(job.createdAt);
    return DemoServe(
      200,
      _mark({
        'id': job.id,
        'kind': job.type,
        'status': const ['queued', 'running', 'done'][stage],
        'topic_id': job.topicRef,
        'result_id': stage == 2 ? (job.result?['result_id']) : null,
        'error': null,
        'error_code': null,
        'cached': false,
        'created_at': job.createdAt.toUtc().toIso8601String(),
        'started_at': stage > 0 ? _now() : null,
        'finished_at': stage == 2 ? _now() : null,
      }),
    );
  }

  DemoAction _topicDetail(String ref) {
    final full = _notes.containsKey('$ref|full');
    final short = _notes.containsKey('$ref|short');
    if (!full && !short) return const DemoPass();
    return DemoPass(
      merge: (data) {
        if (data is! Map) return data;
        return _mark({
          ...Map<String, dynamic>.from(data),
          if (full) 'has_full_notes': true,
          if (short) 'has_short_notes': true,
        });
      },
    );
  }

  Future<DemoAction> _createUpload(Object? data) async {
    var fileName = 'notes.pdf';
    String? topicRef;
    var length = 'medium';
    if (data is FormData) {
      if (data.files.isNotEmpty) {
        fileName = data.files.first.value.filename ?? fileName;
      }
      for (final f in data.fields) {
        if (f.key == 'topic_id') topicRef = f.value;
        if (f.key == 'summary_length') length = f.value;
      }
    }
    final topic = await _topic(topicRef);
    final match = matcher.best(
      fileName.replaceAll(RegExp(r'\.[a-z0-9]+$', caseSensitive: false), ''),
      seed.uploads,
      title: (u) => u.title,
      aliases: (u) => u.aliases,
      keywords: (u) => u.keywords,
      topicCode: topic?.code,
      unitNumber: topic?.unitNumber,
    );
    final picked = match!.item;
    final upload = _DemoUpload(
      id: _id('upload'),
      fileName: fileName,
      topicRef: topicRef,
      seedItem: picked,
      closest: !match.strong && topic?.code != picked.topicCode,
      length: length,
      createdAt: timing.now(),
    );
    _uploads[upload.id] = upload;
    return DemoServe(
      202,
      _mark({'upload_id': upload.id, 'job_id': _id('job'), 'status': 'queued'}),
    );
  }

  Map<String, dynamic> _uploadJson(_DemoUpload u, {bool detail = false}) {
    final stage = _stage(u.createdAt);
    final done = stage == 2;
    final summary = u.closest
        ? '${DemoMatcher.closestNote}\n\n${u.seedItem.summary}'
        : u.seedItem.summary;
    return {
      'id': u.id,
      'file_name': u.fileName,
      'mime_type': u.fileName.toLowerCase().endsWith('.pdf')
          ? 'application/pdf'
          : null,
      'size_bytes': null,
      'topic_id': u.topicRef,
      'status': const ['queued', 'running', 'done'][stage],
      'summary_length': u.length,
      'summary': done ? summary : null,
      'key_points': done ? u.seedItem.keyPoints : <String>[],
      'error': null,
      'created_at': u.createdAt.toUtc().toIso8601String(),
      if (detail) 'extracted_text': null,
    };
  }

  DemoAction _listUploads() {
    if (_uploads.isEmpty) return const DemoPass();
    List<Map<String, dynamic>> mine() => [
      for (final u in _uploads.values.toList().reversed) _uploadJson(u),
    ];
    return DemoPass(
      merge: (data) {
        if (data is! Map) return data;
        final items = [...mine(), ...(data['items'] as List? ?? const [])];
        return _mark({
          ...Map<String, dynamic>.from(data),
          'items': items,
          'total': ((data['total'] as num?)?.toInt() ?? 0) + _uploads.length,
        });
      },
      fallback: () => DemoServe(
        200,
        _mark({
          'items': mine(),
          'total': _uploads.length,
          'page': 1,
          'size': 20,
        }),
      ),
    );
  }

  DemoAction _uploadDetail(String id) {
    final u = _uploads[id];
    return u == null
        ? DemoServe.error(404, 'UPLOAD_NOT_FOUND', 'Upload not found.')
        : DemoServe(200, _mark(_uploadJson(u, detail: true)));
  }

  Future<DemoAction> _saveUpload(String id, Map<String, dynamic> body) async {
    final u = _uploads[id];
    if (u == null) {
      return DemoServe.error(404, 'UPLOAD_NOT_FOUND', 'Upload not found.');
    }
    final refs = <String>{?u.topicRef, ?(body['topic_id'] as String?)};
    final code = u.seedItem.topicCode;
    if (refs.isEmpty && code != null) {
      refs.add(code);
      final uuid = await _uuid(code);
      if (uuid != null) refs.add(uuid);
    }
    final note = <String, dynamic>{
      'id': _id('note'),
      'topic_id': refs.isEmpty ? null : refs.first,
      'type': 'short',
      'depth': null,
      'title': u.seedItem.title,
      'blocks': [
        {'type': 'paragraph', 'text': u.seedItem.summary},
        {'type': 'bullet_list', 'items': u.seedItem.keyPoints},
      ],
      'read_minutes': 2,
      'ai_generated': true,
      'is_own': true,
      'created_at': _now(),
    };
    for (final ref in refs) {
      _notes['$ref|short'] = note;
    }
    return DemoServe(201, _mark(_copy(note)));
  }

  // ------------------------------------------------------------------ visuals

  Future<DemoAction> _generateVisual(Map<String, dynamic> body) async {
    final prompt = '${body['prompt'] ?? ''}'.trim();
    if (prompt.length < 3) {
      return DemoServe.error(
        422,
        'VALIDATION_ERROR',
        'Describe the visual in a few more words.',
      );
    }
    if (!matcher.isBiology(prompt)) {
      final job = _newJob(
        'generate_visual',
        null,
        error: notBiologyVisual,
        errorCode: 'NOT_BIOLOGY',
      );
      return DemoServe(202, _mark({'job_id': job.id}));
    }
    final topicRef = body['topic_id'] as String?;
    final topic = await _topic(topicRef);
    final match = matcher.best(
      prompt,
      seed.visuals,
      title: (v) => v.title,
      aliases: (v) => v.aliases,
      keywords: (v) => v.keywords,
      topicCode: topic?.code,
      unitNumber: topic?.unitNumber,
    )!;
    final s = match.item;
    final id = _id('visual');
    final visual = <String, dynamic>{
      'id': id,
      'title': match.strong
          ? s.title
          : '${s.title} (${DemoMatcher.closestNote.toLowerCase()})',
      'topic_id': topicRef,
      'concept_id': null,
      'kind': s.json['kind'] ?? 'diagram',
      'image_url': 'asset://${s.image.replaceFirst('assets/', '')}',
      'mermaid_code': null,
      'alt_text': s.json['alt_text'],
      'labels': s.json['labels'] ?? const [],
      'style': body['style'] ?? s.json['style'],
      'width': s.json['width'],
      'height': s.json['height'],
      'is_ai_generated': true,
      'is_verified': false,
      'created_at': _now(),
    };
    _visuals[id] = visual;
    if (topicRef != null) (_visualsByTopic[topicRef] ??= []).insert(0, id);
    final job = _newJob('generate_visual', {'visual_id': id});
    return DemoServe(202, _mark({'job_id': job.id}));
  }

  DemoAction _topicVisuals(String ref) {
    final ids = _visualsByTopic[ref];
    if (ids == null || ids.isEmpty) return const DemoPass();
    List<Map<String, dynamic>> mine() => [
      for (final id in ids)
        if (_visuals[id] != null) _copy(_visuals[id]!),
    ];
    return DemoPass(
      merge: (data) {
        if (data is! Map) return data;
        return _mark({
          ...Map<String, dynamic>.from(data),
          'visuals': [...mine(), ...(data['visuals'] as List? ?? const [])],
        });
      },
      fallback: () {
        final code = _topicCode.hasMatch(ref) ? ref : _codeOfRef[ref];
        final topic = code == null ? null : seed.topicsByCode[code];
        if (topic == null) return null;
        return DemoServe(
          200,
          _mark({
            'topic_id': ref,
            'topic_title': topic.title,
            'unit_code': '${topic.unitNumber}',
            'unit_title': topic.unitTitle,
            'visuals': mine(),
          }),
        );
      },
    );
  }

  DemoAction _aiJob(String id) {
    final job = _jobs[id];
    if (job == null) {
      return DemoServe.error(404, 'JOB_NOT_FOUND', 'Job not found.');
    }
    final stage = _stage(job.createdAt);
    final failed = stage == 2 && job.error != null;
    final status = stage < 2
        ? const ['queued', 'running'][stage]
        : (failed ? 'failed' : 'succeeded');
    return DemoServe(
      200,
      _mark({
        'id': job.id,
        'job_type': job.type,
        'status': status,
        'progress': stage == 2 ? 1.0 : _progress(job.createdAt),
        'result': stage == 2 && !failed ? job.result : null,
        'error': failed ? job.error : null,
        'error_code': failed ? job.errorCode : null,
        'created_at': job.createdAt.toUtc().toIso8601String(),
        'finished_at': stage == 2 ? _now() : null,
      }),
    );
  }

  // ------------------------------------------------------------------- papers

  DemoAction _generatePaper(Map<String, dynamic> body) {
    final units = [
      for (final u in (body['unit_numbers'] as List? ?? const []))
        if (u is num) u.toInt(),
    ];
    if (units.isEmpty) {
      return DemoServe.error(
        422,
        'VALIDATION_ERROR',
        'Pick at least one unit.',
      );
    }
    int count(String key) => (body[key] as num?)?.toInt() ?? 0;
    final wanted = {
      'mcq': count('mcq_count'),
      'structured': count('structured_count'),
      'essay': count('essay_count'),
    };
    final offset = _paperCount++;
    final warnings = <String>[];
    final questions = <Map<String, dynamic>>[];
    final key = <String, int>{};

    List<T> spread<T extends DemoItem>(List<T> pool, int n) {
      // Round-robin over the chosen units, so every unit is used.
      final byUnit = {
        for (final u in units)
          u: pool.where((q) => _unitOf(q.topicCode) == u).toList()
            ..sort((a, b) => a.id.compareTo(b.id)),
      };
      for (final list in byUnit.values) {
        if (list.isEmpty) continue;
        final shift = (offset * 7) % list.length;
        final rotated = [...list.skip(shift), ...list.take(shift)];
        list
          ..clear()
          ..addAll(rotated);
      }
      final out = <T>[];
      var i = 0;
      while (out.length < n && byUnit.values.any((l) => i < l.length)) {
        for (final list in byUnit.values) {
          if (out.length < n && i < list.length) out.add(list[i]);
        }
        i++;
      }
      return out;
    }

    final mcqs = spread(seed.mcqs, wanted['mcq']!);
    final structured = spread(
      seed.written.where((w) => w.type == 'structured').toList(),
      wanted['structured']!,
    );
    final essays = spread(
      seed.written.where((w) => w.type == 'essay').toList(),
      wanted['essay']!,
    );
    for (final (label, got, want) in [
      ('MCQ', mcqs.length, wanted['mcq']!),
      ('structured', structured.length, wanted['structured']!),
      ('essay', essays.length, wanted['essay']!),
    ]) {
      if (got < want) {
        warnings.add(
          'Only $got of $want $label questions are saved for these units, '
          'so the paper is shorter.',
        );
      }
    }
    var position = 1;
    for (final q in mcqs) {
      key[q.id] = q.answer;
      questions.add({
        'id': q.id,
        'position': position++,
        'question_type': 'mcq',
        'stem': q.stem,
        'topic_id': null,
        'topic': _topicLabel(q.topicCode),
        'marks': 1,
        'options': [
          for (var i = 0; i < q.options.length; i++)
            {'label': String.fromCharCode(65 + i), 'text': q.options[i]},
        ],
        'is_outdated': false,
      });
    }
    for (final w in [...structured, ...essays]) {
      questions.add({
        'id': w.id,
        'position': position++,
        'question_type': w.type,
        'stem': w.stem,
        'topic_id': null,
        'topic': _topicLabel(w.topicCode),
        'marks': w.marks.round(),
        'options': const <Object>[],
        'is_outdated': false,
      });
    }
    if (questions.isEmpty) {
      final job = _newJob(
        'build_paper',
        null,
        error: 'No saved questions match these units.',
        errorCode: 'NOT_ENOUGH_QUESTIONS',
      );
      return DemoServe(
        202,
        _mark({'job_id': job.id, 'from_bank': 0, 'to_generate': 0}),
      );
    }
    final paperId = _id('paper');
    final title = '${body['title'] ?? ''}'.trim().isNotEmpty
        ? '${body['title']}'.trim()
        : 'Model paper: ${[for (final u in units) seed.unit(u)?.title ?? 'Unit $u'].join(', ')}';
    final totalMarks = questions.fold<int>(
      0,
      (s, q) => s + (q['marks'] as int),
    );
    _papers[paperId] = {
      'id': paperId,
      'title': title,
      'paper_type': 'ai_generated',
      'year': null,
      'duration_minutes':
          (body['time_limit_minutes'] as num?)?.toInt() ??
          (mcqs.length * 1.5 + structured.length * 10 + essays.length * 20)
              .round(),
      'total_marks': totalMarks,
      'hidden_outdated': 0,
      'questions': questions,
    };
    _paperKeys[paperId] = key;
    final job = _newJob('build_paper', {
      'paper_id': paperId,
      'title': title,
      'total_questions': questions.length,
      'from_bank': 0,
      'generated': questions.length,
      'warnings': warnings,
    });
    return DemoServe(
      202,
      _mark({
        'job_id': job.id,
        'from_bank': 0,
        'to_generate': questions.length,
      }),
    );
  }

  int _unitOf(String? code) =>
      code == null ? 0 : int.parse(code.split('-').last.split('.').first);

  String _topicLabel(String? code) {
    final t = code == null ? null : seed.topicsByCode[code];
    return t == null ? 'Biology' : 'Unit ${t.unitNumber}: ${t.title}';
  }

  DemoAction _submitPaper(String paperId, Map<String, dynamic> body) {
    final paper = _papers[paperId];
    final key = _paperKeys[paperId];
    if (paper == null || key == null) {
      return DemoServe.error(404, 'PAPER_NOT_FOUND', 'Paper not found.');
    }
    final answers = {
      for (final a in (body['answers'] as List? ?? const []))
        if (a is Map) '${a['question_id']}': Map<String, dynamic>.from(a),
    };
    final results = <Map<String, dynamic>>[];
    final topicStats = <String, List<int>>{};
    var correct = 0, answered = 0, marks = 0, writtenTotal = 0;
    var writtenMarks = 0.0;
    for (final q in (paper['questions'] as List).cast<Map<String, dynamic>>()) {
      final id = q['id'] as String;
      final topic = q['topic'] as String;
      final answer = answers[id];
      if (q['question_type'] == 'mcq') {
        final options = (q['options'] as List).cast<Map<String, dynamic>>();
        final letter = answer?['selected'] as String?;
        final index = letter == null || letter.isEmpty
            ? -1
            : letter.codeUnitAt(0) - 65;
        final selected = index >= 0 && index < options.length
            ? options[index]['text'] as String
            : null;
        final right = index == key[id];
        if (selected != null) answered++;
        if (right) {
          correct++;
          marks++;
        }
        final stats = topicStats.putIfAbsent(topic, () => [0, 0]);
        stats[1]++;
        if (right) stats[0]++;
        final mcq = seed.mcqs.firstWhere((m) => m.id == id);
        results.add({
          'question_id': id,
          'topic': topic,
          'question': q['stem'],
          'selected_option': selected,
          'correct_answer': options[key[id]!]['text'],
          'is_correct': right,
          'marks_awarded': right ? 1 : 0,
          'explanation': right ? null : mcq.explanation,
        });
      } else {
        final w = seed.written.firstWhere((x) => x.id == id);
        final text = '${answer?['answer_text'] ?? ''}'.trim();
        if (text.isNotEmpty) answered++;
        final got = DemoMarker.total(DemoMarker.mark(w, text));
        writtenMarks += got;
        writtenTotal += w.marks.round();
        results.add({
          'question_id': id,
          'topic': topic,
          'question': q['stem'],
          'selected_option': text.isEmpty ? null : text,
          'correct_answer': w.modelAnswer,
          'is_correct': got >= w.marks * 0.5,
          'marks_awarded': got.round(),
          'explanation':
              'Estimated ${_fmt(got)} / ${_fmt(w.marks)} marks from the '
              'saved marking points.',
        });
      }
    }
    final byTopic = [
      for (final e in topicStats.entries)
        {
          'topic': e.key,
          'correct': e.value[0],
          'total': e.value[1],
          'percent': (1000 * e.value[0] / e.value[1]).round() / 10,
        },
    ];
    final marksTotal = paper['total_marks'] as int;
    final obtained = marks + writtenMarks.round();
    return DemoServe(
      200,
      _mark({
        'paper_id': paperId,
        'attempt_id': _id('attempt'),
        'status': 'graded',
        'total_questions': results.length,
        'answered': answered,
        'correct': correct,
        'marks_obtained': obtained,
        'marks_total': marksTotal,
        'percent': marksTotal == 0
            ? 0.0
            : (1000 * obtained / marksTotal).round() / 10,
        'by_topic': byTopic,
        'weak_topics': [
          for (final t in byTopic)
            if ((t['percent'] as double) < 50) t['topic'],
        ],
        'results': results,
        'written': const <Object>[],
        'written_marks_total': writtenTotal,
        'pending_written': 0,
      }),
    );
  }

  /// A real past paper: MCQs are marked by the backend as usual, but without
  /// AI explanations, and written answers are not sent (they would start AI
  /// marking). See docs/demo/ai-route-audit.md.
  DemoAction _realSubmit(Map<String, dynamic> body) => DemoPass(
    body: {
      ...body,
      'explain': false,
      'answers': [
        for (final a in (body['answers'] as List? ?? const []))
          if (a is Map) {...Map<String, dynamic>.from(a), 'answer_text': null},
      ],
    },
  );

  // --------------------------------------------------------------- evaluation

  Iterable<DemoWritten> get _listedWritten =>
      seed.written.where((w) => w.id.startsWith('demo-viva-'));

  Map<String, dynamic> _writtenJson(DemoWritten w) {
    final t = seed.topicsByCode[w.topicCode];
    final stats = _writtenStats[w.id];
    return {
      'id': w.id,
      'code': 'DEMO-${w.id.split('-').last.toUpperCase()}',
      'question_type': w.type,
      'stem': w.stem,
      'marks': w.marks,
      'difficulty': 'medium',
      'year': null,
      'is_outdated': false,
      'topic_id': null,
      'topic_title': t?.title,
      'unit_number': t?.unitNumber,
      'my_attempts': stats?.attempts ?? 0,
      'my_best_marks': stats?.best,
    };
  }

  DemoAction _writtenQuestions(String? type) {
    List<Map<String, dynamic>> mine() => [
      for (final w in _listedWritten)
        if (type == null || w.type == type) _writtenJson(w),
    ];
    return DemoPass(
      merge: (data) {
        if (data is! Map) return data;
        final items = [...mine(), ...(data['items'] as List? ?? const [])];
        return _mark({
          ...Map<String, dynamic>.from(data),
          'items': items,
          'total': ((data['total'] as num?)?.toInt() ?? 0) + mine().length,
        });
      },
      fallback: () {
        final items = mine();
        return DemoServe(
          200,
          _mark({
            'items': items,
            'total': items.length,
            'page': 1,
            'size': 100,
          }),
        );
      },
    );
  }

  DemoAction _questionStem(String id) {
    final w = seed.written.where((x) => x.id == id).firstOrNull;
    if (w == null) {
      return DemoServe.error(404, 'QUESTION_NOT_FOUND', 'Question not found.');
    }
    return DemoServe(
      200,
      _mark({
        'id': w.id,
        'stem': w.stem,
        'question_type': w.type,
        'marks': w.marks,
      }),
    );
  }

  /// The seed question for [questionId]; for a real question, the saved one
  /// whose wording is closest (asked from the non-AI question route).
  Future<(DemoWritten, bool closest, String stem)> _writtenFor(
    String questionId,
    String answer,
  ) async {
    final own = seed.written.where((w) => w.id == questionId).firstOrNull;
    if (own != null) return (own, false, own.stem);
    final real = questionId.startsWith('demo-')
        ? null
        : await realGet?.call('/questions/$questionId');
    final stem = '${real?['stem'] ?? real?['question'] ?? ''}';
    final match = matcher.best(
      stem.isEmpty ? answer : stem,
      seed.written,
      title: (w) => w.stem,
      keywords: (w) => [for (final p in w.points) ...p.keywords],
    )!;
    return (match.item, true, stem.isEmpty ? match.item.stem : stem);
  }

  Future<DemoAction> _evaluate(Map<String, dynamic> body) async {
    final questionId = '${body['question_id'] ?? ''}';
    final answer = '${body['answer_text'] ?? ''}'.trim();
    if (questionId.isEmpty || answer.isEmpty) {
      return DemoServe.error(422, 'VALIDATION_ERROR', 'Write an answer first.');
    }
    final existing = _evaluations[body['evaluation_id']];
    final (question, closest, stem) = await _writtenFor(questionId, answer);
    final marks = DemoMarker.mark(question, answer);
    final job = _newJob('evaluate_answer', null);
    final evaluation = _DemoEvaluation(
      id: existing?.id ?? _id('eval'),
      questionId: questionId,
      stem: stem,
      question: question,
      source: existing?.source ?? 'typed',
      answer: answer,
      ocrText: existing?.ocrText,
      marks: marks,
      closest: closest,
      createdAt: job.createdAt,
    );
    job.result = {'evaluation_id': evaluation.id};
    _evaluations[evaluation.id] = evaluation;
    final total = DemoMarker.total(marks);
    final old = _writtenStats[questionId];
    _writtenStats[questionId] = (
      attempts: (old?.attempts ?? 0) + 1,
      best: old == null || total > old.best ? total : old.best,
    );
    return DemoServe(
      202,
      _mark({
        'evaluation_id': evaluation.id,
        'job_id': job.id,
        'status': 'queued',
      }),
    );
  }

  Future<DemoAction> _ocr(Map<String, dynamic> body) async {
    final questionId = '${body['question_id'] ?? ''}';
    if (questionId.isEmpty) {
      return DemoServe.error(422, 'VALIDATION_ERROR', 'Pick a question.');
    }
    final (question, closest, stem) = await _writtenFor(
      questionId,
      seed.ocr.text,
    );
    final job = _newJob('ocr_answer', null);
    final evaluation = _DemoEvaluation(
      id: _id('eval'),
      questionId: questionId,
      stem: stem,
      question: question,
      source: 'handwritten',
      answer: null,
      ocrText: seed.ocr.text,
      marks: const [],
      closest: closest,
      createdAt: job.createdAt,
    );
    job.result = {'evaluation_id': evaluation.id};
    _evaluations[evaluation.id] = evaluation;
    return DemoServe(
      202,
      _mark({
        'evaluation_id': evaluation.id,
        'job_id': job.id,
        'status': 'queued',
      }),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Map<String, dynamic> _evaluationJson(_DemoEvaluation e) {
    final stage = _stage(e.createdAt);
    final ocrOnly = e.answer == null;
    final done = stage == 2;
    final status = !done
        ? const ['queued', 'running'][stage]
        : (ocrOnly ? 'ocr_ready' : 'succeeded');
    final marked = done && !ocrOnly;
    final total = DemoMarker.total(e.marks);
    final max = e.question.marks;
    final percent = max == 0 ? 0 : (100 * total / max).round();
    int count(String s) => e.marks.where((m) => m.status == s).length;
    final missing = [
      for (final m in e.marks)
        if (m.status != 'covered') m.point.text,
    ];
    final feedback = percent >= 75
        ? 'A strong answer that covers most of the marking points.'
        : percent >= 40
        ? 'A fair answer. Add the missing points below to gain more marks.'
        : 'This answer misses most of the marking points. Read the model '
              'answer, then try again.';
    return {
      'id': e.id,
      'question_id': e.questionId,
      'question': e.stem,
      'question_type': e.question.type,
      'status': status,
      'source': e.source,
      'answer_text': e.answer,
      'ocr_text': e.ocrText,
      'estimated_marks': marked ? total : null,
      'max_marks': max,
      'percent': marked ? percent : null,
      'covered': marked ? count('covered') : 0,
      'partial': marked ? count('partial') : 0,
      'missing': marked ? count('missing') : 0,
      'points': [
        if (marked)
          for (final m in e.marks)
            {
              'id': null,
              'text': m.point.text,
              'marks': m.point.marks,
              'status': m.status,
              'marks_awarded': m.marksAwarded,
              'evidence': null,
              'matched_keywords': m.matched,
              'is_required': false,
            },
      ],
      'model_answer': marked ? e.question.modelAnswer : null,
      'feedback': marked
          ? (e.closest ? '$feedback ${DemoMatcher.closestNote}' : feedback)
          : null,
      'tips': [
        if (marked)
          for (final text in missing.take(3)) 'Include: $text',
      ],
      'strengths': [
        if (marked)
          for (final m in e.marks)
            if (m.status == 'covered') m.point.text,
      ],
      'tips_ai_generated': false,
      'structure_ok': null,
      'confidence': null,
      'error': null,
    };
  }

  // ---------------------------------------------------------------- community

  Future<DemoAction> _suggestTopic(Map<String, dynamic> body) async {
    final text = '${body['title'] ?? ''} ${body['body'] ?? ''}';
    final nothing = {
      'topic_id': null,
      'topic': null,
      'unit_number': null,
      'confidence': 0.0,
    };
    await _wait();
    if (!matcher.isBiology(text)) return DemoServe(200, _mark(nothing));
    int? unit;
    final group = body['group_id'];
    if (group is String && group.isNotEmpty) {
      final json = await realGet?.call('/groups/$group');
      final n = json?['unit_number'];
      if (n is num) unit = n.toInt();
    }
    final topic = matcher.bestTopic(text, unitNumber: unit);
    final uuid = topic == null ? null : await _uuid(topic.code);
    if (topic == null || uuid == null) return DemoServe(200, _mark(nothing));
    return DemoServe(
      200,
      _mark({
        'topic_id': uuid,
        'topic': topic.title,
        'unit_number': topic.unitNumber,
        'confidence': 0.8,
      }),
    );
  }
}

class _DemoJob {
  _DemoJob({
    required this.id,
    required this.type,
    required this.createdAt,
    this.result,
    this.error,
    this.errorCode,
  });

  final String id;
  final String type;
  final DateTime createdAt;
  Map<String, dynamic>? result;
  String? error;
  String? errorCode;
  String? topicRef;
}

class _DemoUpload {
  _DemoUpload({
    required this.id,
    required this.fileName,
    required this.topicRef,
    required this.seedItem,
    required this.closest,
    required this.length,
    required this.createdAt,
  });

  final String id;
  final String fileName;
  final String? topicRef;
  final DemoUploadSeed seedItem;
  final bool closest;
  final String length;
  final DateTime createdAt;
}

class _DemoEvaluation {
  _DemoEvaluation({
    required this.id,
    required this.questionId,
    required this.stem,
    required this.question,
    required this.source,
    required this.answer,
    required this.ocrText,
    required this.marks,
    required this.closest,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final String stem;
  final DemoWritten question;
  final String source;
  final String? answer;
  final String? ocrText;
  final List<DemoPointMark> marks;
  final bool closest;
  final DateTime createdAt;
}
