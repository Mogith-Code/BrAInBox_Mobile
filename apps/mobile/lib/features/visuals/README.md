# Visuals (mobile)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Diagram gallery, zoomable viewer and generate-visual flow. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/visuals` (tickets: `feature/visuals/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Diagrams | `presentation/diagram_gallery_screen.dart` | `/visuals` |
| Diagram viewer | `presentation/diagram_viewer_screen.dart` | `/visuals/view/:visualId` |
| Generate visual | `presentation/generate_visual_screen.dart` | `/visuals/generate` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/topics/{topic_id}/visuals` | Diagrams for a topic |
| `GET` | `/visuals/{visual_id}` | One diagram |
| `POST` | `/visuals/generate` | Start AI visual generation (returns a job id) |

Shared models used: `Visual`, `AiJob` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
visuals/
├── domain/visuals_models.dart              freezed models
├── data/visuals_repository.dart            calls ApiClient (the only place that does)
├── application/visuals_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/visuals/` (same structure as this folder).
