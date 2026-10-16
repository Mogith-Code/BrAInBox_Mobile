import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/home_models.dart';

part 'home_repository.g.dart';

/// Data layer for the Home feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class HomeRepository {
  HomeRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Home screen.
  Future<HomeSummary> fetchSummary() async {
    // TODO(samni): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/home/summary');
    // return HomeSummary.fromJson(json);
    return const HomeSummary(
      title: 'Home',
      message: 'Placeholder data - API not connected yet.',
    );
  }
}

@riverpod
HomeRepository homeRepository(Ref ref) =>
    HomeRepository(ref.watch(apiClientProvider));
