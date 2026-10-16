# Users (admin)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Student list and suspend / unsuspend. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-users` (tickets: `feature/admin-users/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Users | `presentation/users_screen.dart` | `/users` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/users` | Students (search, paging) |
| `POST` | `/admin/users/{user_id}/suspend` | Suspend |
| `POST` | `/admin/users/{user_id}/unsuspend` | Unsuspend |

Shared models used: `AppUser` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
users/
├── domain/users_models.dart              freezed models
├── data/users_repository.dart            calls ApiClient (the only place that does)
├── application/users_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/users/` (same structure as this folder).
