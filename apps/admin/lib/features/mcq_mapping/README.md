# McqMapping (admin)

| | |
|---|---|
| **Owner** | Udith (`@udith`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Tag the misconception behind each wrong MCQ option. |
| **Jira epic** | `BRN-??` *(TODO(udith): add the epic key)* |
| **Git branch** | `feature/admin-mcq-mapping` (tickets: `feature/admin-mcq-mapping/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| MCQ mapping | `presentation/mcq_mapping_screen.dart` | `/mcq-mapping` |

## API endpoints it uses

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/questions?type=mcq&page=` | MCQs to pick from (question bank repository) |
| `GET` / `PUT` | `/admin/questions/{question_id}` | Load / save the MCQ: 5 options, correct answer, explanation, misconceptions, unit/topic/concept (keeps its status) |
| `POST` | `/admin/questions/{question_id}/misconception-suggestions` | "Suggest with AI" (MAP_MISCONCEPTIONS job, polled with `JobPoller`) |
| `PUT` | `/admin/options/{option_id}/misconception` | Save one accepted suggestion |

Route `/mcq-mapping?questionId=` (`AdminRoutes.mcqMappingPath`). Nothing the AI
suggests is saved until the admin presses "Accept" for that option. The
student preview uses `McqOptionTile` from brainbox_core.

## Folders

```
mcq_mapping/
├── domain/mcq_mapping_models.dart              plain classes with fromJson
├── data/mcq_mapping_repository.dart            calls ApiClient (the only place that does)
├── application/mcq_mapping_controller.dart     plain Riverpod 3 providers
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/mcq_mapping/` (same structure as this folder).
