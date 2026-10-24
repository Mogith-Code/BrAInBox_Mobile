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
| Let's find your starting point (Figma A12) | `presentation/diagnostic_screen.dart` | `/diagnostic` |
| Diagnostic question (not in Figma) | `presentation/diagnostic_question_screen.dart` | `/diagnostic/questions` |
| Your starting point (Figma A13) | `presentation/diagnostic_result_screen.dart` | `/diagnostic/result` |
| Practice hub, quiz setup, MCQ, feedback, result | placeholders | `/practice/...` |

The diagnostic is outside the bottom nav. `application/diagnostic_controller.dart`
resumes at the first unanswered question, saves each answer
(`POST /diagnostic/{id}/answer`) before moving on, submits after the last one,
and handles Skip for now and `NOT_ENOUGH_QUESTIONS`.

### Diagnostic endpoints

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/diagnostic/start` | Start or resume the attempt |
| `POST` | `/diagnostic/{attempt_id}/answer` | Save one answer |
| `POST` | `/diagnostic/{attempt_id}/submit` | Finish -> result |
| `POST` | `/diagnostic/skip` | Skip for now |
| `GET` | `/diagnostic/result` | Result after a restart |

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
