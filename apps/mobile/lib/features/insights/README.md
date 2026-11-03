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

### What the screens show (MCQ results only)

- **Overview:** mastery ring = `overall.percent`; legend = counts of the backend's topic statuses (strong → Mastered, good → Strong, developing → Improving, weak + very weak → Weak). Then strongest / weakest, weak topics, not-enough-data topics, mastery map button, grade bands, note.
- **Mastery map:** one row per unit ("6 Genetics", unit number taken from the topic numbers), one square per topic with its percent, coloured by the backend's `status` (`StatusStyle.heatFill`). Rows are in unit-number order and squares in topic-number order; topics without a number go to the "Other" row, last. Tapping a square outlines it and opens a sheet (ring, unit, topic, status, questions tried, Open topic / Practice).
- **Not shown until the backend has data:** study time, accuracy trend, unit mastery, the This week / This month selector, the mistake journal and recurring mistakes. They are left out, not faked.

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
- **Backend (overview cards in Figma):** study time, accuracy trend and unit mastery need endpoints first (the backend README plans `/insights/summary` and `/insights/units`). Add the cards back when they exist.
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
