import 'package:brainbox_core/brainbox_core.dart';

import '../domain/visuals_models.dart';
import 'visuals_repository.dart';

/// DEBUG ONLY: [VisualsRepository] in memory. Used ONLY with
/// `--dart-define=USE_FAKE_API=true` and in tests; the real app always uses
/// [ApiVisualsRepository].
///
/// Every topic shows the Figma B8 sample (Unit 6 > Mendelian inheritance).
/// Images are Mermaid diagrams rendered by Kroki (needs internet).
///
/// Jobs behave like the backend: queued -> running -> succeeded, with
/// progress 0 then 1. A prompt containing "fail" is refused like a
/// non-Biology prompt (`error_code: NOT_BIOLOGY`).
class FakeVisualsRepository implements VisualsRepository {
  FakeVisualsRepository({this.step = const Duration(milliseconds: 500)});

  /// Time between two fake job polls (zero in tests).
  final Duration step;

  final Map<String, Visual> _visuals = {for (final v in _seed) v.id: v};
  final Map<String, GenerateVisualRequest> _jobs = {};
  final List<VisualReportReason> reports = [];
  int _nextId = 1;

  Future<void> _delay() => Future<void>.delayed(step);

  @override
  Future<TopicVisuals> topicVisuals(String topicId) async {
    await _delay();
    final mine = _visuals.values
        .where((v) => v.topicId == topicId && v.id.startsWith('gen-'))
        .toList()
        .reversed;
    return TopicVisuals(
      topicId: topicId,
      topicTitle: 'Mendelian inheritance',
      unitCode: '6',
      unitTitle: 'Genetics',
      // Newest generated first, then the shared ones.
      visuals: [
        ...mine,
        ..._seed.map((v) => v.copyWith(topicId: topicId)),
      ],
    );
  }

  @override
  Future<Visual> visual(String visualId) async {
    await _delay();
    final found = _visuals[visualId];
    if (found == null) {
      throw const ApiException(
        code: 'VISUAL_NOT_FOUND',
        message: 'Visual not found.',
        statusCode: 404,
      );
    }
    return found;
  }

  @override
  Future<String> startGeneration(GenerateVisualRequest request) async {
    await _delay();
    final id = 'job-${_nextId++}';
    _jobs[id] = request;
    return id;
  }

  @override
  Stream<AiJob> watchJob(String jobId) async* {
    final request = _jobs[jobId];
    yield AiJob(id: jobId);
    await _delay();
    for (var i = 0; i < 2; i++) {
      yield AiJob(id: jobId, status: AiJobStatus.running);
      await _delay();
    }
    if (request == null || request.prompt.toLowerCase().contains('fail')) {
      yield AiJob(
        id: jobId,
        status: AiJobStatus.failed,
        error: 'I can only draw Biology visuals.',
        errorCode: 'NOT_BIOLOGY',
      );
      return;
    }
    final visual = _generated(request);
    _visuals[visual.id] = visual;
    yield AiJob(
      id: jobId,
      status: AiJobStatus.succeeded,
      progress: 1,
      result: {'visual_id': visual.id},
    );
  }

  @override
  Future<Visual> visualFromJob(AiJob job) =>
      visual(job.result?['visual_id'] as String);

  @override
  Future<void> report(
    String visualId, {
    required VisualReportReason reason,
    String? details,
  }) async {
    await _delay();
    reports.add(reason);
  }

  Visual _generated(GenerateVisualRequest r) {
    final title = _titleFrom(r.prompt);
    final id = 'gen-${_nextId++}';
    return switch (r.visualType) {
      VisualType.process => Visual(
        id: id,
        topicId: r.topicId,
        title: title,
        kind: VisualKind.flowchart,
        style: 'flat_colour',
        isAiGenerated: true,
        mermaidCode: _urineFlow,
        altText: 'Four steps of urine formation in the nephron.',
        labels: _urineLabels,
      ),
      VisualType.structure => _seed[2].copyWith(
        id: id,
        topicId: r.topicId,
        title: title,
        isVerified: false,
        isAiGenerated: true,
      ),
      VisualType.comparison => Visual(
        id: id,
        topicId: r.topicId,
        title: title,
        kind: VisualKind.table,
        isAiGenerated: true,
        mermaidCode: _mitosisVsMeiosis,
        altText: 'Mitosis and meiosis compared side by side.',
      ),
    };
  }

  static String _titleFrom(String prompt) {
    final text = prompt.trim();
    final short = text.length > 40 ? '${text.substring(0, 40)}...' : text;
    return short.isEmpty
        ? 'New visual'
        : short[0].toUpperCase() + short.substring(1);
  }

  static const _urineFlow = '''
flowchart LR
  A["1. Filtration<br/>Glomerulus"] --> B["2. Reabsorption<br/>PCT"]
  B --> C["3. Concentration<br/>Loop of Henle"]
  C --> D["4. Collection<br/>Collecting duct"]
''';

  static const _urineLabels = [
    VisualLabel(
      number: 1,
      name: 'Filtration',
      description:
          'High blood pressure in the glomerulus pushes water, glucose, salts '
          'and urea into Bowman\'s capsule. This is ultrafiltration.',
    ),
    VisualLabel(
      number: 2,
      name: 'Reabsorption',
      description:
          'The proximal convoluted tubule takes back all glucose and amino '
          'acids and most of the water and salts.',
    ),
    VisualLabel(
      number: 3,
      name: 'Concentration',
      description:
          'The loop of Henle builds a salt gradient in the medulla so water '
          'can leave the filtrate.',
    ),
    VisualLabel(
      number: 4,
      name: 'Collection',
      description:
          'ADH controls how much water the collecting duct lets back into '
          'the blood.',
    ),
  ];

  static const _mitosisVsMeiosis = '''
flowchart TB
  subgraph Mitosis
    M1["1 division"] --> M2["2 identical diploid cells"]
  end
  subgraph Meiosis
    E1["2 divisions"] --> E2["4 different haploid cells"]
  end
''';

  static const _seed = <Visual>[
    Visual(
      id: 'v-monohybrid',
      title: 'Monohybrid cross',
      kind: VisualKind.flowchart,
      isVerified: true,
      mermaidCode: '''
flowchart TB
  P["P: TT x tt"] --> F1["F1: all Tt (tall)"]
  F1 --> F2["F2: TT, Tt, Tt, tt"]
  F2 --> R["3 tall : 1 dwarf"]
''',
      altText: 'A cross of pure tall and dwarf pea plants giving a 3:1 ratio.',
    ),
    Visual(
      id: 'v-dna-gene',
      title: 'Chromosome, gene and allele',
      kind: VisualKind.diagram,
      isVerified: true,
      mermaidCode: '''
flowchart LR
  C["Chromosome"] --> G["Gene: a section of DNA"]
  G --> A1["Allele T"]
  G --> A2["Allele t"]
''',
      labels: [
        VisualLabel(
          number: 1,
          name: 'Gene',
          description: 'A section of DNA that codes for one characteristic.',
        ),
        VisualLabel(
          number: 2,
          name: 'Allele',
          description:
              'A different form of the same gene, e.g. T (tall) and t (dwarf).',
        ),
      ],
    ),
    Visual(
      id: 'v-nephron',
      title: 'Nephron structure',
      kind: VisualKind.diagram,
      style: 'flat_colour',
      isAiGenerated: true,
      mermaidCode: '''
flowchart TB
  B["1. Bowman's capsule"] --> P["2. PCT"]
  P --> L["3. Loop of Henle"]
  L --> D["4. DCT"]
  D --> C["Collecting duct"]
''',
      altText: 'The parts of a nephron in the order the filtrate flows.',
      labels: [
        VisualLabel(
          number: 1,
          name: "Bowman's capsule",
          description:
              'Cup-shaped end of the nephron. High pressure in the glomerulus '
              'pushes water, glucose, salts and urea in here. This is '
              'ultrafiltration.',
        ),
        VisualLabel(
          number: 2,
          name: 'Proximal convoluted tubule',
          description:
              'Reabsorbs all glucose and most water and salts back into the '
              'blood.',
        ),
        VisualLabel(
          number: 3,
          name: 'Loop of Henle',
          description:
              'Makes the medulla salty, so water can be drawn out of the '
              'filtrate later.',
        ),
        VisualLabel(
          number: 4,
          name: 'Distal convoluted tubule',
          description: 'Fine-tunes salt and pH balance.',
        ),
      ],
    ),
    Visual(
      id: 'v-dihybrid',
      title: 'Dihybrid cross 9:3:3:1',
      kind: VisualKind.flowchart,
      isAiGenerated: true,
      mermaidCode: '''
flowchart TB
  P["P: RRYY x rryy"] --> F1["F1: all RrYy"]
  F1 --> F2["F2: 16 combinations"]
  F2 --> R["9 round yellow : 3 round green : 3 wrinkled yellow : 1 wrinkled green"]
''',
      altText: 'A dihybrid cross giving the 9:3:3:1 ratio.',
    ),
  ];
}
