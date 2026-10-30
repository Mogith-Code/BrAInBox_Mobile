# Splash (mobile)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Splash screen and start-up redirect (onboarding / login / home). |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/splash` (tickets: `feature/splash/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Splash (Figma A1) | `presentation/splash_screen.dart` | `/` |

The splash has no data layer of its own. It watches `sessionProvider`
(auth feature): dots while loading, the error + Retry if loading fails, and
the router's onboarding redirect moves on as soon as the session is known.
With the redirect off (no Firebase / fake API, or `DISABLE_AUTH_GUARD`) it
shows "Get started" and the Dev menu button instead.

Decorations are drawn in `presentation/widgets/splash_decorations.dart`.

## API endpoints it uses

None directly (the session calls `GET /auth/me`).

## Folders

```
splash/
├── domain/splash_models.dart              freezed models
├── data/splash_repository.dart            calls ApiClient (the only place that does)
├── application/splash_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/splash/` (same structure as this folder).
