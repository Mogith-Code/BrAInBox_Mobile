# Settings (mobile)

| | |
|---|---|
| **Owner** | Samni (`@samni`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Settings, privacy and about. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/settings` (tickets: `feature/settings/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Settings | `presentation/settings_screen.dart` | `/settings` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/me/settings` | Settings |
| `PUT` | `/me/settings` | Save settings |
| `DELETE` | `/me` | Delete account (privacy) |

## Folders

```
settings/
├── domain/settings_models.dart              freezed models
├── data/settings_repository.dart            calls ApiClient (the only place that does)
├── application/settings_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/settings/` (same structure as this folder).
