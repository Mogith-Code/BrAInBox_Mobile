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
| Create your account (A5) | `presentation/signup_screen.dart` | `/auth/signup` |
| Welcome back / Log in (A6) | `presentation/login_screen.dart` | `/auth/login` |
| Forgot your password? (A7) | `presentation/forgot_password_screen.dart` | `/auth/forgot-password` |
| Check your inbox - verify email (A8) | `presentation/check_inbox_screen.dart` | `/auth/verify-email` |
| Check your inbox - reset code (A8) | `presentation/check_inbox_screen.dart` | `/auth/reset-code` |
| Set a new password (not in Figma) | `presentation/new_password_screen.dart` | `/auth/new-password` |

## How it fits together

- `data/auth_repository.dart` is the ONLY place that uses Firebase Auth.
  `data/fake_auth_repository.dart` replaces it with `--dart-define=USE_FAKE_API=true`.
- `application/session_controller.dart` builds the **session**
  (welcome flag + Firebase account + `GET /auth/me`).
- `application/session_redirect.dart` is the **onboarding redirect table** used
  by `app/router.dart` (welcome -> log in -> inbox -> setup -> diagnostic -> home).
- `application/auth_flow_controllers.dart`: one controller per form.
- `application/inbox_controller.dart`: countdown, resend, verify (both modes).
- Reset tokens and codes live in memory only - never on the device.

## API endpoints it uses

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/auth/register` | Create / update the backend user (upsert) |
| `GET` | `/auth/me` | Load the user (404 `USER_NOT_FOUND` -> register) |
| `DELETE` | `/auth/me` | "Wrong email? Change it" on an unverified sign-up |
| `POST` | `/auth/email-code/send` | Send the 6-digit email code |
| `POST` | `/auth/email-code/verify` | Verify it |
| `POST` | `/auth/password-reset/send` | Send a reset code |
| `POST` | `/auth/password-reset/verify` | Code -> reset token |
| `POST` | `/auth/password-reset/complete` | Save the new password |

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
