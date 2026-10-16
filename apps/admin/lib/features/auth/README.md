# Auth (admin)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Admin login. Only users with role "admin" get past the router guard. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-auth` (tickets: `feature/admin-auth/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Admin login | `presentation/login_screen.dart` | `/login` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/me` | Check the signed-in user's role |

Shared models used: `AppUser` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
auth/
├── domain/auth_models.dart              freezed models
├── data/auth_repository.dart            calls ApiClient (the only place that does)
├── application/auth_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/auth/` (same structure as this folder).
