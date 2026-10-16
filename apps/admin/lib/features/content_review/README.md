# ContentReview (admin)

| | |
|---|---|
| **Owner** | Samni (`@samni`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Approve, edit or reject AI notes, short notes and images. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-content-review` (tickets: `feature/admin-content-review/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Content review | `presentation/content_review_screen.dart` | `/content-review` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/content?status=pending` | Review queue |
| `PUT` | `/admin/content/{content_id}` | Edit content |
| `POST` | `/admin/content/{content_id}/approve` | Approve |
| `POST` | `/admin/content/{content_id}/reject` | Reject with a reason |

Shared models used: `Note`, `Visual` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
content_review/
├── domain/content_review_models.dart              freezed models
├── data/content_review_repository.dart            calls ApiClient (the only place that does)
├── application/content_review_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/content_review/` (same structure as this folder).
