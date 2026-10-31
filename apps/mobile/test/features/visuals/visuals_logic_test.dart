import 'dart:convert';
import 'dart:io';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/visuals/application/visuals_controller.dart';
import 'package:brainbox_mobile/features/visuals/data/diagram_renderer.dart';
import 'package:brainbox_mobile/features/visuals/data/fake_visuals_repository.dart';
import 'package:brainbox_mobile/features/visuals/data/visuals_repository.dart';
import 'package:brainbox_mobile/features/visuals/domain/visuals_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

ProviderContainer _container(FakeVisualsRepository repo) {
  final c = ProviderContainer(
    overrides: [visualsRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('DiagramRenderer', () {
    test('puts zlib + base64url Mermaid in a Kroki PNG url', () {
      const code = 'flowchart LR\n  A --> B';
      final url = DiagramRenderer.mermaidPngUrl(code);
      expect(url, startsWith('${DiagramRenderer.baseUrl}/mermaid/png/'));

      final packed = base64Url.decode(url.split('/').last);
      expect(utf8.decode(ZLibDecoder().convert(packed)), code);
    });

    test('prefers the backend PNG, falls back to Mermaid, else null', () {
      const png = Visual(id: '1', title: 't', imageUrl: 'https://x/y.png');
      const mermaid = Visual(id: '2', title: 't', mermaidCode: 'graph TD');
      const empty = Visual(id: '3', title: 't');
      expect(DiagramRenderer.imageUrlOf(png), 'https://x/y.png');
      expect(DiagramRenderer.imageUrlOf(mermaid), contains('/mermaid/png/'));
      expect(DiagramRenderer.imageUrlOf(empty), isNull);
    });
  });

  test('Visual reads the backend JSON (snake_case, labels, new kinds)', () {
    final visual = Visual.fromJson({
      'id': 'v1',
      'title': 'Nephron structure',
      'topic_id': 't1',
      'kind': 'something_new',
      'image_url': 'https://cdn/n.png',
      'is_ai_generated': true,
      'width': 800,
      'height': 400,
      'labels': [
        {'number': 1, 'name': "Bowman's capsule", 'x': 0.2, 'y': 0.3},
      ],
    });
    expect(visual.kind, VisualKind.diagram); // unknown kind -> default
    expect(visual.aspectRatio, 2);
    expect(visual.labels.single.x, 0.2);
    expect(visual.isAiGenerated, isTrue);
    expect(const Visual(id: 'x', title: 'y').aspectRatio, 4 / 3);
  });

  test('GenerateVisualRequest sends the backend enum values', () {
    const request = GenerateVisualRequest(
      prompt: 'Nephron',
      visualType: VisualType.process,
      style: VisualStyle.crossSection,
      topicId: 't1',
    );
    expect(request.toJson(), {
      'prompt': 'Nephron',
      'visual_type': 'process',
      'style': 'cross_section',
      'topic_id': 't1',
    });
  });

  test('VisualFilter matches the right visuals', () {
    const ai = Visual(id: 'a', title: 'a', isAiGenerated: true);
    const checked = Visual(
      id: 'b',
      title: 'b',
      isVerified: true,
      labels: [VisualLabel(number: 1, name: 'x')],
    );
    expect(VisualFilter.all.matches(ai), isTrue);
    expect(VisualFilter.verified.matches(ai), isFalse);
    expect(VisualFilter.verified.matches(checked), isTrue);
    expect(VisualFilter.aiGenerated.matches(ai), isTrue);
    expect(VisualFilter.labelled.matches(checked), isTrue);
    expect(VisualFilter.labelled.matches(ai), isFalse);
  });

  group('GenerateVisualController', () {
    test('runs the job and ends with the new visual', () async {
      final repo = FakeVisualsRepository(step: Duration.zero);
      final c = _container(repo);
      final sub = c.listen(generateVisualControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final controller = c.read(generateVisualControllerProvider.notifier);

      controller.setType(VisualType.comparison);
      final run = controller.generate(
        prompt: 'mitosis vs meiosis',
        topicId: 't1',
      );
      expect(sub.read().isGenerating, isTrue);
      await run;

      final state = sub.read();
      expect(state.phase, GeneratePhase.done);
      expect(state.progress, 1);
      expect(state.visual?.kind, VisualKind.table);
      expect(state.visual?.isAiGenerated, isTrue);

      // It is saved under the topic and listed first in the gallery.
      final gallery = await repo.topicVisuals('t1');
      expect(gallery.visuals.first.id, state.visual!.id);
    });

    test('shows the job error when the AI fails', () async {
      final c = _container(FakeVisualsRepository(step: Duration.zero));
      final sub = c.listen(generateVisualControllerProvider, (_, _) {});
      addTearDown(sub.close);

      await c
          .read(generateVisualControllerProvider.notifier)
          .generate(prompt: 'please fail');

      expect(sub.read().phase, GeneratePhase.failed);
      expect(sub.read().error, contains('could not draw'));
    });

    test('ignores an empty prompt and can be cancelled', () async {
      final c = _container(
        FakeVisualsRepository(step: const Duration(milliseconds: 5)),
      );
      final sub = c.listen(generateVisualControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final controller = c.read(generateVisualControllerProvider.notifier);

      await controller.generate(prompt: '   ');
      expect(sub.read().phase, GeneratePhase.editing);

      final run = controller.generate(prompt: 'nephron');
      controller.cancel();
      await run;
      expect(sub.read().phase, GeneratePhase.editing);
      expect(sub.read().visual, isNull);
    });
  });

  test('report sends the reason', () async {
    final repo = FakeVisualsRepository(step: Duration.zero);
    final c = _container(repo);
    final sub = c.listen(visualReportControllerProvider, (_, _) {});
    addTearDown(sub.close);

    final ok = await c
        .read(visualReportControllerProvider.notifier)
        .submit('v-nephron', reason: VisualReportReason.wrongLabel);

    expect(ok, isTrue);
    expect(repo.reports, [VisualReportReason.wrongLabel]);
    expect(VisualReportReason.wrongLabel.apiValue, 'wrong_label');
  });

  group('ApiVisualsRepository', () {
    late _MockApi api;
    late ApiVisualsRepository repo;

    setUp(() {
      api = _MockApi();
      repo = ApiVisualsRepository(api, JobPoller(api));
    });

    test('starts a job and returns its id', () async {
      when(
        () => api.post<Map<String, dynamic>>(
          '/visuals/generate',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => {'job_id': 'job-9'});

      expect(
        await repo.startGeneration(
          const GenerateVisualRequest(
            prompt: 'Nephron',
            visualType: VisualType.structure,
            style: VisualStyle.flatColour,
          ),
        ),
        'job-9',
      );
    });

    test('reads the visual from a job: inline or by id', () async {
      final inline = await repo.visualFromJob(
        const AiJob(
          id: 'j',
          status: AiJobStatus.succeeded,
          result: {
            'visual': {'id': 'v1', 'title': 'Inline'},
          },
        ),
      );
      expect(inline.title, 'Inline');

      when(
        () => api.get<Map<String, dynamic>>('/visuals/v2'),
      ).thenAnswer((_) async => {'id': 'v2', 'title': 'By id'});
      final byId = await repo.visualFromJob(
        const AiJob(
          id: 'j',
          status: AiJobStatus.succeeded,
          result: {'visual_id': 'v2'},
        ),
      );
      expect(byId.title, 'By id');
    });

    test('report leaves out empty details', () async {
      when(
        () => api.post<Object?>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => null);

      await repo.report(
        'v1',
        reason: VisualReportReason.unclear,
        details: '  ',
      );

      verify(
        () => api.post<Object?>(
          '/visuals/v1/report',
          data: {'reason': 'unclear'},
        ),
      ).called(1);
    });
  });
}

class _MockApi extends Mock implements ApiClient {}
