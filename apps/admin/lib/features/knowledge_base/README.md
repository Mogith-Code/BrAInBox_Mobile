# KnowledgeBase (admin)

| | |
|---|---|
| **Owner** | Keshomigha (`@keshomigha`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Model answers and marking keywords used by evaluation. |
| **Jira epic** | `BRN-??` *(TODO(keshomigha): add the epic key)* |
| **Git branch** | `feature/admin-knowledge-base` (tickets: `feature/admin-knowledge-base/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Knowledge base | `presentation/knowledge_base_screen.dart` | `/knowledge-base` |

## API endpoints it uses

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/model-answers?status=` | Model answers with marking points + keywords |
| `POST` | `/admin/model-answers` | Add one (`status: draft` or `approved`) with points `{text, marks, keywords}` |
| `PUT` | `/admin/model-answers/{answer_id}/keywords` | Replace the keywords of the changed points |
| `GET` | `/admin/questions?type=structured` / `essay` | Questions to write an answer for |

"Practisable" = approved **and** has marking points (that is what the backend's
evaluation uses). The backend has no route to approve an answer that is
already saved, so approving happens only when adding one ("Save and approve").

## Folders

```
knowledge_base/
├── domain/knowledge_base_models.dart              plain classes with fromJson
├── data/knowledge_base_repository.dart            calls ApiClient (the only place that does)
├── application/knowledge_base_controller.dart     plain Riverpod 3 providers
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/knowledge_base/` (same structure as this folder).
