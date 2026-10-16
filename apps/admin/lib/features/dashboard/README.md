# Dashboard (admin)

| | |
|---|---|
| **Owner** | Samni (`@samni`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | KPI tiles and recent activity. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-dashboard` (tickets: `feature/admin-dashboard/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Dashboard | `presentation/dashboard_screen.dart` | `/dashboard` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/dashboard` | KPIs and recent activity |

## Folders

```
dashboard/
├── domain/dashboard_models.dart              freezed models
├── data/dashboard_repository.dart            calls ApiClient (the only place that does)
├── application/dashboard_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/dashboard/` (same structure as this folder).
