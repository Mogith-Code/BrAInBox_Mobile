# Analytics (admin)

| | |
|---|---|
| **Owner** | Keshomigha (`@keshomigha`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Most-missed topics and most common misconceptions. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-analytics` (tickets: `feature/admin-analytics/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Analytics | `presentation/analytics_screen.dart` | `/analytics` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/analytics/most-missed-topics` | Most-missed topics |
| `GET` | `/admin/analytics/misconceptions` | Most common misconceptions |

Shared models used: `Topic`, `Mistake` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
analytics/
├── domain/analytics_models.dart              freezed models
├── data/analytics_repository.dart            calls ApiClient (the only place that does)
├── application/analytics_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/analytics/` (same structure as this folder).
