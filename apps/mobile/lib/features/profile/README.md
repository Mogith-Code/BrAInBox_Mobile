# Profile (mobile)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Profile setup: stream, exam year, goals, daily study time. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/profile` (tickets: `feature/profile/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Setup 1/3 What are you studying? (A9) | `presentation/profile_screen.dart` + `widgets/setup_steps.dart` (`StreamStep`) | `/profile/setup` |
| Setup 2/3 Set your goal (A10) | same screen (`GoalStep`) | `/profile/setup` |
| Setup 3/3 When can you study? (A11) | same screen (`AvailabilityStep`) | `/profile/setup` |

One route, three steps. `application/profile_setup_controller.dart` keeps the
draft values (so the back arrow never loses them), resumes at the first
unsaved step, sends each step with `PATCH /profile` and finishes with
`POST /profile/complete` (then the session refresh moves the student to the
diagnostic). "Coming soon" subjects can't be picked.

Confidence labels: 0-20 Not at all, 21-40 A little, 41-60 Okay-ish,
61-80 Fairly, 81-100 Very (`domain/profile_models.dart`).

## API endpoints it uses

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/profile/options` | Streams, subjects, exam years, grades, preferred times |
| `GET` | `/profile` | Saved answers (resume) |
| `PATCH` | `/profile` | Save one step |
| `POST` | `/profile/complete` | Finish setup (`PROFILE_INCOMPLETE` if a step is missing) |

## Folders

```
profile/
├── domain/profile_models.dart              freezed models
├── data/profile_repository.dart            calls ApiClient (the only place that does)
├── application/profile_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/profile/` (same structure as this folder).
