import 'package:brainbox_core/brainbox_core.dart';

import '../../../app/dev/fake_backend.dart';
import '../domain/home_models.dart';
import 'home_repository.dart';

/// DEBUG ONLY: [HomeRepository] on the in-memory [FakeBackend], with the
/// numbers from the Figma Home dashboard (12-day streak, 287 days, 62%...).
class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository(this.backend);

  final FakeBackend backend;

  static const _plan = [
    ('plan-1', 'Recap: Dihybrid crosses', 10, 'Unit 6'),
    ('plan-2', 'Practice: 10 MCQs Nephron', 15, 'Unit 5'),
    ('plan-3', 'Read short notes: Enzymes', 5, 'Unit 2'),
  ];

  List<PlanItem> _items(FakeAccount account) => [
    for (final (id, title, minutes, unit) in _plan)
      PlanItem(
        id: id,
        title: title,
        minutes: minutes,
        unitLabel: unit,
        done: account.planDone[id] ?? false,
      ),
  ];

  @override
  Future<HomeSummary> summary() async {
    await backend.delay();
    final account = backend.requireSignedIn();
    final items = _items(account);
    final skipped =
        account.onboarding.diagnosticSkipped &&
        !account.onboarding.diagnosticCompleted;

    return HomeSummary(
      greetingName: account.toUser().firstName,
      initials: Formatters.initials(account.fullName),
      streakDays: 12,
      daysToExam: 287,
      nextBestAction: skipped
          ? const NextBestAction(
              type: 'diagnostic',
              title: 'Find your starting point',
              reason:
                  'A quick 10-minute check so your plan fits where you are.',
              buttonLabel: 'Start diagnostic',
              minutes: 10,
            )
          : const NextBestAction(
              type: 'revision',
              title: 'Revise: Dihybrid crosses',
              reason:
                  'You missed 4 of 5 recently — mostly the 9:3:3:1 ratio step.',
              buttonLabel: 'Start 10-min revision',
              minutes: 10,
              target: ActionTarget(unitCode: 'U6', topicId: 't-dihybrid'),
              aiGenerated: true,
            ),
      todaysPlan: TodaysPlan(
        done: items.where((i) => i.done).length,
        total: items.length,
        items: items,
      ),
      overallMastery: 62,
      masteryChangeWeek: 4,
      continueLearning: const [
        ContinueItem(
          topicId: 't-nephron',
          title: 'Nephron & osmoregulation',
          unitCode: 'U5',
          progress: 48,
        ),
        ContinueItem(
          topicId: 't-dihybrid',
          title: 'Dihybrid crosses',
          unitCode: 'U6',
          progress: 72,
        ),
        ContinueItem(
          topicId: 't-enzymes',
          title: 'Enzymes',
          unitCode: 'U2',
          progress: 35,
        ),
      ],
    );
  }

  @override
  Future<PlanItem> setPlanItemDone(String itemId, {required bool done}) async {
    await backend.delay();
    final account = backend.requireSignedIn();
    account.planDone[itemId] = done;
    return _items(account).firstWhere((i) => i.id == itemId);
  }
}
