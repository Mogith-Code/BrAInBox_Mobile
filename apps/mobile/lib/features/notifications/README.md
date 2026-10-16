# Notifications (mobile)

| | |
|---|---|
| **Owner** | Samni (`@samni`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Notification center. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/notifications` (tickets: `feature/notifications/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Notifications | `presentation/notifications_screen.dart` | `/notifications` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/notifications` | Notifications |
| `POST` | `/notifications/{notification_id}/read` | Mark as read |

## Folders

```
notifications/
├── domain/notifications_models.dart              freezed models
├── data/notifications_repository.dart            calls ApiClient (the only place that does)
├── application/notifications_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/notifications/` (same structure as this folder).
