# AI Speaking Partner PRO MAX

[![Release APK](https://img.shields.io/github/v/release/mmagroscience/ai-speaking-partner-pro-max?label=download%20APK&logo=android)](https://github.com/mmagroscience/ai-speaking-partner-pro-max/releases/latest)

![AI Speaking Partner PRO MAX](screenshots/collage_v1.1.0.png)

A face-to-face AI speaking coach built with Flutter. The app simulates a video
call with an AI tutor, listens to your voice, replies with a natural-sounding
coach, and gives pronunciation, fluency and vocabulary feedback. It also has an
IELTS speaking mock, a three-tone vocabulary bank, a voice-cloning demo and an
over-the-air (OTA) content admin panel.

## Highlights

- **Face-to-face video call UI** — animated avatar, live subtitles, camera
  self-view, mute/speaker/captions controls, call timer and end-of-call report.
- **Call transcript** — open the transcript from the call and copy the whole
  conversation.
- **Works offline** — a built-in demo coach replies without any API key. Add one
  or more Gemini API keys in Settings to use the online coach; keys rotate
  automatically.
- **Microphone fallback** — if speech recognition cannot hear you twice, the app
  offers a one-tap keyboard reply.
- **Pronunciation coach** — word-by-word scoring with tips and a practice list.
- **IELTS speaking mock** — Part 1, cue-card Part 2 with a 60-second preparation
  timer and two-minute talk timer, Part 3, a band estimate and feedback.
- **Three-tone vocabulary** — formal, neutral and casual versions of each word,
  with a quiz and favourites.
- **Voice cloning flow** — name, photo and audio sample with a simulated
  on-device cloning progress (demo).
- **Bangla / Hindi help** — switch the onboarding and coach help language.
- **PIN-protected admin** — publishing updates and editing practice topics sits
  behind a 4–8 digit PIN (default `1234`, change it in the panel).
- **Privacy-first storage** — no account and no backend. Gemini keys go into the
  Android keystore / iOS Keychain; everything else uses local preferences.
- **Progress backup** — export sessions, streak and custom topics to the
  clipboard as JSON, then import them on another install.
- **Responsive layout** — phones use the full screen; tablets and desktop web
  show a centred 480-pixel app frame.
- **OTA updates** — point the app at a remote `ota.json` or generate one from
  the in-app admin panel.

## What's new in 1.1.0

- Call transcript sheet with copy-to-clipboard.
- Keyboard fallback after repeated empty microphone results.
- Audio/microphone cleanup when the app goes to the background.
- Admin PIN gate and in-panel PIN change.
- API keys moved to platform secure storage (browser storage fallback).
- Progress export/import.
- Privacy & data screen with a Bangla summary.
- First-call empty state on Progress, with a direct route to Practice.
- Scenario cards no longer truncate long titles behind the level pill.
- Larger dashboard tiles, responsive desktop/web frame.
- Monochrome adaptive launcher icon, iOS scaffolding and a CI workflow.
- Release APK/AAB now signed with a generated release keystore.

## Run

```powershell
flutter pub get
flutter run
```

## Build

```powershell
flutter build web --release
flutter build apk --release
flutter build appbundle --release
flutter build apk --release --split-per-abi
```

Release outputs:

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

Signing details live in [SIGNING.md](SIGNING.md). Back up `android/key.properties`
and `android/keystore/` before publishing.

## Build the APK with GitHub Actions

`.github/workflows/release-apk.yml` builds the signed APK, split APKs and the
Play Store bundle. Run it from **Actions → Release APK → Run workflow**, or push
a version tag:

```powershell
git tag v1.1.0
git push origin v1.1.0
```

Tagged builds are attached to the GitHub Release automatically. The workflow
reads these repository secrets:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | base64 of `android/keystore/ai_speaking_partner_release.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_PASSWORD` | key password |
| `ANDROID_KEY_ALIAS` | `ai-speaking-partner` |

Without the secrets the workflow still produces an installable APK, signed with
the debug key — fine for testing, not for Play Store updates.

## Project layout

```
lib/
  core/        theme, constants, helpers
  data/        models, catalog, offline demo coach
  services/    AI, speech, TTS, pronunciation, IELTS, OTA, secure storage
  state/       AppState (ChangeNotifier + shared_preferences)
  widgets/     shared UI (avatar, cards, buttons, backgrounds)
  screens/     splash, onboarding, home, practice, progress, profile,
               privacy, admin, call and update flows
assets/
  branding/    app icon, adaptive foreground + monochrome layer
  audio/       ringtone
  fonts/       Poppins + Hind Siliguri
  ota_config.json
```

## Tests

```powershell
flutter analyze
flutter test
```

The suite covers the offline coach, catalog integrity, call screen, admin PIN,
progress export/import and the first-call empty state.

## Optional AI keys

Open **Profile → Settings → AI coaching → Add** and paste one or more Gemini API
keys. Without keys the app stays fully usable with the offline demo coach. Keys
are stored in the platform keystore on mobile and are never committed to the
project.

## Privacy

There is no account, analytics or backend. Microphone, camera and photo access
are used only while practising. The full policy is available in the app under
**Profile → Privacy & data**.
