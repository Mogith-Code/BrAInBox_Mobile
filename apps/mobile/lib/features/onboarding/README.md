# Onboarding (mobile)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Welcome carousel shown on first launch. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/onboarding` (tickets: `feature/onboarding/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Welcome carousel (Figma A2-A4: Learn smarter / Know exactly what went wrong / Always know what's next) | `presentation/onboarding_screen.dart` | `/onboarding` |

Illustrations are drawn in Flutter (`presentation/widgets/welcome_illustrations.dart`).
TODO(mogith): replace them with the designer's SVG exports.

## API endpoints it will use

None. The only state is the **"welcome seen"** flag in shared_preferences
(`data/onboarding_repository.dart`), exposed as `welcomeSeenProvider`.
Get Started / Skip -> Create account, Log in -> Log in; all three save the flag.

## Folders

```
onboarding/
├── domain/onboarding_models.dart              freezed models
├── data/onboarding_repository.dart            calls ApiClient (the only place that does)
├── application/onboarding_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/onboarding/` (same structure as this folder).
