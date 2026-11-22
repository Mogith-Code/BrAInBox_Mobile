# BrAInBox – handover

This page is for the customer's technical contact: the person who owns the
BrAInBox accounts, keeps the secrets and publishes new versions. Teachers and
students need only the [admin guide](admin-guide.md) and the
[user guide](user-guide.md).

Fill in every **⟨…⟩** before you sign off the handover.

---

## 1. What is delivered

| Item | Where | Version |
|---|---|---|
| **Student app (Android APK)** | GitHub → *Releases* → `v1.0.0` → `app-release.apk` (built by the Release workflow) | 1.0.0 (build 1) |
| **Admin portal (web)** | ⟨https://admin-url⟩ (Firebase Hosting) | 1.0.0 |
| **Backend API** | ⟨https://api-url⟩/api/v1 – health check: ⟨https://api-url⟩/api/v1/health → `{"status":"ok","db":"ok"}` | 1.0.0 |
| **Frontend source** | this repository (`apps/mobile`, `apps/admin`, `packages/brainbox_core`) | branch `main`, tag `v1.0.0` |
| **Backend source** | the `brainbox-backend` repository (API, AI service, deploy scripts) | tag `v1.0.0` |
| **Documentation** | `docs/` here, and `docs/` + `deploy/README.md` in the backend | |

App details:

| | |
|---|---|
| App name | BrAInBox |
| Android package id | `lk.ac.sab.brainbox` (never change it: Android would treat it as a different app) |
| Android versions | 7.0 (API 24) and newer; targets the current Android API level |
| Languages | English |
| iOS | Not built in this version |

## 2. Accounts the customer gets

Every account must be owned by a **customer** email address (not a
developer's), with at least **two** people as owners/admins, so nothing is lost
when someone leaves.

| Account | What it holds | Who must own it |
|---|---|---|
| **GitHub** organisation / repositories | Source code, Release workflow, repository secrets, built APKs | ⟨owner⟩ |
| **Google Cloud / Firebase project** ⟨project id⟩ | Sign-in (Firebase Auth), file storage, Cloud Run (API + AI service), Cloud Tasks, Firebase Hosting (admin portal), Secret Manager | ⟨owner⟩, billing account with a **budget alert** |
| **Neon** | The PostgreSQL database (all app data and the AI knowledge base) | ⟨owner⟩ |
| **Google AI Studio** | The Gemini API key | ⟨owner⟩ |
| **Email (SMTP) mailbox** | Sends the 6-digit sign-up / password-reset codes | ⟨mailbox⟩ |
| **Domain / DNS** (if used) | `admin.…` and `api.…` addresses | ⟨owner⟩ |
| Optional: Cloudflare (illustrations), YouTube Data API (video suggestions) | | ⟨owner⟩ |

**First admin in the portal:** sign in once, then the backend operator runs
`python scripts/make_admin.py ⟨email⟩` (or `seed_customer.py --admin-email
⟨email⟩` on a fresh database). Sign out and in again. More admins: same
command. Remove admin rights: see the backend's `docs/deployment.md` §8.

Demo/test accounts created during development must be **deleted** before
go-live (Firebase console → Authentication).

## 3. Secrets and files you must keep

Keep all of these in a **password manager** owned by the customer, with a
second person who has access. None of them are in the repositories.

| Secret / file | Why it matters | If it is lost |
|---|---|---|
| **Android upload keystore** (`upload-keystore.jks`) **+ its passwords + alias** | Every update of the app must be signed with the same key | **Installed apps can never be updated.** Students would have to uninstall and install a new app (and lose local data). Keep two copies in different places. |
| `key.properties` | The keystore passwords for building on a PC | Recreate it from the passwords above |
| **Firebase config**: `apps/mobile/lib/firebase_options.dart`, `apps/admin/lib/firebase_options.dart`, `apps/mobile/android/app/google-services.json` | Connect the apps to your Firebase project | Download again with `flutterfire configure` (needs Firebase access) |
| **Firebase service account** JSON (for the Release workflow and any non-Cloud-Run host) | Lets CI deploy the admin portal | Generate a new key in Firebase console → Project settings → Service accounts, delete the old one |
| **Neon `DATABASE_URL`** (user + password) | All student data | Reset the password in Neon and update the secret |
| `GEMINI_API_KEY`, `AI_SERVICE_TOKEN`, `AUTH_CODE_SECRET`, `SMTP_PASSWORD` | Backend secrets (in Google Secret Manager) | Rotate them; see the backend's `docs/deployment.md` |
| GitHub repository **secrets and variables** | What the Release workflow uses (list in [deployment.md](deployment.md)) | Re-enter them from the items above |

Rules:

- Never commit any of these files; they are in `.gitignore`.
- Never send them by email or chat. Share the password-manager entry.
- If a secret may have leaked, **rotate it** (make a new one, delete the old one).

### Firebase setting the app depends on

Google sign-in on Android only works when the **SHA-1 and SHA-256 fingerprints
of the upload key** are added to the Android app in the Firebase console
(Project settings → Your apps → Android). Get them with:

```powershell
keytool -list -v -keystore upload-keystore.jks -alias upload
```

## 4. Known limitations (version 1.0.0)

| Area | Limitation | Workaround |
|---|---|---|
| Community | Posts are **text only**: images cannot be attached (the backend has no upload endpoint for posts) | Describe the diagram, or link to it |
| Ask BrAInBox (AI tutor) | **Not built.** The screen shows *Coming soon* | Use notes, visuals and practice feedback |
| Subjects | Only **Biological Science · Biology**. Chemistry and Physics show *Coming soon* | – |
| Admin → Question bank | **Import CSV** is not available | Bulk-load on the server: `seed_customer.py --only question-bank` |
| Admin → Dashboard | Search, notifications, **Export** and *Create practice set* are not connected | Use each page's own filters |
| Admin pages | A page whose server part is missing shows *"The backend for this page is not built yet"* instead of an error | – |
| Admin roles | No "remove admin" button | SQL in the backend's `docs/deployment.md` §8 |
| My visuals | The list of visuals a student made is kept **on the phone only**; it is empty on a new phone | – |
| Fonts | Poppins and Inter are downloaded on first launch. Offline on the very first launch the app uses the system font until it is online once | – |
| Dark mode | Uses a provisional dark palette (no dark design exists). The main screens are checked for contrast; some rarely used screens may still have low-contrast text | Report the screen; it is a small fix |
| Links | The privacy-policy link is `https://brainbox.lk/privacy` and the support address is `support@brainbox.lk`. **Confirm both exist** or give us the real ones before release | – |
| Database | On Neon's free plan the database sleeps when idle; the first request after a pause takes a few seconds | Paid Neon plan |
| AI | AI content can contain mistakes. Students only see approved content, but AI marking and feedback are generated live | Review queues; check marking accuracy in Analytics |
| Platforms | No iOS app | – |

## 5. Releasing a new version

Releases are built by GitHub Actions (`.github/workflows/release.yml`). It
builds the **signed APK**, deploys the **admin portal** to Firebase Hosting, and
attaches the APK to a GitHub release. One-time setup (secrets and variables) is
in [deployment.md](deployment.md).

1. **Change the version** in `apps/mobile/pubspec.yaml` (and the same in
   `apps/admin/pubspec.yaml`):

   ```yaml
   version: 1.0.1+2   # <name>+<build>. Always increase the build number.
   ```

   Android refuses to install an update whose build number is not higher than
   the installed one.

2. **Check** on your PC (PowerShell, from the repository root):

   ```powershell
   melos run analyze
   melos run format:check
   melos run test
   ```

3. **Merge to `main`**, then tag and push:

   ```powershell
   git checkout main
   git pull
   git tag v1.0.1
   git push origin v1.0.1
   ```

4. Watch **Actions → Release**. When it is green:
   - the admin portal is live at ⟨https://admin-url⟩ (hard-refresh with Ctrl+F5);
   - `app-release.apk` is attached to the `v1.0.1` release on GitHub.
5. **Send students the new APK.** Installing it over the old one keeps their
   data, because it is signed with the same key.
6. **Backend changes** are deployed separately from the backend repository
   (`./deploy/deploy.sh deploy`, see its `docs/deployment.md`). Deploy the
   backend **first** when the apps depend on a new API.

You can also run the workflow by hand: *Actions → Release → Run workflow* on
`main` (no GitHub release is created then; download the APK from the run's
*Artifacts*).

### Building on a PC instead

See [deployment.md](deployment.md) → *Building a signed APK on your PC*: put
`upload-keystore.jks` and `key.properties` in `apps/mobile/android/`, then

```powershell
cd apps\mobile
flutter build apk --release --dart-define=API_BASE_URL=https://⟨api-url⟩/api/v1
```

The APK is at `apps\mobile\build\app\outputs\flutter-apk\app-release.apk`.

### Publishing on Google Play (optional, later)

The app is ready for Play: release builds are signed, shrunk by R8, allow HTTPS
only, and target the current API level. For Play you would build an App Bundle
(`flutter build appbundle --release …`), enrol in Play App Signing, and add a
privacy policy and data-safety form. That is not part of this delivery.

## 6. Who to contact

| Topic | Contact |
|---|---|
| Frontend (apps) | ⟨name, email⟩ |
| Backend / hosting | ⟨name, email⟩ |
| Support period | ⟨dates and what is covered⟩ |
