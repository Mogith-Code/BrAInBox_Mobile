# Onboarding (mobile)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Welcome carousel shown on first launch. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/onboarding` (tickets: `feature/onboarding/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Onboarding | `presentation/onboarding_screen.dart` | `/onboarding` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

None - this feature only uses local state (shared_preferences / auth state).

## Folders

```
onboarding/
├── domain/onboarding_models.dart              freezed models
├── data/onboarding_repository.dart            calls ApiClient (the only place that does)
├── application/onboarding_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/onboarding/` (same structure as this folder).
