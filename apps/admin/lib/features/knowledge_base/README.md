# KnowledgeBase (admin)

| | |
|---|---|
| **Owner** | Keshomigha (`@keshomigha`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Model answers and marking keywords used by evaluation. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-knowledge-base` (tickets: `feature/admin-knowledge-base/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Knowledge base | `presentation/knowledge_base_screen.dart` | `/knowledge-base` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/model-answers` | Model answers |
| `POST` | `/admin/model-answers` | Add a model answer |
| `PUT` | `/admin/model-answers/{answer_id}/keywords` | Edit keywords |

## Folders

```
knowledge_base/
├── domain/knowledge_base_models.dart              freezed models
├── data/knowledge_base_repository.dart            calls ApiClient (the only place that does)
├── application/knowledge_base_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/knowledge_base/` (same structure as this folder).
