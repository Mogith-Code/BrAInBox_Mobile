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
| Exam mode | `presentation/exam_attempt_screen.dart` | `/exams/attempt/:paperId?hide_outdated=true` |
| Result | `presentation/exam_result_screen.dart` | `/exams/result` |

## API endpoints

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/papers?year=&type=` | Approved past papers |
| `GET` | `/papers/{id}?hide_outdated=` | One paper's questions (no answers) |
| `POST` | `/papers/generate` | Model paper from a blueprint: 202 + job, polled with `JobPoller` |
| `POST` | `/papers/{id}/submit` | MCQ letters + structured / essay text; written answers are marked in the background |

Exam mode has a tab per question type (Part I MCQ, Part II structured,
essay), a question palette (answered / unanswered / flagged, each with icon,
word and colour) and a submit confirmation.

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
