# Insights (mobile)

| | |
|---|---|
| **Owner** | Keshomigha (`@keshomigha`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Per-topic results: overview, mastery map (heatmap), topic detail. Mistake journal later. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/insights` (tickets: `feature/insights-BRN-xx-short-name`) |

## Screens

| Screen | File | How it opens |
|---|---|---|
| Insights overview | `presentation/insights_screen.dart` | `/insights` (bottom-nav tab) |
| This attempt (single attempt) | `presentation/insights_screen.dart` | `/insights?attempt_id=<id>`, built with `InsightsNav.attemptLocation(id)` |
| Mastery map | `presentation/heatmap_screen.dart` | `/insights/heatmap`; with an attempt: `InsightsNav.openHeatmap` |
| Topic detail | `presentation/topic_insight_screen.dart` | `InsightsNav.openTopic` (Navigator push, no route constant yet) |
| Mistake journal | `presentation/mistake_journal_screen.dart` | `/insights/mistakes` (placeholder) |

Practice and exam result screens can link to one attempt with:

```dart
context.push(InsightsNav.attemptLocation(attemptId));
```

## API endpoints

| Method | Path | Used by |
|---|---|---|
| `GET` | `/insights/topics` | Overview, mastery map and topic detail (one request, shared through `insightsControllerProvider`) |
| `GET` | `/insights/topics?attempt_id=<uuid>` | "This attempt" mode |
| `GET` | `/insights/summary?period=week\|month\|all` | Overview cards: mastery ring, study time, accuracy trend, unit mastery. **Backend not built yet** (see below). |
| `GET` | `/mistakes` | Mistake journal. **Backend not built yet.** |

### Rules the screens follow

- `percent`, `grade` and `grade_label` can be null: shown as "Not attempted" (or "—" in rings), never 0 %.
- `topics` is ranked weakest first by the backend; the app keeps that order and never recomputes percent, grade or status.
- `topic_id` can be null (the "General" group). Feedback is matched by `topic_id`, or by `topic` name when the id is null.
- `reliable: false`: percent faded and "Needs N more questions" (N = `min_questions_per_topic - attempted`).
- Grade legend comes from `grade_bands`; `note` is always shown in the Formative-feedback box.
- Unknown `status` and `resource_type` values fall back to `unknown` (generic icon), so new backend values never crash the app.
- Every status is shown with colour + icon + label. All colours are chosen in `presentation/widgets/insights_style.dart`, using `AppColors` tokens only:

  | Level | Colour | Soft background | Text on soft |
  |---|---|---|---|
  | Strong / Mastered (75 %+) | `success` | `successSoft` | `successDark` |
  | Good / Strong (55–75 %) | `secondary` | `secondarySoft` | `secondaryDark` |
  | Developing / Improving (35–55 %) | `warning` | `warningSoft` | `warningDark` |
  | Weak / Very weak (below 35 %) | `error` | `errorSoft` | `error` |
  | Not enough data / not attempted | `mutedLight` | `surfaceMuted` | `muted` |
- Results are calculated, not AI-generated, so there is no `AiBadge`.

### `GET /insights/summary` (contract for the backend)

Response (snake_case, every section may be `null`):

```json
{
  "period": "week", "period_start": "2026-10-26", "period_end": "2026-11-01",
  "mastery": { "percent": 62.0, "bands": [
    { "key": "mastered", "label": "Mastered", "topic_count": 11 },
    { "key": "strong", "label": "Strong", "topic_count": 24 },
    { "key": "improving", "label": "Improving", "topic_count": 38 },
    { "key": "weak", "label": "Weak", "topic_count": 19 } ] },
  "study_time": { "total_minutes": 822, "bars": [
    { "label": "M", "date": "2026-10-26", "minutes": 90, "highlight": false } ] },
  "accuracy_trend": { "change_points": 22.0, "window_label": "8 wks", "points": [
    { "label": "W1", "period_start": "2026-09-07", "percent": 52.0 } ] },
  "units": [ { "unit_id": "…", "unit_number": 1, "name": "Introduction to biology",
               "percent": 88.0, "status": "strong" } ]
}
```

- The app only displays these values; it never computes percent, change or totals.
- `bars`: 7 days for `week`, weeks for `month`, months for `all`; `highlight` marks today / the current bar.
- `points[].percent` can be `null` (a week with no answers is drawn as a gap).
- `units[].status` uses the same values as topic `status`.
- Until the endpoint exists the backend answers 404: study time, trend and units show "Coming soon", and the mastery ring falls back to `/insights/topics` (overall percent; strong → Mastered, good → Strong, developing → Improving, weak + very weak → Weak).

### Errors

| Backend answer | Screen shows |
|---|---|
| 401 `USER_NOT_REGISTERED` | Goes to profile setup (`AppRoutes.profileSetup`) |
| 403 / 404 | "This result isn't available" + Back |
| 422 | Logged as a bug (`debugPrint`), generic error + Retry |
| No connection / timeout | Offline state + Retry |
| 5xx / other | `ErrorBanner` + Retry |

A failed pull-to-refresh keeps the old data on screen with an `ErrorBanner` above it.

## Still to do

- **Routes (Samni):** add `AppRoutes.insightsTopic` (`/insights/topics/:topicKey`) and `AppRoutes.insightsAttempt` (`/insights/attempts/:attemptId`), then replace the Navigator pushes and the `attempt_id` query in `presentation/insights_navigation.dart`.
- **Practice button** on the mastery-map sheet opens the Practice tab; it should open practice for that topic once Udith's practice feature accepts a topic id.
- **Mistake journal:** needs `GET /mistakes`.
- **Backend:** build `GET /insights/summary` (contract above).
- Not in this version (no backend data yet): weekly plan, recommendations, reassessment.

## Folders

```
insights/
├── domain/insights_models.dart              freezed models for GET /insights/topics
├── domain/insights_summary.dart             freezed models for GET /insights/summary
├── data/insights_repository.dart            calls ApiClient (the only place that does), maps errors
├── application/insights_controller.dart     Riverpod controller, family by attemptId
└── presentation/
    ├── insights_screen.dart                 overview / "This attempt"
    ├── heatmap_screen.dart                  mastery map + topic sheet
    ├── topic_insight_screen.dart            topic detail
    ├── mistake_journal_screen.dart          placeholder
    ├── insights_navigation.dart             InsightsNav (temporary routes)
    └── widgets/                             style, chips, ring, cards, summary cards, states
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/insights/` (same structure as this folder),
with sample responses in `test/features/insights/insights_fixtures.dart`.
