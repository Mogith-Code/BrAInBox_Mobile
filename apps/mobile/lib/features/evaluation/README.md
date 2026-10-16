# Evaluation (mobile)

| | |
|---|---|
| **Owner** | Keshomigha (`@keshomigha`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Typed answers, handwritten upload + OCR preview, and AI feedback. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/evaluation` (tickets: `feature/evaluation/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Typed answer | `presentation/typed_answer_screen.dart` | `/evaluation/typed/:questionId` |
| Handwritten answer | `presentation/handwritten_upload_screen.dart` | `/evaluation/handwritten/:questionId` |
| OCR preview | `presentation/ocr_preview_screen.dart` | `/evaluation/ocr-preview` |
| Answer feedback | `presentation/evaluation_feedback_screen.dart` | `/evaluation/feedback/:evaluationId` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/evaluations/typed` | Evaluate a typed answer (returns a job id) |
| `POST` | `/evaluations/handwritten` | Multipart photo upload, OCR + evaluation (job id) |
| `GET` | `/evaluations/{evaluation_id}` | Evaluation result |

Shared models used: `Question`, `AiJob` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
evaluation/
├── domain/evaluation_models.dart              freezed models
├── data/evaluation_repository.dart            calls ApiClient (the only place that does)
├── application/evaluation_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/evaluation/` (same structure as this folder).
