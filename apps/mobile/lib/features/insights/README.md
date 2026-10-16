# Insights (mobile)

| | |
|---|---|
| **Owner** | Keshomigha (`@keshomigha`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Mastery overview, topic heatmap and the mistake journal (fl_chart). |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/insights` (tickets: `feature/insights/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Insights | `presentation/insights_screen.dart` | `/insights` |
| Heatmap | `presentation/heatmap_screen.dart` | `/insights/heatmap` |
| Mistake journal | `presentation/mistake_journal_screen.dart` | `/insights/mistakes` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/insights/mastery` | Mastery per unit / topic |
| `GET` | `/insights/heatmap` | Heatmap data |
| `GET` | `/mistakes` | Mistake journal entries |

Shared models used: `Mistake`, `Topic` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
insights/
├── domain/insights_models.dart              freezed models
├── data/insights_repository.dart            calls ApiClient (the only place that does)
├── application/insights_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/insights/` (same structure as this folder).
