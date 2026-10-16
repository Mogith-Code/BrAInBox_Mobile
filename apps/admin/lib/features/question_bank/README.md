# QuestionBank (admin)

| | |
|---|---|
| **Owner** | Udith (`@udith`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Question table with filters and bulk import. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-question-bank` (tickets: `feature/admin-question-bank/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Question bank | `presentation/question_bank_screen.dart` | `/question-bank` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/questions` | Questions (filters as query params) |
| `POST` | `/admin/questions` | Create a question |
| `POST` | `/admin/questions/import` | Bulk import (multipart CSV) |

Shared models used: `Question`, `McqOption` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
question_bank/
├── domain/question_bank_models.dart              freezed models
├── data/question_bank_repository.dart            calls ApiClient (the only place that does)
├── application/question_bank_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/question_bank/` (same structure as this folder).
