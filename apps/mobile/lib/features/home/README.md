# Home (mobile)

| | |
|---|---|
| **Owner** | Samni (`@samni`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Dashboard: next best action and today's study plan. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/home` (tickets: `feature/home/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Home | `presentation/home_screen.dart` | `/home` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/home/summary` | Greeting, streak, next best action, today's plan |

Shared models used: `Recommendation` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
home/
├── domain/home_models.dart              freezed models
├── data/home_repository.dart            calls ApiClient (the only place that does)
├── application/home_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/home/` (same structure as this folder).
