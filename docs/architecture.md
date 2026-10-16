# Architecture

## Summary

- **Two apps, one shared package.** `apps/mobile` (Android student app) and
  `apps/admin` (web admin portal) both depend on `packages/brainbox_core`.
  It holds the models, API client, auth state, theme and UI kit.
- **State:** Riverpod (`flutter_riverpod` + `riverpod_annotation` /
  `riverpod_generator`). Providers are written with `@riverpod` and generated
  with `melos run gen`.
- **Navigation:** `go_router`. Every route is declared in the app's
  `app/router.dart`. The student app uses a `StatefulShellRoute` for the
  bottom navigation (Home, Learn, Practice, Insights, Community). The admin
  portal uses a `ShellRoute` for the sidebar layout.
- **Networking:** `dio`, wrapped by `ApiClient` in `brainbox_core`.
- **Models:** `freezed` + `json_serializable`. JSON keys are snake_case
  (`topic_id`). This is set once in each package's `build.yaml`.
- **Auth:** Firebase Auth on the device. The backend verifies the Firebase ID
  token on every request.
- **Offline cache:** `hive` / `hive_flutter`, opened in `apps/mobile/lib/main.dart`.

## The layering rule

Every feature folder has the same four layers:

```
<feature>/
├── presentation/   screens + widgets (UI only)
├── application/    Riverpod controllers / providers (state)
├── data/           repository classes that call the API client
└── domain/         freezed models for this feature
```

```
 ┌──────────────┐   ref.watch / methods   ┌──────────────┐   calls   ┌──────────────┐   HTTP   ┌───────────┐
 │    Screen    │ ──────────────────────► │  Controller  │ ────────► │  Repository  │ ───────► │ ApiClient │ ──► FastAPI
 │ presentation │ ◄────────────────────── │ application  │ ◄──────── │     data     │ ◄─────── │  (core)   │
 └──────────────┘     AsyncValue<T>       └──────────────┘  models   └──────────────┘   JSON   └───────────┘
```

| Layer | May use | Must NOT use |
|---|---|---|
| `presentation/` | Flutter widgets, `brainbox_core` widgets/theme, controllers via `ref` | Dio, Firebase, repositories, `ApiClient` |
| `application/` | repositories, other providers | Flutter widgets, Dio |
| `data/` | `ApiClient`, Firebase Auth (in `auth/` only), Hive | widgets, controllers |
| `domain/` | `freezed_annotation`, `brainbox_core` models | everything else |

### Example (from the `home` feature)

```dart
// data/home_repository.dart
class HomeRepository {
  HomeRepository(this.api);
  final ApiClient api;

  Future<HomeSummary> fetchSummary() async =>
      HomeSummary.fromJson(await api.get<Map<String, dynamic>>('/home/summary'));
}

// application/home_controller.dart
@riverpod
class HomeController extends _$HomeController {
  @override
  Future<HomeSummary> build() => ref.watch(homeRepositoryProvider).fetchSummary();
}

// presentation/home_screen.dart
final state = ref.watch(homeControllerProvider);
return state.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => ErrorBanner(message: '$e'),
  data: (summary) => Text(summary.title),
);
```

## Cross-cutting pieces in `brainbox_core`

| Piece | File | What it does |
|---|---|---|
| `Env` | `config/env.dart` | `API_BASE_URL` and debug flags from `--dart-define` |
| `FirebaseSetup` | `config/firebase_setup.dart` | Starts Firebase; never crashes if not configured |
| `ApiClient` | `api/api_client.dart` | Dio with base URL, timeouts, debug logging |
| `AuthInterceptor` | `api/auth_interceptor.dart` | Adds the Firebase ID token; on 401 refreshes once and retries |
| `ApiException` | `api/api_exception.dart` | Maps `{"error": {"code", "message"}}` to a Dart exception |
| `JobPoller` | `api/job_poller.dart` | Polls `GET /jobs/{id}` for slow AI work |
| `currentUserProvider` | `auth/current_user_provider.dart` | The signed-in `AppUser` (or `null`) |
| Theme | `theme/` | `AppColors`, `AppTypography` (Poppins/Inter), `AppSpacing`, `AppTheme` |
| UI kit | `widgets/` | `AppButton`, `AppTextField`, `AiBadge`, `MasteryRing`, `McqOptionTile`... |

## Slow AI work

Generating notes, visuals and papers, and evaluating answers, can take a
while. The backend answers right away with a job id. The repository then
uses `JobPoller` to wait, and the screen shows `AiGeneratingLoader` until the
job is done.

## Routing and guards

- Student app: signed-out users are sent to `/auth/login`, except on the
  public routes (splash, onboarding, auth).
- Admin portal: only users with role `admin` get past `/login`.
- Both guards are **off** when Firebase is not configured, or when running
  with `--dart-define=DISABLE_AUTH_GUARD=true` in debug builds.
