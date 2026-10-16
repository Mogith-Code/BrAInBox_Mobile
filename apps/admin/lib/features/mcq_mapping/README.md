# McqMapping (admin)

| | |
|---|---|
| **Owner** | Udith (`@udith`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Tag the misconception behind each wrong MCQ option. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-mcq-mapping` (tickets: `feature/admin-mcq-mapping/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| MCQ mapping | `presentation/mcq_mapping_screen.dart` | `/mcq-mapping` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/questions/{question_id}` | Question with options |
| `PUT` | `/admin/options/{option_id}/misconception` | Set the misconception tag |

Shared models used: `Question`, `McqOption` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
mcq_mapping/
├── domain/mcq_mapping_models.dart              freezed models
├── data/mcq_mapping_repository.dart            calls ApiClient (the only place that does)
├── application/mcq_mapping_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/mcq_mapping/` (same structure as this folder).
