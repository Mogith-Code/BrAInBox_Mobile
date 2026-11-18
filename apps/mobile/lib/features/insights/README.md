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
| Mastery map | `presentation/heatmap_screen.dart` | `/insights/heatmap` (overall, tap a topic -> quiz setup); with an attempt: `InsightsNav.openHeatmap` |
| Topic detail | `presentation/topic_insight_screen.dart` | `InsightsNav.openTopic` (Navigator push, no route constant yet) |
| Mistake journal | `presentation/mistake_journal_screen.dart` | `/insights/mistakes` (Recurring mistakes on top of the To fix tab) |

Practice and exam result screens can link to one attempt with:

```dart
context.push(InsightsNav.attemptLocation(attemptId));
```

## API endpoints

| Method | Path | Used by |
|---|---|---|
| `GET` | `/insights/topics` | Overview, single-attempt mastery map and topic detail (one request, shared through `insightsControllerProvider`) |
| `GET` | `/insights/topics?attempt_id=<uuid>` | "This attempt" mode |
| `GET` | `/insights/units` | Unit mastery card on the overview (loads on its own; pull-to-refresh reloads it) |
| `GET` | `/insights/overview` | Study time (bar chart, last 7 days) and Accuracy trend (line chart, days with answers in the last 14) on the overview. Loads on its own (`insightsOverviewProvider`). |
| `GET` | `/insights/heatmap` | Overall mastery map: every syllabus topic by unit, coloured by the backend's `level` (`topicHeatmapProvider`). |
| `GET` / `PATCH` | `/mistakes`, `/mistakes/{id}` | Mistake journal tabs and Mark fixed. |
| `GET` | `/mistakes/recurring` | "Recurring mistakes": misconceptions hit 3+ times in 14 days, with trend (Rising / Falling / Steady, icon + word + colour). |

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

### What the screens show (MCQ results only)

- **Overview:** mastery ring = `overall.percent`; legend = counts of the backend's topic statuses (strong → Mastered, good → Strong, developing → Improving, weak + very weak → Weak). Then the **Unit mastery** card (`/insights/units`: one bar per unit, Unit 1 first, coloured by the unit's `status`; `mastery: null` shows "—", never 0 %; "Finish a quiz…" when no unit is assessed), strongest / weakest, weak topics, not-enough-data topics, mastery map button, grade bands, note.
- **Overview charts:** Study time shows `study_minutes_week` and one bar per day; Accuracy trend plots only days whose `accuracy` is not null (no "0%" tick). A new student gets a sentence instead of an empty chart.
- **Mastery map (overall, `/insights/heatmap`):** one row per backend unit ("6 Genetics"), one cell per topic with its number and `mastery` ("—" when null). Levels map to the status colours: mastered -> strong, strong -> good, improving -> developing, weak -> weak, not_started -> not attempted. Tapping a cell opens `AppRoutes.quizSetupPath(topicId: ...)`.
- **Mastery map (one attempt, `/insights/topics?attempt_id=`):** rows from topic numbers, as before. Tapping a square opens the sheet (ring, unit, topic, status, questions tried, Open topic / Practice -> quiz setup for that topic).
- **Not shown yet:** the This week / This month selector and `mastery_history` (sent by the backend, no design for it yet).

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
- Not in this version (no backend data yet): weekly plan, recommendations, reassessment.

## Folders

```
insights/
├── domain/insights_models.dart              freezed models for GET /insights/topics
├── data/insights_repository.dart            calls ApiClient (the only place that does), maps errors
├── application/insights_controller.dart     Riverpod controller, family by attemptId
└── presentation/
    ├── insights_screen.dart                 overview / "This attempt"
    ├── heatmap_screen.dart                  mastery map + topic sheet
    ├── topic_insight_screen.dart            topic detail
    ├── mistake_journal_screen.dart          placeholder
    ├── insights_navigation.dart             InsightsNav (temporary routes)
    └── widgets/                             style, chips, ring, mastery card, map, cards, states
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/insights/` (same structure as this folder),
with sample responses in `test/features/insights/insights_fixtures.dart`.
