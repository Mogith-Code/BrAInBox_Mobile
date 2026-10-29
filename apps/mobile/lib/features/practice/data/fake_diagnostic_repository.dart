import 'package:brainbox_core/brainbox_core.dart';

import '../../../app/dev/fake_backend.dart';
import '../domain/diagnostic_models.dart';
import 'diagnostic_repository.dart';

/// DEBUG ONLY: [DiagnosticRepository] on the in-memory [FakeBackend].
/// 15 A/L Biology questions across the 10 units; the result is the one from
/// the Figma "Your starting point" screen.
class FakeDiagnosticRepository implements DiagnosticRepository {
  FakeDiagnosticRepository(this.backend);

  final FakeBackend backend;

  static const units = [
    ('U1', 'Introduction'),
    ('U2', 'Chemical & Cellular'),
    ('U3', 'Evolution & Diversity'),
    ('U4', 'Plant Form & Function'),
    ('U5', 'Animal Form & Function'),
    ('U6', 'Genetics'),
    ('U7', 'Molecular Biology'),
    ('U8', 'Environmental'),
    ('U9', 'Microbiology'),
    ('U10', 'Applied Biology'),
  ];

  /// (unit index, stem, options A-E)
  static const _bank = [
    (
      0,
      'Which of the following is a characteristic of all living organisms?',
      [
        'Photosynthesis',
        'Cellular organisation',
        'Locomotion',
        'A nucleus',
        'Multicellularity',
      ],
    ),
    (
      1,
      'Which organelle is the main site of aerobic respiration?',
      ['Ribosome', 'Golgi body', 'Mitochondrion', 'Lysosome', 'Chloroplast'],
    ),
    (
      1,
      'Which bond joins two amino acids in a protein?',
      [
        'Glycosidic bond',
        'Peptide bond',
        'Ester bond',
        'Hydrogen bond',
        'Phosphodiester bond',
      ],
    ),
    (
      2,
      'Which kingdom includes organisms with chitin cell walls?',
      ['Plantae', 'Animalia', 'Fungi', 'Protista', 'Monera'],
    ),
    (
      3,
      'Through which tissue does water move up a plant stem?',
      ['Phloem', 'Xylem', 'Cortex', 'Epidermis', 'Pith'],
    ),
    (
      3,
      'Which hormone mainly causes stomatal closure during water stress?',
      ['Auxin', 'Gibberellin', 'Cytokinin', 'Abscisic acid', 'Ethylene'],
    ),
    (
      4,
      'Where in the nephron does ultrafiltration take place?',
      [
        "Bowman's capsule",
        'Loop of Henle',
        'Collecting duct',
        'Distal tubule',
        'Proximal tubule',
      ],
    ),
    (
      4,
      'Which blood vessel carries oxygenated blood from the lungs to the heart?',
      [
        'Pulmonary artery',
        'Pulmonary vein',
        'Aorta',
        'Vena cava',
        'Hepatic vein',
      ],
    ),
    (
      5,
      'In a dihybrid cross of two heterozygotes, what is the expected phenotypic ratio?',
      ['3:1', '1:2:1', '9:3:3:1', '1:1:1:1', '12:3:1'],
    ),
    (
      5,
      'A trait carried on the X chromosome is described as',
      ['autosomal', 'sex-linked', 'codominant', 'polygenic', 'epistatic'],
    ),
    (
      6,
      'Which enzyme joins Okazaki fragments during DNA replication?',
      ['Helicase', 'Primase', 'DNA ligase', 'RNA polymerase', 'Topoisomerase'],
    ),
    (
      6,
      'Which base is found in RNA but not in DNA?',
      ['Adenine', 'Guanine', 'Cytosine', 'Thymine', 'Uracil'],
    ),
    (
      7,
      'Which organisms occupy the first trophic level of a food chain?',
      ['Herbivores', 'Producers', 'Decomposers', 'Carnivores', 'Omnivores'],
    ),
    (
      8,
      'Which structure allows some bacteria to survive harsh conditions?',
      ['Capsule', 'Endospore', 'Pilus', 'Plasmid', 'Flagellum'],
    ),
    (
      9,
      'Which technique makes many copies of a DNA segment?',
      [
        'ELISA',
        'Gel electrophoresis',
        'PCR',
        'Western blotting',
        'Chromatography',
      ],
    ),
  ];

  static const _masteries = [82, 70, 58, 88, 54, 26, 40, 66, 49, 61];

  /// attempt id -> question id -> option id
  final Map<String, Map<String, String>> _answers = {};

  String get _attemptId => 'attempt-${backend.requireSignedIn().uid}';

  List<DiagnosticQuestion> _questions(Map<String, String> answers) => [
    for (final (i, (unit, stem, options)) in _bank.indexed)
      DiagnosticQuestion(
        id: 'q${i + 1}',
        unitCode: units[unit].$1,
        unitTitle: units[unit].$2,
        stem: stem,
        options: [
          for (final (j, text) in options.indexed)
            DiagnosticOption(
              id: 'q${i + 1}-$j',
              label: String.fromCharCode(65 + j), // A, B, C...
              text: text,
            ),
        ],
        selectedOptionId: answers['q${i + 1}'],
      ),
  ];

  @override
  Future<DiagnosticAttempt> start() async {
    await backend.delay();
    final answers = _answers.putIfAbsent(_attemptId, () => {});
    return DiagnosticAttempt(
      attemptId: _attemptId,
      total: _bank.length,
      minutes: 10,
      questions: _questions(answers),
    );
  }

  @override
  Future<AnswerSaved> answer({
    required String attemptId,
    required String questionId,
    required String optionId,
  }) async {
    await backend.delay();
    final answers = _answers.putIfAbsent(attemptId, () => {});
    answers[questionId] = optionId;
    return AnswerSaved(answered: answers.length, total: _bank.length);
  }

  @override
  Future<DiagnosticResult> submit(String attemptId) async {
    await backend.delay();
    final account = backend.requireSignedIn();
    account.onboarding = account.onboarding.copyWith(diagnosticCompleted: true);
    return figmaResult(attemptId);
  }

  @override
  Future<void> skip() async {
    await backend.delay();
    final account = backend.requireSignedIn();
    account.onboarding = account.onboarding.copyWith(diagnosticSkipped: true);
  }

  @override
  Future<DiagnosticResult> result() async {
    await backend.delay();
    if (!backend.requireSignedIn().onboarding.diagnosticCompleted) {
      throw const ApiException(
        code: 'DIAGNOSTIC_NOT_FOUND',
        message: 'No diagnostic yet.',
        statusCode: 404,
      );
    }
    return figmaResult(_attemptId);
  }

  /// The result shown in Figma A13.
  static DiagnosticResult figmaResult(String attemptId) => DiagnosticResult(
    attemptId: attemptId,
    completedAt: DateTime.now(),
    score: 8,
    total: _bank.length,
    strongest: const UnitRef(
      unitCode: 'U4',
      unitTitle: 'Plant Form & Function',
    ),
    needsWork: const UnitRef(unitCode: 'U6', unitTitle: 'Genetics'),
    units: [
      for (final (i, (code, title)) in units.indexed)
        UnitResult(
          unitCode: code,
          unitTitle: title,
          mastery: _masteries[i].toDouble(),
          status: _masteries[i] >= 80
              ? UnitStatus.strong
              : _masteries[i] < 45
              ? UnitStatus.needsWork
              : UnitStatus.ok,
        ),
    ],
    summary: '',
    summaryAiGenerated: true,
    disclaimer: 'Formative feedback — not an official exam mark.',
  );
}
