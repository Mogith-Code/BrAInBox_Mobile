# QualityReview (admin)

| | |
|---|---|
| **Owner** | Udith (`@udith`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Queue of automatic checks on AI-generated questions. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-quality-review` (tickets: `feature/admin-quality-review/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Quality review | `presentation/quality_review_screen.dart` | `/quality-review` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/quality-checks` | Check queue |
| `POST` | `/admin/quality-checks/{check_id}/resolve` | Accept / fix / discard |

Shared models used: `Question` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
quality_review/
├── domain/quality_review_models.dart              freezed models
├── data/quality_review_repository.dart            calls ApiClient (the only place that does)
├── application/quality_review_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/quality_review/` (same structure as this folder).
