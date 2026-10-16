# Auth (mobile)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Login, sign up, forgot password and email verification (Firebase Auth). |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/auth` (tickets: `feature/auth/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Log in | `presentation/login_screen.dart` | `/auth/login` |
| Sign up | `presentation/signup_screen.dart` | `/auth/signup` |
| Forgot password | `presentation/forgot_password_screen.dart` | `/auth/forgot-password` |
| Verify email | `presentation/verify_email_screen.dart` | `/auth/verify-email` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/me` | Load the signed-in student (creates the profile on first call) |

Shared models used: `AppUser` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
auth/
├── domain/auth_models.dart              freezed models
├── data/auth_repository.dart            calls ApiClient (the only place that does)
├── application/auth_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/auth/` (same structure as this folder).
