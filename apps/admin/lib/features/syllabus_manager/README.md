# SyllabusManager (admin)

| | |
|---|---|
| **Owner** | Keshomigha (`@keshomigha`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Unit -> Topic -> Concept tree editor. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-syllabus-manager` (tickets: `feature/admin-syllabus-manager/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Syllabus manager | `presentation/syllabus_manager_screen.dart` | `/syllabus` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/units` | Syllabus tree |
| `POST` | `/admin/units` | Create a unit (same for /admin/topics, /admin/concepts) |
| `PUT` | `/admin/topics/{topic_id}` | Edit a topic |
| `DELETE` | `/admin/concepts/{concept_id}` | Delete a concept |

Shared models used: `Unit`, `Topic`, `Concept` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
syllabus_manager/
├── domain/syllabus_manager_models.dart              freezed models
├── data/syllabus_manager_repository.dart            calls ApiClient (the only place that does)
├── application/syllabus_manager_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/syllabus_manager/` (same structure as this folder).
