# Folder structure

One line per folder. Owners are in `.github/CODEOWNERS` and in each feature's `README.md`.

```
brainbox-mobile/
├── README.md                      what the repo is, setup, run commands, rules
├── CONTRIBUTING.md                branches, commit format, PR checklist, Definition of Done
├── pubspec.yaml                   workspace root + Melos config (scripts: analyze, format, test, gen, build:*)
├── pubspec.lock                   one lock file for the whole workspace
├── analysis_options.yaml          shared lint rules for every package
├── tool/                          repo scripts (ensure_firebase_options.dart runs after bootstrap)
├── .github/
│   ├── workflows/flutter-ci.yml   CI: format, analyze, test, build web (+ APK on main)
│   ├── pull_request_template.md   PR checklist
│   └── CODEOWNERS                 folder -> reviewer
├── docs/                          architecture, this file, API contract
├── design/                        Figma exports and logo SVGs
│
├── packages/
│   └── brainbox_core/             shared by both apps
│       ├── assets/logo/           logo SVG used by AppLogo
│       ├── lib/
│       │   ├── brainbox_core.dart exports everything below (import only this)
│       │   ├── config/            Env (--dart-define), FirebaseSetup
│       │   ├── api/               ApiClient (Dio), AuthInterceptor, ApiException, JobPoller
│       │   ├── auth/              currentUserProvider (signed-in AppUser)
│       │   ├── models/            shared freezed models (Unit, Topic, Question...)
│       │   ├── theme/             AppColors, AppTypography, AppSpacing, AppTheme
│       │   ├── widgets/           UI kit (AppButton, AppTextField, AiBadge, MasteryRing...)
│       │   └── utils/             validators, Firebase error messages, formatters
│       └── test/                  core tests
│
└── apps/
    ├── mobile/                    ANDROID STUDENT APP (package id lk.ac.sab.brainbox)
    │   ├── android/               Android project (cleartext HTTP allowed in debug only)
    │   ├── assets/                images/, icons/, logo/, illustrations/
    │   ├── lib/
    │   │   ├── main.dart          Firebase + Hive init, ProviderScope
    │   │   ├── firebase_options.dart.example   stub copied to firebase_options.dart
    │   │   ├── app/               app.dart, router.dart, routes.dart, shell_scaffold.dart, dev_menu_screen.dart
    │   │   └── features/          one folder per feature (table below)
    │   ├── test/                  mirrors lib/ (test/app, test/features/<feature>/...)
    │   └── integration_test/      app_smoke_test.dart (runs on a device)
    │
    └── admin/                     ADMIN WEB PORTAL
        ├── web/                   index.html, manifest.json, icons ("BrAInBox Admin")
        ├── lib/
        │   ├── main.dart
        │   ├── firebase_options.dart.example
        │   ├── app/               app.dart, router.dart (admin guard), admin_shell.dart (sidebar)
        │   └── features/          one folder per feature (table below)
        └── test/                  mirrors lib/
```

## Inside every feature folder

```
<feature>/
├── README.md                              owner, purpose, screens, routes, endpoints, Jira epic, branch
├── domain/<feature>_models.dart           freezed models (+ re-exports of shared core models)
├── data/<feature>_repository.dart         calls ApiClient - the only layer that does
├── application/<feature>_controller.dart  Riverpod controller: AsyncValue (loading / error / data)
└── presentation/
    ├── <screen>_screen.dart               one file per screen (UI only)
    └── widgets/                           widgets used only by this feature
```

## Mobile features (`apps/mobile/lib/features/`)

| Feature folder | Owner | What it contains |
|---|---|---|
| `splash/` | Mogith | Splash screen and start-up redirect (onboarding / login / home). |
| `onboarding/` | Mogith | Welcome carousel shown on first launch. |
| `auth/` | Mogith | Login, sign up, forgot password and email verification (Firebase Auth). |
| `profile/` | Mogith | Profile setup: stream, exam year, goals, daily study time. |
| `home/` | Samni | Dashboard: next best action and today's study plan. |
| `syllabus/` | Keshomigha | Units list, unit detail and the topic page with tabs. |
| `notes/` | Samni | AI notes, short notes, the generate-notes sheet and the notes library. |
| `upload/` | Samni | Upload notes (PDF / photo), show processing, then the AI summary. |
| `visuals/` | Mogith | Diagram gallery, zoomable viewer and generate-visual flow. |
| `practice/` | Udith | Practice hub, quiz setup, MCQ flow, feedback, results and the diagnostic test. |
| `exams/` | Udith | Past papers, model paper generator and exam mode. |
| `evaluation/` | Keshomigha | Typed answers, handwritten upload + OCR preview, and AI feedback. |
| `insights/` | Keshomigha | Mastery overview, topic heatmap and the mistake journal (fl_chart). |
| `recommendations/` | Udith | Next steps, resources, study plan and reassessment. |
| `community/` | Mogith | Study groups, group feed, post detail and create post. |
| `notifications/` | Samni | Notification center. |
| `settings/` | Samni | Settings, privacy and about. |

## Admin features (`apps/admin/lib/features/`)

| Feature folder | Owner | What it contains |
|---|---|---|
| `auth/` | Mogith | Admin login. Only users with role "admin" get past the router guard. |
| `dashboard/` | Samni | KPI tiles and recent activity. |
| `syllabus_manager/` | Keshomigha | Unit -> Topic -> Concept tree editor. |
| `content_review/` | Samni | Approve, edit or reject AI notes, short notes and images. |
| `question_bank/` | Udith | Question table with filters and bulk import. |
| `mcq_mapping/` | Udith | Tag the misconception behind each wrong MCQ option. |
| `quality_review/` | Udith | Queue of automatic checks on AI-generated questions. |
| `past_papers/` | Udith | Upload past papers and their marking schemes. |
| `knowledge_base/` | Keshomigha | Model answers and marking keywords used by evaluation. |
| `rag_sources/` | Samni | Upload syllabus, teacher guides and approved notes for RAG; ingestion status; re-index. |
| `moderation/` | Mogith | Reported / flagged posts and groups. |
| `users/` | Mogith | Student list and suspend / unsuspend. |
| `analytics/` | Keshomigha | Most-missed topics and most common misconceptions. |
