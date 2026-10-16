import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/dashboard_models.dart';

part 'dashboard_repository.g.dart';

/// Data layer for the Dashboard feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class DashboardRepository {
  DashboardRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Dashboard screen.
  Future<DashboardSummary> fetchSummary() async {
    // TODO(samni): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/admin/dashboard');
    // return DashboardSummary.fromJson(json);
    return const DashboardSummary(
      title: 'Dashboard',
      message: 'Placeholder data - API not connected yet.',
    );
  }
}

@riverpod
DashboardRepository dashboardRepository(Ref ref) =>
    DashboardRepository(ref.watch(apiClientProvider));
