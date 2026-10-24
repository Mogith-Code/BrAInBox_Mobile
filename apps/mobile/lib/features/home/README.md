# Home (mobile)

| | |
|---|---|
| **Owner** | Samni (`@samni`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Dashboard: next best action and today's study plan. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/home` (tickets: `feature/home/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Home dashboard (Figma B1) | `presentation/home_screen.dart` + `widgets/home_cards.dart` | `/home` |

- Greeting by local time: Good morning (5-11), Good afternoon (12-16),
  Good evening (17-4); date like "Tuesday, 7 Oct".
- Chips: "N-day streak", "N days to A/L" (hidden when `days_to_exam` is null).
- Next best action: `type == diagnostic` opens the diagnostic intro; other
  types open the topic placeholder for now (TODO).
- Today's plan: tapping a circle ticks it right away (optimistic) and rolls
  back if `PATCH /home/plan/{id}` fails.
- Mastery ring + "+N% wk" (red when negative). Continue learning cards ->
  topic; See all -> Learn tab. Avatar -> Settings.
- Pull to refresh, skeleton while loading, error banner with Retry.

## API endpoints it uses

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/home/summary` | Everything on the dashboard |
| `PATCH` | `/home/plan/{item_id}` | Tick / untick a plan item (`{done}`) |

## Folders

```
home/
├── domain/home_models.dart              freezed models
├── data/home_repository.dart            calls ApiClient (the only place that does)
├── application/home_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/home/` (same structure as this folder).
