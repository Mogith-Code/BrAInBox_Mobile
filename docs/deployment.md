# Deployment

`.github/workflows/release.yml` builds a **signed release APK** and deploys
the **admin web app to Firebase Hosting**. Run it from
*Actions > Release > Run workflow*, or push a tag (`git tag v1.0.0`,
`git push origin v1.0.0`); a tag also attaches the APK to a GitHub release.

## What you must supply

### Repository secrets (*Settings > Secrets and variables > Actions > Secrets*)

| Secret | What it is | How to make it |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | The upload keystore | `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | chosen when creating the keystore |
| `ANDROID_KEY_PASSWORD` | Key password | same as above unless you set another |
| `ANDROID_KEY_ALIAS` | Key alias | e.g. `upload` |
| `GOOGLE_SERVICES_JSON_BASE64` | `apps/mobile/android/app/google-services.json` | `base64 -w0 google-services.json` |
| `MOBILE_FIREBASE_OPTIONS_BASE64` | `apps/mobile/lib/firebase_options.dart` | `flutterfire configure`, then `base64 -w0` |
| `ADMIN_FIREBASE_OPTIONS_BASE64` | `apps/admin/lib/firebase_options.dart` | same, for the web app |
| `FIREBASE_SERVICE_ACCOUNT` | Service account JSON with *Firebase Hosting Admin* | Firebase console > Project settings > Service accounts > Generate new private key (paste the whole JSON) |

On Windows (PowerShell) make the base64 text with:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

then paste it as the secret value (same for the other files).

### Repository variables (*... > Variables*)

| Variable | Example |
|---|---|
| `API_BASE_URL` | `https://api.brainbox.lk/api/v1` |
| `FIREBASE_PROJECT_ID` | `brainbox-prod` |

## The keystore (once)

```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Keep the `.jks` file and its passwords in the team password manager. **If it is
lost, updates to an installed app cannot be signed.**

## Building a signed APK on your PC

Create `apps/mobile/android/key.properties` (git-ignored, never commit it):

```properties
storeFile=upload-keystore.jks
storePassword=...
keyPassword=...
keyAlias=upload
```

Put `upload-keystore.jks` in `apps/mobile/android/` (`*.jks` is git-ignored), then
(PowerShell):

```powershell
cd apps\mobile
flutter build apk --release --dart-define=API_BASE_URL=https://api.brainbox.lk/api/v1
```

The APK is `apps\mobile\build\app\outputs\flutter-apk\app-release.apk`.
Release builds use R8 (code shrinking); no extra ProGuard rules are needed for
the current plugins. They allow HTTPS only: `http://` is enabled in debug
builds only (`android/app/src/debug/AndroidManifest.xml`).

The first release build downloads the Android NDK version Flutter asks for.
If that fails ("sdkmanager did not install NDK"), install it yourself:
Android Studio → SDK Manager → SDK Tools → NDK (Side by side), or
`android sdk install ndk/<version>` with the version from the error.

Without `key.properties` the release build is signed with the debug key
(fine for testing, not for distribution).

## API_BASE_URL

The apps read the backend address at build time from
`--dart-define=API_BASE_URL=...` (`brainbox_core/lib/config/env.dart`).
Local Android emulator: `http://10.0.2.2:8000/api/v1`.
