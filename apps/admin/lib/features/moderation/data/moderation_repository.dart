import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/moderation_models.dart';

part 'moderation_repository.g.dart';

/// Community moderation (admin). Only this layer calls the API.
abstract interface class ModerationRepository {
  /// `GET /admin/moderation/reports` - open reports, oldest first.
  Future<List<ModerationItem>> reports();

  /// `POST /admin/moderation/reports/{id}/resolve` with `{action}`.
  Future<void> resolve(String reportId, ModerationAction action);

  /// `GET /admin/community/groups`
  Future<List<StudyGroup>> groups();

  /// `POST /admin/community/groups` with `{name}`.
  Future<StudyGroup> createGroup(String name);
}

class ApiModerationRepository implements ModerationRepository {
  ApiModerationRepository(this.api);

  final ApiClient api;

  @override
  Future<List<ModerationItem>> reports() async => [
    for (final item in await api.get<List<dynamic>>(
      '/admin/moderation/reports',
    ))
      ModerationItem.fromJson(item as Map<String, dynamic>),
  ];

  @override
  Future<void> resolve(String reportId, ModerationAction action) =>
      api.post<Object?>(
        '/admin/moderation/reports/$reportId/resolve',
        data: {'action': action.name},
      );

  @override
  Future<List<StudyGroup>> groups() async => [
    for (final item in await api.get<List<dynamic>>('/admin/community/groups'))
      StudyGroup.fromJson(item as Map<String, dynamic>),
  ];

  @override
  Future<StudyGroup> createGroup(String name) async => StudyGroup.fromJson(
    await api.post<Map<String, dynamic>>(
      '/admin/community/groups',
      data: {'name': name},
    ),
  );
}

/// DEBUG ONLY (`USE_FAKE_API=true`): the queue from the Figma page.
class FakeModerationRepository implements ModerationRepository {
  final _reports = <ModerationItem>[
    const ModerationItem(
      id: 'r1',
      targetType: ReportTarget.post,
      reason: 'spam',
      authorHandle: 'kavindu_22',
      groupName: 'Unit 6 · Genetics',
      text: 'Join my WhatsApp for leaked 2026 papers 👉 bit.ly/...',
      aiFlagLabel: 'Spam / external link',
      aiFlagScore: 0.96,
      reportCount: 3,
    ),
    const ModerationItem(
      id: 'r2',
      targetType: ReportTarget.post,
      reason: 'offensive',
      authorHandle: 'sanduni.p',
      groupName: 'Unit 5 · Human body',
      text: 'This teacher is useless, anyone who uses BrAInBox is dumb',
      aiFlagLabel: 'Harassment',
      aiFlagScore: 0.88,
      reportCount: 2,
    ),
    const ModerationItem(
      id: 'r3',
      targetType: ReportTarget.post,
      reason: 'other',
      authorHandle: 'ruwan_bio',
      groupName: 'General',
      text: 'Answer for model paper Q12 is A, copy this for tomorrow',
      aiFlagLabel: 'Academic integrity',
      aiFlagScore: 0.71,
    ),
    const ModerationItem(
      id: 'r4',
      targetType: ReportTarget.visual,
      reason: 'unclear',
      details: 'Labels overlap',
      visualTitle: 'Nephron labelled diagram',
      reportCount: 4,
    ),
  ];

  final _groups = <StudyGroup>[
    const StudyGroup(
      id: 'g1',
      name: 'Unit 6 · Genetics',
      members: 1284,
      moderatorName: 'Ms. Tharushi',
    ),
    const StudyGroup(
      id: 'g2',
      name: 'Unit 5 · Human body',
      members: 1102,
      moderatorName: 'Mr. Dilan',
    ),
    const StudyGroup(
      id: 'g3',
      name: 'Unit 2 · Cell biology',
      members: 986,
      moderatorName: 'Ms. Tharushi',
    ),
    const StudyGroup(
      id: 'g4',
      name: 'Past paper discussion',
      members: 2240,
      moderatorName: 'Mr. Nuwan',
    ),
    const StudyGroup(id: 'g5', name: 'Exam stress & tips', members: 640),
    const StudyGroup(
      id: 'g6',
      name: 'Unit 4 · Plants',
      members: 512,
      moderatorName: 'Mr. Dilan',
    ),
  ];

  @override
  Future<List<ModerationItem>> reports() async => List.of(_reports);

  @override
  Future<void> resolve(String reportId, ModerationAction action) async =>
      _reports.removeWhere((r) => r.id == reportId);

  @override
  Future<List<StudyGroup>> groups() async => List.of(_groups);

  @override
  Future<StudyGroup> createGroup(String name) async {
    final group = StudyGroup(id: 'g${_groups.length + 1}', name: name);
    _groups.add(group);
    return group;
  }
}

@Riverpod(keepAlive: true)
ModerationRepository moderationRepository(Ref ref) => Env.useFakeApi
    ? FakeModerationRepository()
    : ApiModerationRepository(ref.watch(apiClientProvider));
