# Notes (mobile)

| | |
|---|---|
| **Owner** | Samni (`@samni`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | AI notes, short notes, the generate-notes sheet and the notes library. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/notes` (tickets: `feature/notes/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Topic notes | `presentation/topic_notes_screen.dart` | `/notes/topics/:topicId` |
| Short notes | `presentation/short_notes_screen.dart` | `/notes/topics/:topicId/short` |
| Notes library | `presentation/library_screen.dart` | `/notes/library` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/topics/{topic_id}/notes` | AI notes for a topic |
| `GET` | `/topics/{topic_id}/short-notes` | Short notes for a topic |
| `POST` | `/topics/{topic_id}/notes/generate` | Start AI note generation (returns a job id) |
| `GET` | `/notes/library` | The student's saved notes |

Shared models used: `Note`, `AiJob` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
notes/
├── domain/notes_models.dart              freezed models
├── data/notes_repository.dart            calls ApiClient (the only place that does)
├── application/notes_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/notes/` (same structure as this folder).
