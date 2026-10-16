# Exams (mobile)

| | |
|---|---|
| **Owner** | Udith (`@udith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Past papers, model paper generator and exam mode. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/exams` (tickets: `feature/exams/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Past papers | `presentation/past_papers_screen.dart` | `/exams` |
| Generate model paper | `presentation/generate_paper_screen.dart` | `/exams/generate` |
| Exam mode | `presentation/exam_attempt_screen.dart` | `/exams/attempt/:paperId` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/past-papers` | List of past papers |
| `POST` | `/model-papers/generate` | Start model paper generation (returns a job id) |
| `POST` | `/exam-attempts` | Start an exam attempt |
| `POST` | `/exam-attempts/{attempt_id}/submit` | Submit answers |

Shared models used: `Question`, `AiJob` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
exams/
├── domain/exams_models.dart              freezed models
├── data/exams_repository.dart            calls ApiClient (the only place that does)
├── application/exams_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/exams/` (same structure as this folder).
