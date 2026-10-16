# BrAInBox – frontend (`brainbox-mobile`)

BrAInBox is an AI study app for Sri Lankan **G.C.E. A/L Biology** students
(English only). This repository holds all the Flutter code:

| Folder | What it is |
|---|---|
| `apps/mobile` | **Student app** for Android (Flutter) |
| `apps/admin` | **Admin portal** for the web (Flutter Web) |
| `packages/brainbox_core` | Code **shared by both apps**: models, API client, auth, theme, widgets |

The backend (FastAPI) is in a separate repo, **`brainbox-backend`**. Its
`/docs` page (OpenAPI) is the API contract. See [docs/api-contract.md](docs/api-contract.md).

> **Status:** project skeleton. Every screen is a placeholder that shows its
> title, its owner and "Coming soon". Each owner builds their features in
> their own folders.

---

## 1. Requirements

- **Flutter 3.44 or newer** (stable), which includes Dart 3.12. Check with `flutter --version`.
- **Android Studio** with an Android emulator (for the student app).
- **Chrome** (for the admin portal).
- **Melos**, which manages the workspace:
  ```bash
  dart pub global activate melos
  ```
  Make sure the pub cache `bin` folder is on your `PATH`
  (Windows: `%LOCALAPPDATA%\Pub\Cache\bin`). Without it, use `dart run melos ...`.

## 2. Setup

```bash
git clone <repo-url> brainbox-mobile
cd brainbox-mobile
melos bootstrap      # installs packages; also creates stub firebase_options.dart files
melos run gen        # generates *.freezed.dart / *.g.dart (run again after editing models/providers)
```

Generated files (`*.g.dart`, `*.freezed.dart`) are **not committed**. Run
`melos run gen` after every pull that changes models or providers.

## 3. Run

Start the FastAPI backend first (see `brainbox-backend`). Then:

```bash
# Student app on the Android emulator (10.0.2.2 = your computer's localhost)
cd apps/mobile && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Admin portal in Chrome
cd apps/admin  && flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

Useful extra flags (debug builds only):

| Flag | What it does |
|---|---|
| `--dart-define=API_BASE_URL=...` | Backend URL. Defaults to `http://10.0.2.2:8000/api/v1` (Android) or `http://localhost:8000/api/v1` (web). |
| `--dart-define=DISABLE_AUTH_GUARD=true` | Open any route without signing in. |

**Open any screen:** in the student app, tap **Dev menu** on the splash or
home screen to get a list of every route. In the admin portal, type the path
in the browser's address bar or use the sidebar.

## 4. Melos commands

| Command | What it does |
|---|---|
| `melos bootstrap` | Install dependencies for all packages |
| `melos run gen` | Run `build_runner` (freezed, json_serializable, riverpod_generator) |
| `melos run gen:watch` | Same, but keeps regenerating as you edit |
| `melos run analyze` | `flutter analyze` in every package (must show **no issues**) |
| `melos run format` | Format all Dart code |
| `melos run format:check` | Fail if anything is not formatted (CI runs this before `gen`) |
| `melos run test` | Unit and widget tests in every package |
| `melos run build:apk` | Debug APK of the student app |
| `melos run build:web` | Web build of the admin portal |

Melos 7 and newer read their config from the root `pubspec.yaml` (the `melos:`
section), so there is no `melos.yaml`. The repo is a
[Dart pub workspace](https://dart.dev/tools/pub/workspaces): there is one
`pubspec.lock` at the root, so both apps always use the same package versions.

## 5. Firebase setup

Sign-in uses **Firebase Auth**. The app sends the Firebase ID token to the
backend, and the backend verifies it.

Firebase config files hold project keys, so **they are never committed**:
`firebase_options.dart`, `google-services.json` and `GoogleService-Info.plist`
are in `.gitignore`.

**Without Firebase**, `melos bootstrap` copies
`lib/firebase_options.dart.example` (a stub with no keys) to
`lib/firebase_options.dart` in each app. The apps still start. Sign-in is
disabled, the router's auth guard is off, and debug builds show an amber
*"Firebase not configured"* strip.

**To connect Firebase** (each developer, once):

1. Ask the team lead to add you to the Firebase project.
2. Install the tools:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   ```
3. Generate the config for each app:
   ```bash
   cd apps/mobile && flutterfire configure --project=<firebase-project-id> --platforms=android --android-package-name=lk.ac.sab.brainbox
   cd apps/admin  && flutterfire configure --project=<firebase-project-id> --platforms=web
   ```
   This overwrites `lib/firebase_options.dart` with the real one (still git-ignored).
4. **Do not commit** any changes `flutterfire` makes to `android/` Gradle files
   or `google-services.json`. We set Firebase up from Dart
   (`DefaultFirebaseOptions`), so the Google Services Gradle plugin is not needed.
5. Enable **Email/Password** sign-in in the Firebase console.
6. Admin role: the admin portal only lets in users whose role is `admin`.
   For now we assume the backend sets a Firebase **custom claim** `role: "admin"`.
   See the `TODO(mogith)` in `packages/brainbox_core/lib/auth/current_user_provider.dart`.

## 6. Project structure

```
brainbox-mobile/
├── apps/
│   ├── mobile/lib/
│   │   ├── main.dart            Firebase + Hive init, ProviderScope
│   │   ├── app/                 MaterialApp, router, routes, bottom-nav shell, dev menu
│   │   └── features/<feature>/  one folder per feature (see below)
│   └── admin/lib/
│       ├── main.dart
│       ├── app/                 MaterialApp, router + admin guard, sidebar shell
│       └── features/<feature>/
├── packages/brainbox_core/lib/
│   ├── config/   api/   auth/   models/   theme/   widgets/   utils/
├── docs/        architecture, folder structure, API contract
├── design/      Figma exports and logo SVGs
└── .github/     CI, PR template, CODEOWNERS
```

The full annotated tree is in [docs/folder-structure.md](docs/folder-structure.md).
Each feature folder has a `README.md` with its owner, screens, routes and API endpoints.

## 7. The layering rule (important)

Every feature has the same four layers:

```
<feature>/
├── presentation/   screens + widgets (UI only)
├── application/    Riverpod controllers / providers (state)
├── data/           repository classes that call the API client
└── domain/         freezed models for this feature
```

**The flow is always: screen → controller → repository → `ApiClient`.**

- Screens **never** import Dio or Firebase. They `ref.watch` a controller and
  call its methods.
- Controllers hold state as `AsyncValue` (loading / error / data) and call repositories.
- Repositories are the **only** classes that call `ApiClient` (or Firebase Auth, in `auth/`).
- `ApiClient` adds the Firebase ID token, refreshes it once on a 401, and
  turns errors into `ApiException`.

More in [docs/architecture.md](docs/architecture.md).

## 8. Rules

- Work only in your own feature folders (see `.github/CODEOWNERS`). If you
  need to change `brainbox_core` or `app/`, ask Samni in your PR.
- Use the theme tokens (`AppColors`, `AppSpacing`, `Theme.of(context).textTheme`)
  and the widgets in `brainbox_core` (`AppButton`, `AppTextField`...). No hard-coded colors.
- Show `AiBadge` on **every** piece of AI-generated content.
- Use the route constants in `AppRoutes` / `AdminRoutes`. Don't type paths.
- No secrets in the repo, ever.
- Mark unfinished work with `// TODO(<your-handle>): ...`.
- See [CONTRIBUTING.md](CONTRIBUTING.md) for branches, commits and PRs.

## 9. Team

| Member | Handle | Owns |
|---|---|---|
| Mogith (22CSE0394) | `@mogith` | splash, onboarding, auth, profile, visuals, community; admin: auth, moderation, users; `.github/` |
| Samni (22CSE0391) | `@samni` | `brainbox_core` (theme, widgets), `app/` shells, home, notes, upload, notifications, settings; admin: dashboard, content_review, rag_sources, `admin_shell` |
| Udith (22CSE0358) | `@udith` | practice, exams, recommendations; admin: question_bank, mcq_mapping, quality_review, past_papers |
| Keshomigha (22CSE0392) | `@keshomigha` | syllabus, evaluation, insights; admin: syllabus_manager, knowledge_base, analytics |

> The GitHub handles above are placeholders. Replace them in this table and in
> `.github/CODEOWNERS` with the real usernames.
