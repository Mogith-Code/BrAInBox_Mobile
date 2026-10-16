# Splash (mobile)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Splash screen and start-up redirect (onboarding / login / home). |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/splash` (tickets: `feature/splash/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Splash | `presentation/splash_screen.dart` | `/` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

None - this feature only uses local state (shared_preferences / auth state).

## Folders

```
splash/
├── domain/splash_models.dart              freezed models
├── data/splash_repository.dart            calls ApiClient (the only place that does)
├── application/splash_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/splash/` (same structure as this folder).
