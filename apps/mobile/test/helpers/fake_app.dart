import 'package:brainbox_mobile/app/dev/fake_backend.dart';
import 'package:brainbox_mobile/features/auth/application/session_controller.dart';
import 'package:brainbox_mobile/features/auth/data/auth_repository.dart';
import 'package:brainbox_mobile/features/auth/data/fake_auth_repository.dart';
import 'package:brainbox_mobile/features/practice/data/diagnostic_repository.dart';
import 'package:brainbox_mobile/features/practice/data/fake_diagnostic_repository.dart';
import 'package:brainbox_mobile/features/profile/data/fake_profile_repository.dart';
import 'package:brainbox_mobile/features/profile/data/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

/// Overrides that run the app on the in-memory [FakeBackend] (like
/// `USE_FAKE_API=true`), with the onboarding redirect switched on.
///
/// Later features add their fake repositories here.
List<Override> fakeOverrides(FakeBackend backend) => [
  fakeBackendProvider.overrideWithValue(backend),
  authRepositoryProvider.overrideWithValue(FakeAuthRepository(backend)),
  profileRepositoryProvider.overrideWithValue(FakeProfileRepository(backend)),
  diagnosticRepositoryProvider.overrideWithValue(
    FakeDiagnosticRepository(backend),
  ),
  authGuardEnabledProvider.overrideWithValue(true),
];

/// A container on the fake backend. [welcomeSeen] presets the flag.
ProviderContainer fakeContainer({
  FakeBackend? backend,
  bool welcomeSeen = true,
  List<Override> overrides = const [],
}) {
  SharedPreferences.setMockInitialValues({'welcome_seen': welcomeSeen});
  return ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      ...fakeOverrides(backend ?? FakeBackend(latency: Duration.zero)),
      ...overrides,
    ],
  );
}
