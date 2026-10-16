# Upload (mobile)

| | |
|---|---|
| **Owner** | Samni (`@samni`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Upload notes (PDF / photo), show processing, then the AI summary. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/upload` (tickets: `feature/upload/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Upload notes | `presentation/upload_screen.dart` | `/upload` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/uploads` | Multipart upload (returns a job id) |
| `GET` | `/jobs/{job_id}` | Processing status (use JobPoller) |
| `GET` | `/uploads/{upload_id}/summary` | AI summary of the upload |

Shared models used: `AiJob` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
upload/
├── domain/upload_models.dart              freezed models
├── data/upload_repository.dart            calls ApiClient (the only place that does)
├── application/upload_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/upload/` (same structure as this folder).
