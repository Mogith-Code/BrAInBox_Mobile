# Recommendations (mobile)

| | |
|---|---|
| **Owner** | Udith (`@udith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Next steps, resources, study plan and reassessment. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/recommendations` (tickets: `feature/recommendations/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Next steps | `presentation/next_steps_screen.dart` | `/recommendations` |
| Study plan | `presentation/study_plan_screen.dart` | `/recommendations/study-plan` |
| Reassessment | `presentation/reassessment_screen.dart` | `/recommendations/reassessment` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/recommendations` | Next steps + resources |
| `GET` | `/study-plan` | The student's study plan |
| `POST` | `/reassessments` | Start a reassessment |

Shared models used: `Recommendation` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
recommendations/
├── domain/recommendations_models.dart              freezed models
├── data/recommendations_repository.dart            calls ApiClient (the only place that does)
├── application/recommendations_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/recommendations/` (same structure as this folder).
