# Practice (mobile)

| | |
|---|---|
| **Owner** | Udith (`@udith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Practice hub, quiz setup, MCQ flow, feedback, results and the diagnostic test. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/practice` (tickets: `feature/practice/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Practice | `presentation/practice_hub_screen.dart` | `/practice` |
| Quiz setup | `presentation/quiz_setup_screen.dart` | `/practice/setup` |
| MCQ question | `presentation/mcq_question_screen.dart` | `/practice/quiz` |
| Answer feedback | `presentation/answer_feedback_screen.dart` | `/practice/feedback` |
| Quiz result | `presentation/quiz_result_screen.dart` | `/practice/result` |
| Diagnostic test | `presentation/diagnostic_screen.dart` | `/practice/diagnostic` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/practice/hub` | In-progress quizzes and suggestions |
| `POST` | `/quizzes` | Create a quiz from the setup options |
| `GET` | `/quizzes/{quiz_id}/questions` | Questions for a quiz |
| `POST` | `/quizzes/{quiz_id}/answers` | Submit one answer, get feedback |
| `GET` | `/quizzes/{quiz_id}/result` | Final result |
| `POST` | `/diagnostic` | Start the diagnostic test |

Shared models used: `Question`, `McqOption` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
practice/
├── domain/practice_models.dart              freezed models
├── data/practice_repository.dart            calls ApiClient (the only place that does)
├── application/practice_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/practice/` (same structure as this folder).
