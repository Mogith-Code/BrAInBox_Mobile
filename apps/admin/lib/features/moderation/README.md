# Moderation (admin)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Reported / flagged posts and groups. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-moderation` (tickets: `feature/admin-moderation/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Moderation | `presentation/moderation_screen.dart` | `/moderation` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/reports` | Open reports |
| `POST` | `/admin/posts/{post_id}/hide` | Hide a post |
| `POST` | `/admin/groups/{group_id}/lock` | Lock a group |

Shared models used: `CommunityPost` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
moderation/
├── domain/moderation_models.dart              freezed models
├── data/moderation_repository.dart            calls ApiClient (the only place that does)
├── application/moderation_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/moderation/` (same structure as this folder).
