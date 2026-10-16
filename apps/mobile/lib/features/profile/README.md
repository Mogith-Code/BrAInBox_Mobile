# Profile (mobile)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Profile setup: stream, exam year, goals, daily study time. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/profile` (tickets: `feature/profile/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Profile setup | `presentation/profile_screen.dart` | `/profile/setup` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/me` | Current profile |
| `PUT` | `/me/profile` | Save stream, exam year, goals, study time |

Shared models used: `AppUser` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
profile/
├── domain/profile_models.dart              freezed models
├── data/profile_repository.dart            calls ApiClient (the only place that does)
├── application/profile_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/profile/` (same structure as this folder).
