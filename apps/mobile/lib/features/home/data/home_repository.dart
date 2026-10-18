import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dev/fake_backend.dart';
import '../domain/home_models.dart';
import 'fake_home_repository.dart';

part 'home_repository.g.dart';

/// Home dashboard data. Only this layer calls the API.
abstract interface class HomeRepository {
  /// `GET /home/summary`
  Future<HomeSummary> summary();

  /// `PATCH /home/plan/{item_id}` with `{done}` - returns the updated item.
  Future<PlanItem> setPlanItemDone(String itemId, {required bool done});
}

class ApiHomeRepository implements HomeRepository {
  ApiHomeRepository(this.api);

  final ApiClient api;

  @override
  Future<HomeSummary> summary() async => HomeSummary.fromJson(
    await api.get<Map<String, dynamic>>('/home/summary'),
  );

  @override
  Future<PlanItem> setPlanItemDone(String itemId, {required bool done}) async =>
      PlanItem.fromJson(
        await api.patch<Map<String, dynamic>>(
          '/home/plan/$itemId',
          data: {'done': done},
        ),
      );
}

@Riverpod(keepAlive: true)
HomeRepository homeRepository(Ref ref) => Env.useFakeApi
    ? FakeHomeRepository(ref.watch(fakeBackendProvider))
    : ApiHomeRepository(ref.watch(apiClientProvider));
