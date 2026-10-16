# Syllabus (mobile)

| | |
|---|---|
| **Owner** | Keshomigha (`@keshomigha`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Units list, unit detail and the topic page with tabs. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/syllabus` (tickets: `feature/syllabus/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Learn | `presentation/syllabus_screen.dart` | `/learn` |
| Unit detail | `presentation/unit_detail_screen.dart` | `/learn/units/:unitId` |
| Topic | `presentation/topic_screen.dart` | `/learn/topics/:topicId` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/units` | All units |
| `GET` | `/units/{unit_id}` | One unit with its topics |
| `GET` | `/topics/{topic_id}` | One topic with its concepts |

Shared models used: `Unit`, `Topic`, `Concept` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
syllabus/
├── domain/syllabus_models.dart              freezed models
├── data/syllabus_repository.dart            calls ApiClient (the only place that does)
├── application/syllabus_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/syllabus/` (same structure as this folder).
