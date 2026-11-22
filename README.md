<p align="center"><img src="docs/logo_horizontal_1200.png" width="420" alt="BrAInBox - Study smarter. Fix what matters."></p>

# BrAInBox – frontend

BrAInBox is an AI study app for Sri Lankan **G.C.E. A/L Biology** students
(English). This repository holds all the Flutter code:

| Folder | What it is |
|---|---|
| `apps/mobile` | **Student app** for Android |
| `apps/admin` | **Admin portal** for the web (Flutter Web) |
| `packages/brainbox_core` | Code **shared by both apps**: API client, auth, models, theme, widgets |

The backend (FastAPI + AI service) is in the separate **`brainbox-backend`**
repository. Its `/docs` page (OpenAPI) is the API contract, see
[docs/api-contract.md](docs/api-contract.md).

| Doc | For |
|---|---|
| [docs/user-guide.md](docs/user-guide.md) | Students: how to use the app |
| [docs/admin-guide.md](docs/admin-guide.md) | Teachers / content staff: the admin portal |
| [docs/handover.md](docs/handover.md) | The customer: what is delivered, accounts, secrets, limitations, releasing |
| [docs/deployment.md](docs/deployment.md) | Release workflow, signing, secrets |
| [docs/architecture.md](docs/architecture.md), [docs/folder-structure.md](docs/folder-structure.md) | Developers |
| [docs/brand.md](docs/brand.md) | Logo, colours, icons, splash |

---

## Run both apps in 10 minutes (Windows, PowerShell)

### 1. Install once

| Tool | Check |
|---|---|
| **Flutter 3.44+** (stable, includes Dart 3.12) | `flutter --version` |
| **Android Studio** with an emulator, and the Android SDK | `flutter doctor` shows ✓ for Android |
| **Chrome** | for the admin portal |
| **Java 17+** (Android Studio's bundled JBR is fine) | `java -version` |

Then install Melos (the workspace tool), **version 7.8.1**:

```powershell
dart pub global activate melos 7.8.1
# Put the pub cache on PATH for this window (add it permanently in System settings):
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"
melos --version
```

Melos 8 can't be used yet (`flutter_launcher_icons` needs an older `cli_util`).
Without Melos on `PATH`, write `dart run melos …` instead of `melos …`.

### 2. Get the code and dependencies (~3 min)

```powershell
git clone <repo-url> brainbox-mobile
cd brainbox-mobile
melos bootstrap      # installs packages, creates stub firebase_options.dart files
melos run gen        # generates *.freezed.dart / *.g.dart
```

Run `melos run gen` again after every pull that changes models or providers.
Generated files are not committed.

### 3a. Run with sample data – no backend needed (~2 min)

Both apps have a built-in fake backend for **debug builds**:

```powershell
# Student app: start an emulator in Android Studio first (or plug in a phone)
cd apps\mobile
flutter run --dart-define=USE_FAKE_API=true
```

Log in with **`nethmi.p@gmail.com` / `Mito2027`**, a sample student with
progress. Tap **Dev menu** on the splash or home screen to jump to any screen.

```powershell
# Admin portal, in a second PowerShell window
cd apps\admin
flutter run -d chrome --dart-define=USE_FAKE_API=true
```

With the fake API the admin portal opens without signing in; the student app
shows a **FAKE API** ribbon in the corner. Fake data never ships: the flag is
ignored in release builds.

### 3b. Run against a real backend

Start the backend first (see `brainbox-backend`'s README), then:

```powershell
# Student app on the emulator (10.0.2.2 is your PC's localhost seen from the emulator)
cd apps\mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Admin portal
cd apps\admin
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

Plain `http://` only works in debug builds; release builds allow HTTPS only.
Signing in needs Firebase (section 5).

### Run flags (debug builds only)

| Flag | What it does |
|---|---|
| `--dart-define=API_BASE_URL=...` | Backend URL. Default `http://10.0.2.2:8000/api/v1` (Android) or `http://localhost:8000/api/v1` (web) |
| `--dart-define=USE_FAKE_API=true` | Use the in-app fake backend (sample data) |
| `--dart-define=DISABLE_AUTH_GUARD=true` | Open any route without signing in |

---

## 4. Everyday commands

From the repository root:

| Command | What it does |
|---|---|
| `melos bootstrap` | Install dependencies for all packages |
| `melos run gen` | Run `build_runner` (freezed, json_serializable, riverpod_generator) |
| `melos run gen:watch` | Same, but keeps regenerating as you edit |
| `melos run analyze` | `flutter analyze` in every package (must show **no issues**) |
| `melos run format` | Format all Dart code |
| `melos run format:check` | Fail if anything is not formatted (CI) |
| `melos run test` | Unit and widget tests in every package |
| `melos run build:apk` | Debug APK of the student app |
| `melos run build:web` | Web build of the admin portal |
| `melos run brand:generate` | Regenerate the Android launcher icon and native splash ([docs/brand.md](docs/brand.md)) |

Release builds (signed APK, admin web) are described in
[docs/deployment.md](docs/deployment.md):

```powershell
cd apps\mobile
flutter build apk --release --dart-define=API_BASE_URL=https://<api-host>/api/v1
cd ..\admin
flutter build web --release --dart-define=API_BASE_URL=https://<api-host>/api/v1
```

Melos reads its config from the root `pubspec.yaml` (`melos:` section). The
repo is a [Dart pub workspace](https://dart.dev/tools/pub/workspaces): one
`pubspec.lock` at the root, so both apps use the same package versions.

### Windows: tests fail when the path has spaces

If `flutter test` fails with *"Building native assets for package:objective_c
failed"* and your Flutter SDK or this repo is in a folder with spaces, map the
repo to a drive letter and use a short pub-cache path:

```powershell
subst R: "D:\path with spaces\brainbox-mobile"
$env:PUB_CACHE = "$env:LOCALAPPDATA\Pub\Cache"   # use its 8.3 short form if it has spaces
cd R:\apps\mobile
flutter test
subst R: /D                                      # afterwards, then `flutter pub get` from the real path
```

Easier: keep Flutter and the repo in paths without spaces (e.g. `C:\dev\`).

## 5. Firebase setup

Sign-in uses **Firebase Auth**. The app sends the Firebase ID token to the
backend, which verifies it and keeps the user's role.

Firebase config files hold project keys, so **they are never committed**
(`firebase_options.dart`, `google-services.json` are in `.gitignore`).

**Without Firebase**, `melos bootstrap` copies `lib/firebase_options.dart.example`
(a stub) to `lib/firebase_options.dart`. The apps still start, sign-in is
disabled, and debug builds show an amber *"Firebase not configured"* strip.
`USE_FAKE_API=true` works without Firebase.

**To connect Firebase** (once per developer):

```powershell
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login

cd apps\mobile
flutterfire configure --project=<firebase-project-id> --platforms=android --android-package-name=lk.ac.sab.brainbox
cd ..\admin
flutterfire configure --project=<firebase-project-id> --platforms=web
```

- This overwrites `lib/firebase_options.dart` with the real one (still git-ignored).
- **Don't commit** Gradle changes or `google-services.json` that `flutterfire`
  adds. Firebase is set up from Dart (`DefaultFirebaseOptions`).
- In the Firebase console enable **Email/Password** and **Google** sign-in.
  Google sign-in on Android also needs the SHA-1 / SHA-256 of your signing key
  (`keytool -list -v -keystore <keystore> -alias <alias>`; the debug keystore
  is `%USERPROFILE%\.android\debug.keystore`, password `android`).
- **Admin role:** the admin portal only lets in users whose backend role is
  `admin`. After the person has signed in once, run in the backend:
  `python scripts/make_admin.py someone@example.com`, then sign out and in.

## 6. Project structure

```
brainbox-mobile/
├── apps/
│   ├── mobile/lib/
│   │   ├── main.dart            Firebase + Hive init, ProviderScope
│   │   ├── app/                 MaterialApp, router, routes, bottom-nav shell, dev menu, fake backend
│   │   └── features/<feature>/  one folder per feature
│   └── admin/lib/
│       ├── main.dart
│       ├── app/                 MaterialApp, router + admin guard, sidebar shell
│       └── features/<feature>/
├── packages/brainbox_core/lib/
│   ├── config/   api/   auth/   models/   theme/   widgets/   utils/
├── docs/        guides, architecture, API contract, deployment
├── design/      Figma exports; brand/ = the brand pack (icons, splash, logos)
├── tool/        bootstrap helpers
└── .github/     CI, Release workflow, PR template, CODEOWNERS
```

The full annotated tree is in [docs/folder-structure.md](docs/folder-structure.md).
Each feature folder has a `README.md` with its owner, screens, routes and API endpoints.

## 7. The layering rule

```
<feature>/
├── presentation/   screens + widgets (UI only)
├── application/    Riverpod controllers / providers (state)
├── data/           repositories that call the API client
└── domain/         models for this feature
```

**screen → controller → repository → `ApiClient`.**

- Screens **never** import Dio or Firebase. They `ref.watch` a controller and
  call its methods.
- Controllers hold state as `AsyncValue` (loading / error / data).
- Repositories are the **only** classes that call `ApiClient` (or Firebase Auth, in `auth/`).
- `ApiClient` adds the Firebase ID token, refreshes it once on a 401, and
  turns errors into `ApiException`.
- New code: plain classes with `fromJson` and plain Riverpod 3 providers (no
  codegen); copy `features/recommendations`, `practice` or `evaluation`.

More in [docs/architecture.md](docs/architecture.md).

## 8. Rules

- Use the theme tokens and `brainbox_core` widgets (`AppColors`, `AppSpacing`,
  `AppButton`, `EmptyState`, `ErrorBanner`, `AiBadge`…). No hard-coded colours.
  For text on the page background use `context.appInk`, `context.appMuted` and
  `context.appPrimaryText`, which stay readable in dark mode.
- Every screen has loading, empty and error states. Touch targets ≥ 48 dp.
  Every icon-only button has a `tooltip`.
- Show `AiBadge` on **every** piece of AI-generated content.
- Use `AppLogo` for the logo; never render the wordmark SVGs in Flutter ([docs/brand.md](docs/brand.md)).
- Use the route constants in `AppRoutes` / `AdminRoutes`, not typed paths.
- No secrets in the repo, ever.
- Mark unfinished work with `// TODO(<handle>): ...`. A TODO without an owner is not allowed.
- `test/app/accessibility_test.dart` checks the main screens at text size 1.3,
  in light and dark mode. Keep it green.
- See [CONTRIBUTING.md](CONTRIBUTING.md) for branches, commits and PRs.

## 9. Team

| Member | Handle | Owns |
|---|---|---|
| Mogith (22CSE0394) | `@mogith` | splash, onboarding, auth, profile, visuals, community; admin: auth, moderation, users; `.github/` |
| Samni (22CSE0391) | `@samni` | `brainbox_core` (theme, widgets), `app/` shells, home, notes, upload, notifications, settings; admin: dashboard, content_review, rag_sources, `admin_shell` |
| Udith (22CSE0358) | `@udith` | practice, exams, recommendations; admin: question_bank, mcq_mapping, quality_review, past_papers |
| Keshomigha (22CSE0392) | `@keshomigha` | syllabus, evaluation, insights; admin: syllabus_manager, knowledge_base, analytics |

> The GitHub handles above are placeholders. Replace them here and in
> `.github/CODEOWNERS` with the real usernames.
