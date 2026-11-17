# Analytics (admin)

| | |
|---|---|
| **Owner** | Keshomigha (`@keshomigha`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Most-missed topics and most common misconceptions. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-analytics` (tickets: `feature/admin-analytics/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Analytics | `presentation/analytics_screen.dart` | `/analytics` |

## API endpoints it uses

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/analytics/overview?days=` | Students and daily activity |
| `GET` | `/admin/analytics/performance?days=` | Mastery per unit, misconceptions |
| `GET` | `/admin/analytics/ai-usage?days=` | AI requests per feature |
| `GET` | `/admin/evaluations/accuracy` | Evaluation accuracy card (AI vs teacher marks, all time) |
| `GET` | `/admin/evaluations?page=&size=&only_manual=` | Evaluations table |
| `PATCH` | `/admin/evaluations/{id}` | Save a teacher's marks (`{manual_marks}`, 0..max marks) |

Evaluation code is plain classes + plain Riverpod providers:
`domain/evaluation_models.dart`, `data/evaluations_repository.dart`,
`application/evaluations_controller.dart`,
`presentation/widgets/evaluation_accuracy.dart`.

## Folders

```
analytics/
├── domain/analytics_models.dart              freezed models
├── data/analytics_repository.dart            calls ApiClient (the only place that does)
├── application/analytics_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/analytics/` (same structure as this folder).
