import 'dart:convert';
import 'dart:typed_data';

import 'package:brainbox_core/brainbox_core.dart';

import 'learn_repository.dart';

/// In-memory [LearnRepository] with the same seed as the backend.
///
/// Used with `--dart-define=USE_MOCK_LEARN=true` (or `USE_FAKE_API=true`)
/// and by tests. Bookmarks, generated notes and uploads live until the app
/// closes.
///
/// AI work is simulated: a generation job or an upload needs
/// [pollsUntilDone] polls before it is done. Set [failNextGeneration] or
/// name a file `fail.pdf` to see the error states.
class MockLearnRepository implements LearnRepository {
  MockLearnRepository({
    this.latency = const Duration(milliseconds: 350),
    this.pollsUntilDone = 2,
  });

  final Duration latency;
  final int pollsUntilDone;

  /// The next generation job fails (for the error state).
  bool failNextGeneration = false;

  /// Every progress event sent, for tests: `(topicId, event, completed)`.
  final List<(String, ProgressEvent, bool)> progressLog = [];

  final Set<String> _bookmarked = {'t-dihybrid'};
  final Map<(String, NoteType), TopicNote> _notes = {
    ('t-mendelian', NoteType.full): mendelianNote,
  };
  final Map<String, _MockJob> _jobs = {};
  final List<Upload> _uploads = [
    Upload(
      id: 'up-1',
      fileName: 'Genetics tuition notes.pdf',
      status: UploadStatus.done,
      createdAt: DateTime(2026, 11, 10, 18, 30),
      topic: const UploadTopic(
        id: 't-mendelian',
        title: 'Mendelian inheritance',
      ),
      summary: _uploadSummary,
      keyPoints: _uploadKeyPoints,
      extractedText: _uploadText,
    ),
  ];
  final Map<String, int> _uploadPolls = {};
  final List<Bookmark> _shortNotes = [];
  final Map<String, TopicStatus> _statusOverrides = {};
  int _ids = 0;

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<List<Subject>> fetchSubjects() async {
    await _wait();
    return const [
      Subject(id: 'biology', name: 'Biology', available: true),
      Subject(id: 'chemistry', name: 'Chemistry'),
      Subject(id: 'physics', name: 'Physics'),
    ];
  }

  @override
  Future<List<UnitProgress>> fetchUnits(String subjectId) async {
    await _wait();
    if (subjectId != 'biology') return const [];
    return seedUnits;
  }

  @override
  Future<UnitDetail> fetchUnit(String unitId) async {
    await _wait();
    final unit = _unit(unitId);
    return UnitDetail(unit: unit, topics: _topicsOf(unitId));
  }

  @override
  Future<TopicDetail> fetchTopic(String topicId) async {
    await _wait();
    final topic = _topic(topicId);
    final unit = _unit(topic.unitId);
    final index = _topicsOf(unit.id).indexWhere((t) => t.id == topicId) + 1;
    return TopicDetail(
      topic: topic,
      unit: unit,
      breadcrumb: ['Biology', 'Unit ${unit.order}', topic.title],
      masteryLevel: _masteryOf(topic),
      masteryPercent: topic.status == TopicStatus.mastered ? 90 : 48,
      saved: _bookmarked.contains(topicId),
      syllabusCode: '${unit.order}.$index',
      syllabusVersion: '2023',
    );
  }

  @override
  Future<TopicNote?> fetchNote(String topicId, NoteType type) async {
    await _wait();
    _topic(topicId);
    return _notes[(topicId, type)];
  }

  /// Unit 1 has one book, Unit 5 has two, and the rest have none yet, so
  /// every state of the Government notes viewer can be seen.
  @override
  Future<OfficialNotes> fetchOfficialNotes(String topicId) async {
    await _wait();
    final unitId = _topic(topicId).unitId;
    final books = switch (unitId) {
      'unit-1' => const [
        OfficialBook(
          documentId: 'book-1',
          title: 'Unit 1: Introduction To Biology',
          pageCount: 5,
        ),
      ],
      'unit-5' => const [
        OfficialBook(
          documentId: 'book-5a',
          title: 'Unit 5: Animal Form And Function (Part 1)',
          pageCount: 3,
        ),
        OfficialBook(
          documentId: 'book-5b',
          title: 'Unit 5: Animal Form And Function (Part 2)',
          pageCount: 2,
        ),
      ],
      _ => const <OfficialBook>[],
    };
    return OfficialNotes(
      topicId: topicId,
      available: books.isNotEmpty,
      books: books,
      openDocumentId: books.firstOrNull?.documentId,
      exactMatch: unitId == 'unit-1',
    );
  }

  @override
  Future<Uint8List> fetchOfficialPage(String documentId, int page) async {
    await _wait();
    return _samplePage;
  }

  @override
  Future<String> startNoteGeneration(
    String topicId,
    NoteGenerationRequest request,
  ) async {
    await _wait();
    final topic = _topic(topicId);
    final id = 'job-${++_ids}';
    _jobs[id] = _MockJob(
      topicId: topicId,
      title: topic.title,
      request: request,
      fail: failNextGeneration,
    );
    failNextGeneration = false;
    return id;
  }

  @override
  Future<GenerationJob> fetchJob(String jobId) async {
    await _wait();
    final job = _jobs[jobId];
    if (job == null) throw _notFound('JOB_NOT_FOUND', 'Job not found.');
    job.polls++;
    if (job.polls < pollsUntilDone) {
      return GenerationJob(
        status: job.polls == 1 ? JobStatus.queued : JobStatus.running,
      );
    }
    if (job.fail) {
      return const GenerationJob(
        status: JobStatus.failed,
        error: "BrAInBox couldn't write these notes. Please try again.",
      );
    }
    final note = _generatedNote(job);
    _notes[(job.topicId, job.request.type)] = note;
    return GenerationJob(status: JobStatus.done, resultId: note.id);
  }

  @override
  Future<List<Diagram>> fetchDiagrams(String topicId) async {
    await _wait();
    _topic(topicId);
    return topicId == 't-mendelian' ? mendelianDiagrams : const [];
  }

  @override
  Future<List<Video>> fetchVideos(String topicId) async {
    await _wait();
    final topic = _topic(topicId);
    final q = Uri.encodeQueryComponent('${topic.title} A/L biology');
    return [
      Video(
        id: 'v-$topicId-1',
        title: '${topic.title} explained',
        url: 'https://www.youtube.com/results?search_query=$q',
        durationSeconds: 754,
      ),
      Video(
        id: 'v-$topicId-2',
        title: '${topic.title}: past-paper walkthrough',
        url: 'https://www.youtube.com/results?search_query=$q+past+paper',
        durationSeconds: 1325,
      ),
    ];
  }

  @override
  Future<PracticeSummary> fetchPracticeSummary(String topicId) async {
    await _wait();
    _topic(topicId);
    return topicId == 't-mendelian'
        ? PracticeSummary(
            questionCount: 48,
            accuracyPercent: 62,
            lastAttemptAt: DateTime(2026, 11, 14, 19, 5),
          )
        : const PracticeSummary(questionCount: 24);
  }

  @override
  Future<void> sendProgress(
    String topicId,
    ProgressEvent event, {
    int seconds = 0,
    bool completed = false,
  }) async {
    progressLog.add((topicId, event, completed));
    if (event == ProgressEvent.opened &&
        _topic(topicId).status == TopicStatus.notStarted) {
      _statusOverrides[topicId] = TopicStatus.inProgress;
    }
  }

  @override
  Future<List<Bookmark>> fetchBookmarks() async {
    await _wait();
    return [
      for (final id in _bookmarked)
        if (_findTopic(id) case final topic?)
          Bookmark(
            topicId: id,
            topicTitle: topic.title,
            unitTitle: _unit(topic.unitId).title,
            unitOrder: _unit(topic.unitId).order,
          ),
      ..._shortNotes,
    ];
  }

  @override
  Future<void> addBookmark(String topicId) async {
    await _wait();
    _topic(topicId);
    _bookmarked.add(topicId);
  }

  @override
  Future<void> removeBookmark(String topicId) async {
    await _wait();
    _bookmarked.remove(topicId);
  }

  @override
  Future<SearchResult> search(String query) async {
    await _wait();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return SearchResult.empty;
    return SearchResult(
      units: filterUnits(seedUnits, q),
      topics: [
        for (final unit in seedUnits)
          for (final topic in _topicsOf(unit.id))
            if (topic.title.toLowerCase().contains(q))
              TopicSearchHit(
                id: topic.id,
                title: topic.title,
                unitId: unit.id,
                unitTitle: unit.title,
                unitOrder: unit.order,
              ),
      ],
    );
  }

  @override
  Future<Upload> createUpload(
    PickedUploadFile file, {
    String? topicId,
    SummaryLength summaryLength = SummaryLength.medium,
    void Function(double progress)? onProgress,
  }) async {
    for (var i = 1; i <= 4; i++) {
      await Future<void>.delayed(latency ~/ 2);
      onProgress?.call(i / 4);
    }
    final topic = topicId == null ? null : _findTopic(topicId);
    final upload = Upload(
      id: 'up-${++_ids + 100}',
      fileName: file.name,
      status: UploadStatus.processing,
      createdAt: DateTime.now(),
      topic: topic == null
          ? null
          : UploadTopic(id: topic.id, title: topic.title),
    );
    _uploads.insert(0, upload);
    return upload;
  }

  @override
  Future<List<Upload>> fetchUploads() async {
    await _wait();
    return [
      for (final u in _uploads) u.copyWith(extractedText: null, summary: null),
    ];
  }

  @override
  Future<Upload> fetchUpload(String uploadId) async {
    await _wait();
    final i = _uploads.indexWhere((u) => u.id == uploadId);
    if (i < 0) throw _notFound('UPLOAD_NOT_FOUND', 'Upload not found.');
    var upload = _uploads[i];
    if (upload.status.isBusy) {
      final polls = _uploadPolls[uploadId] = (_uploadPolls[uploadId] ?? 0) + 1;
      if (polls >= pollsUntilDone) {
        upload = upload.fileName.toLowerCase().startsWith('fail')
            ? upload.copyWith(
                status: UploadStatus.failed,
                error: "We couldn't read this file. Try a clearer copy.",
              )
            : upload.copyWith(
                status: UploadStatus.done,
                summary: _uploadSummary,
                keyPoints: _uploadKeyPoints,
                extractedText: _uploadText,
              );
        _uploads[i] = upload;
      }
    }
    return upload;
  }

  @override
  Future<void> saveUploadToShortNotes(String uploadId) async {
    final upload = await fetchUpload(uploadId);
    _shortNotes.removeWhere((b) => b.uploadId == uploadId);
    _shortNotes.add(
      Bookmark(
        kind: BookmarkKind.shortNote,
        noteId: 'sn-$uploadId',
        uploadId: uploadId,
        topicId: upload.topic?.id ?? '',
        topicTitle: upload.topic?.title ?? '',
        title: upload.fileName,
        preview: upload.keyPoints.firstOrNull ?? upload.summary,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteUpload(String uploadId) async {
    await _wait();
    _uploads.removeWhere((u) => u.id == uploadId);
    _shortNotes.removeWhere((b) => b.uploadId == uploadId);
  }

  // -------------------------------------------------------------------------

  UnitProgress _unit(String unitId) =>
      seedUnits.where((u) => u.id == unitId).firstOrNull ??
      (throw _notFound('UNIT_NOT_FOUND', 'Unit not found.'));

  List<TopicProgress> _topicsOf(String unitId) => [
    for (final t in seedTopics[unitId] ?? const <TopicProgress>[])
      _statusOverrides[t.id] == null
          ? t
          : t.copyWith(status: _statusOverrides[t.id]!),
  ];

  TopicProgress? _findTopic(String topicId) {
    for (final unit in seedUnits) {
      for (final t in _topicsOf(unit.id)) {
        if (t.id == topicId) return t;
      }
    }
    return null;
  }

  TopicProgress _topic(String topicId) =>
      _findTopic(topicId) ??
      (throw _notFound('TOPIC_NOT_FOUND', 'Topic not found.'));

  static MasteryLevel _masteryOf(TopicProgress t) =>
      t.status == TopicStatus.mastered
      ? MasteryLevel.mastered
      : t.isWeak
      ? MasteryLevel.weak
      : t.status == TopicStatus.inProgress
      ? MasteryLevel.improving
      : MasteryLevel.strong;

  TopicNote _generatedNote(_MockJob job) {
    final r = job.request;
    final minutes = switch (r.depth) {
      NoteDepth.detailed => 12,
      NoteDepth.standard => 6,
      NoteDepth.quick => 2,
    };
    final id = 'note-${++_ids}';
    if (r.type == NoteType.short) {
      return TopicNote(
        id: id,
        type: NoteType.short,
        aiGenerated: true,
        readMinutes: 2,
        createdAt: DateTime.now(),
        blocks: [
          NoteBlock.heading(text: '${job.title}: key points'),
          const NoteBlock.bulletList(
            items: [
              'Each trait is controlled by a pair of alleles.',
              'Alleles separate into gametes during meiosis (segregation).',
              'A dominant allele masks a recessive one in a heterozygote.',
              'Monohybrid F2 ratio 3:1; dihybrid F2 ratio 9:3:3:1.',
              'Use a test cross with the homozygous recessive to find an '
                  'unknown genotype.',
            ],
          ),
          if (r.includePastPaperTips)
            const NoteBlock.tip(
              text:
                  'Always state the genotypes of the parents and the '
                  'gametes before drawing the Punnett square.',
            ),
        ],
      );
    }
    return TopicNote(
      id: id,
      aiGenerated: true,
      readMinutes: minutes,
      createdAt: DateTime.now(),
      blocks: [
        NoteBlock.heading(text: job.title),
        NoteBlock.paragraph(
          text:
              '${job.title} builds on the idea that each characteristic '
              'is controlled by genes, and that genes come in different '
              'forms called alleles.',
          highlights: const ['genes', 'alleles'],
        ),
        const NoteBlock.definition(
          term: 'Allele',
          text:
              'One of two or more alternative forms of a gene found at the '
              'same locus on homologous chromosomes.',
        ),
        if (r.depth != NoteDepth.quick)
          const NoteBlock.paragraph(
            text:
                'In a heterozygote the dominant allele is expressed in the '
                'phenotype, while the recessive allele is hidden.',
            highlights: ['heterozygote', 'phenotype'],
          ),
        if (r.includeExamples)
          const NoteBlock.bulletList(
            items: [
              'Pea plant height: T (tall) is dominant over t (dwarf).',
              'Seed colour: Y (yellow) is dominant over y (green).',
            ],
          ),
        if (r.includePastPaperTips)
          const NoteBlock.tip(
            text: 'Examiners award marks for the gamete line. Never skip it.',
          ),
      ],
    );
  }

  static ApiException _notFound(String code, String message) =>
      ApiException(code: code, message: message, statusCode: 404);
}

class _MockJob {
  _MockJob({
    required this.topicId,
    required this.title,
    required this.request,
    required this.fail,
  });

  final String topicId;
  final String title;
  final NoteGenerationRequest request;
  final bool fail;
  int polls = 0;
}

// ---------------------------------------------------------------------------
// Seed data (matches the backend seed)
// ---------------------------------------------------------------------------

const seedUnits = [
  UnitProgress(
    id: 'unit-1',
    order: 1,
    title: 'Introduction to Biology',
    topicCount: 4,
    masteryPercent: 88,
    masteryLevel: MasteryLevel.mastered,
  ),
  UnitProgress(
    id: 'unit-2',
    order: 2,
    title: 'Chemical & Cellular Basis of Life',
    topicCount: 14,
    masteryPercent: 70,
    masteryLevel: MasteryLevel.strong,
  ),
  UnitProgress(
    id: 'unit-3',
    order: 3,
    title: 'Evolution & Diversity of Organisms',
    topicCount: 11,
    masteryPercent: 58,
    masteryLevel: MasteryLevel.improving,
  ),
  UnitProgress(
    id: 'unit-4',
    order: 4,
    title: 'Plant Form & Function',
    topicCount: 12,
    masteryPercent: 82,
    masteryLevel: MasteryLevel.strong,
  ),
  UnitProgress(
    id: 'unit-5',
    order: 5,
    title: 'Animal Form & Function',
    topicCount: 18,
    masteryPercent: 54,
    masteryLevel: MasteryLevel.improving,
  ),
  UnitProgress(
    id: 'unit-6',
    order: 6,
    title: 'Genetics',
    topicCount: 9,
    masteryPercent: 42,
    masteryLevel: MasteryLevel.weak,
  ),
  UnitProgress(
    id: 'unit-7',
    order: 7,
    title: 'Molecular Biology & Recombinant DNA',
    topicCount: 9,
    masteryPercent: 30,
    masteryLevel: MasteryLevel.weak,
  ),
  UnitProgress(
    id: 'unit-8',
    order: 8,
    title: 'Environmental Biology',
    topicCount: 8,
    masteryPercent: 64,
    masteryLevel: MasteryLevel.improving,
  ),
  UnitProgress(
    id: 'unit-9',
    order: 9,
    title: 'Microbiology',
    topicCount: 7,
    masteryPercent: 0,
    masteryLevel: MasteryLevel.weak,
  ),
  UnitProgress(
    id: 'unit-10',
    order: 10,
    title: 'Applied Biology',
    topicCount: 6,
    masteryPercent: 15,
    masteryLevel: MasteryLevel.weak,
  ),
];

/// Topic titles per unit. Ids used elsewhere in the app (Home, Insights)
/// are kept: t-enzymes, t-nephron, t-dihybrid, t-mendelian.
const _topicTitles = <String, List<(String, String)>>{
  'unit-1': [
    ('t-scope', 'Scope of biology'),
    ('t-characteristics', 'Characteristics of living organisms'),
    ('t-levels', 'Levels of organisation'),
    ('t-biology-society', 'Biology and society'),
  ],
  'unit-2': [
    ('t-elements-water', 'Elements and water in life'),
    ('t-carbohydrates', 'Carbohydrates'),
    ('t-lipids', 'Lipids'),
    ('t-proteins', 'Proteins'),
    ('t-nucleic-acids', 'Nucleic acids'),
    ('t-enzymes', 'Enzymes'),
    ('t-microscopy', 'Microscopy and cell theory'),
    ('t-cell-structure', 'Cell structure'),
    ('t-membranes', 'Membranes and transport'),
    ('t-cell-division', 'Cell division'),
    ('t-atp', 'Energy and ATP'),
    ('t-respiration', 'Cellular respiration'),
    ('t-photosynthesis', 'Photosynthesis'),
    ('t-cell-cycle', 'Cell cycle regulation'),
  ],
  'unit-3': [
    ('t-origin-of-life', 'Origin of life'),
    ('t-evolution-theories', 'Theories of evolution'),
    ('t-evolution-evidence', 'Evidence for evolution'),
    ('t-speciation', 'Natural selection and speciation'),
    ('t-classification', 'Principles of classification'),
    ('t-nomenclature', 'Binomial nomenclature'),
    ('t-domains', 'Domains and kingdoms'),
    ('t-protists', 'Kingdom Protista'),
    ('t-plantae', 'Kingdom Plantae'),
    ('t-fungi', 'Kingdom Fungi'),
    ('t-animalia', 'Kingdom Animalia'),
  ],
  'unit-4': [
    ('t-plant-tissues', 'Plant tissues'),
    ('t-plant-organs', 'Root, stem and leaf structure'),
    ('t-plant-growth', 'Plant growth and development'),
    ('t-plant-transport', 'Transport of water and minerals'),
    ('t-translocation', 'Translocation'),
    ('t-transpiration', 'Transpiration'),
    ('t-mineral-nutrition', 'Mineral nutrition'),
    ('t-plant-gas-exchange', 'Gas exchange in plants'),
    ('t-plant-hormones', 'Plant growth substances'),
    ('t-plant-responses', 'Plant responses'),
    ('t-flower-reproduction', 'Reproduction in flowering plants'),
    ('t-seeds-fruits', 'Seeds and fruits'),
  ],
  'unit-5': [
    ('t-animal-tissues', 'Animal tissues'),
    ('t-digestion', 'Nutrition and digestion'),
    ('t-circulation', 'Circulation'),
    ('t-blood', 'Blood and lymph'),
    ('t-immunity', 'Immunity'),
    ('t-animal-gas-exchange', 'Gas exchange in animals'),
    ('t-nephron', 'Excretion and the nephron'),
    ('t-osmoregulation', 'Osmoregulation'),
    ('t-nervous-system', 'Nervous system'),
    ('t-sense-organs', 'Sense organs'),
    ('t-endocrine', 'Endocrine system'),
    ('t-skeleton', 'Musculoskeletal system'),
    ('t-locomotion', 'Locomotion'),
    ('t-homeostasis', 'Homeostasis'),
    ('t-thermoregulation', 'Thermoregulation'),
    ('t-male-reproduction', 'Male reproductive system'),
    ('t-female-reproduction', 'Female reproductive system'),
    ('t-development', 'Human development'),
  ],
  'unit-6': [
    ('t-mendelian', 'Mendelian inheritance'),
    ('t-dihybrid', 'Monohybrid & dihybrid crosses'),
    ('t-test-cross', 'Test cross & back cross'),
    ('t-codominance', 'Incomplete dominance & codominance'),
    ('t-multiple-alleles', 'Multiple alleles & blood groups'),
    ('t-sex-linkage', 'Sex linkage'),
    ('t-pedigree', 'Pedigree analysis'),
    ('t-chromosomal-mutations', 'Chromosomal mutations'),
    ('t-polygenic', 'Polygenic inheritance'),
  ],
  'unit-7': [
    ('t-dna-replication', 'DNA structure and replication'),
    ('t-genetic-code', 'Genes and the genetic code'),
    ('t-transcription', 'Transcription'),
    ('t-translation', 'Translation'),
    ('t-gene-regulation', 'Gene regulation'),
    ('t-recombinant-dna', 'Recombinant DNA technology'),
    ('t-pcr', 'PCR and gel electrophoresis'),
    ('t-gm-applications', 'Applications of genetic engineering'),
    ('t-biosafety', 'Ethics and biosafety'),
  ],
  'unit-8': [
    ('t-ecosystems', 'Ecosystems'),
    ('t-energy-flow', 'Energy flow and food webs'),
    ('t-biogeochemical', 'Biogeochemical cycles'),
    ('t-population-ecology', 'Population ecology'),
    ('t-succession', 'Communities and succession'),
    ('t-biomes-sl', 'Ecosystems of Sri Lanka'),
    ('t-conservation', 'Biodiversity and conservation'),
    ('t-pollution', 'Environmental pollution'),
  ],
  'unit-9': [
    ('t-microbe-diversity', 'Diversity of microorganisms'),
    ('t-microbial-growth', 'Microbial growth'),
    ('t-bacteria', 'Bacteria'),
    ('t-viruses', 'Viruses'),
    ('t-industrial-microbes', 'Microorganisms in industry'),
    ('t-microbes-disease', 'Microorganisms and disease'),
    ('t-microbial-techniques', 'Microbiological techniques'),
  ],
  'unit-10': [
    ('t-agriculture', 'Food production and agriculture'),
    ('t-tissue-culture', 'Plant tissue culture'),
    ('t-aquaculture', 'Aquaculture'),
    ('t-food-preservation', 'Food preservation'),
    ('t-medical-biotech', 'Biotechnology in medicine'),
    ('t-applied-genetics', 'Applied genetics in agriculture'),
  ],
};

/// Status per topic id (everything else is not started). Genetics matches
/// the design: 9 topics · 2 mastered · 3 weak.
const _states = <String, (TopicStatus, double, bool)>{
  't-scope': (TopicStatus.mastered, 100, false),
  't-characteristics': (TopicStatus.mastered, 100, false),
  't-levels': (TopicStatus.mastered, 100, false),
  't-enzymes': (TopicStatus.inProgress, 60, false),
  't-cell-structure': (TopicStatus.mastered, 100, false),
  't-cell-division': (TopicStatus.inProgress, 35, true),
  't-origin-of-life': (TopicStatus.inProgress, 50, false),
  't-photosynthesis': (TopicStatus.mastered, 100, false),
  't-nephron': (TopicStatus.inProgress, 20, true),
  't-circulation': (TopicStatus.inProgress, 45, false),
  't-mendelian': (TopicStatus.inProgress, 40, false),
  't-dihybrid': (TopicStatus.inProgress, 25, true),
  't-test-cross': (TopicStatus.mastered, 100, false),
  't-codominance': (TopicStatus.notStarted, 0, true),
  't-sex-linkage': (TopicStatus.inProgress, 30, true),
  't-pedigree': (TopicStatus.mastered, 100, false),
};

final Map<String, List<TopicProgress>> seedTopics = {
  for (final MapEntry(key: unitId, value: topics) in _topicTitles.entries)
    unitId: [
      for (final (i, (id, title)) in topics.indexed)
        TopicProgress(
          id: id,
          unitId: unitId,
          order: i + 1,
          title: title,
          status: _states[id]?.$1 ?? TopicStatus.notStarted,
          progressPercent: _states[id]?.$2 ?? 0,
          isWeak: _states[id]?.$3 ?? false,
        ),
    ],
};

/// The full sample note for "Mendelian inheritance".
final mendelianNote = TopicNote(
  id: 'note-mendelian-full',
  aiGenerated: true,
  readMinutes: 6,
  createdAt: DateTime(2026, 11, 1),
  blocks: const [
    NoteBlock.heading(text: 'Mendelian inheritance'),
    NoteBlock.paragraph(
      text:
          'Gregor Mendel worked out the basic rules of inheritance by '
          'crossing pea plants with contrasting characters. He showed that '
          'characters are passed on as separate units, which we now call '
          'genes.',
      highlights: ['genes'],
    ),
    NoteBlock.definition(
      term: 'Genotype and phenotype',
      text:
          'The genotype is the set of alleles an organism has for a '
          'character (e.g. Tt). The phenotype is the observable '
          'characteristic that results (e.g. tall).',
    ),
    NoteBlock.heading(text: "Mendel's first law: law of segregation", level: 3),
    NoteBlock.paragraph(
      text:
          'The two alleles of a gene separate from each other during '
          'gamete formation, so each gamete carries only one allele. In a '
          'monohybrid cross of two heterozygotes the F2 phenotypic ratio is '
          '3:1.',
      highlights: ['alleles', 'gamete', '3:1'],
    ),
    NoteBlock.table(
      caption: 'Tt × Tt monohybrid cross',
      headers: ['Gametes', 'T', 't'],
      rows: [
        ['T', 'TT (tall)', 'Tt (tall)'],
        ['t', 'Tt (tall)', 'tt (dwarf)'],
      ],
    ),
    NoteBlock.heading(
      text: "Mendel's second law: law of independent assortment",
      level: 3,
    ),
    NoteBlock.paragraph(
      text:
          'Alleles of different genes assort independently of one another '
          'during gamete formation, provided the genes are on different '
          'chromosomes. A dihybrid cross of two double heterozygotes (YyRr '
          '× YyRr) gives an F2 phenotypic ratio of 9:3:3:1.',
      highlights: ['independent assortment', '9:3:3:1'],
    ),
    NoteBlock.bulletList(
      items: [
        '9 yellow round (Y_R_)',
        '3 yellow wrinkled (Y_rr)',
        '3 green round (yyR_)',
        '1 green wrinkled (yyrr)',
      ],
    ),
    NoteBlock.tip(
      text:
          'Past papers often give a ratio such as 1:1:1:1 and ask for the '
          'parents. That ratio means a test cross: one parent is YyRr and '
          'the other is yyrr. Always write the gametes before the Punnett '
          'square: it carries marks.',
    ),
  ],
);

const mendelianDiagrams = [
  Diagram(
    id: 'd-monohybrid',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/71/'
        'Punnett_square_mendel_flowers.svg/'
        '440px-Punnett_square_mendel_flowers.svg.png',
    caption: 'Monohybrid cross Punnett square',
  ),
  Diagram(
    id: 'd-dihybrid',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/'
        'Dihybrid_cross.svg/500px-Dihybrid_cross.svg.png',
    caption: 'Dihybrid cross: the 9:3:3:1 ratio',
    aiGenerated: true,
  ),
];

/// A 1x1 white PNG that stands in for a scanned book page.
final _samplePage = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/'
  'PchI7wAAAABJRU5ErkJggg==',
);

const _uploadSummary =
    'These tuition notes cover Mendel\'s two laws. The law of segregation '
    'says the two alleles of a gene separate into different gametes, which '
    'explains the 3:1 ratio in a monohybrid cross. The law of independent '
    'assortment says genes on different chromosomes are inherited '
    'independently, giving the 9:3:3:1 ratio in a dihybrid cross. The notes '
    'end with worked test-cross problems.';

const _uploadKeyPoints = [
  'Alleles separate during gamete formation (law of segregation).',
  'Monohybrid F2 phenotypic ratio is 3:1; genotypic ratio 1:2:1.',
  'Genes on different chromosomes assort independently.',
  'Dihybrid F2 phenotypic ratio is 9:3:3:1.',
  'A 1:1 or 1:1:1:1 ratio points to a test cross.',
];

const _uploadText =
    'Genetics - Lesson 3\n\nMendel used pea plants because they have '
    'contrasting characters, a short generation time and can be '
    'self-pollinated...\n\nLaw of segregation: the two factors for a '
    'character separate during gamete formation...\n\nLaw of independent '
    'assortment: ...';
