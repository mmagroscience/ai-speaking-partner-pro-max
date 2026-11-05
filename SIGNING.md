# Release signing

This project contains a generated Android release keystore so it can produce a
signed APK/AAB without extra setup.

| Item | Value |
| --- | --- |
| Keystore | `android/keystore/ai_speaking_partner_release.jks` |
| Alias | `ai-speaking-partner` |
| Passwords | See `android/key.properties` (git-ignored) |
| Certificate | `CN=Foysal Ahmed, O=AI Speaking Partner, C=BD` |
| Validity | 10,000 days |

## Important

- **Back up `android/keystore/` and `android/key.properties` somewhere safe.**
  Play Store updates must be signed with the same key forever. Losing it means
  you can never update the published app.
- These files are listed in `.gitignore`. Do not commit them to a public
  repository.
- The certificate was generated on this machine by the assistant. If you want a
  Play Store identity tied to your own company details, replace the keystore and
  update `key.properties` before the first upload.
- Existing installs signed with the older debug key must be uninstalled before
  installing this release, because Android rejects signature changes.

## Build commands

```powershell
flutter build apk --release
flutter build appbundle --release
flutter build apk --release --split-per-abi
```

Outputs:

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

Verify a build:

```powershell
$env:JAVA_HOME="C:\jdk17\jdk-17.0.21+9"
& "$env:JAVA_HOME\bin\keytool.exe" -printcert -jarfile build\app\outputs\flutter-apk\app-release.apk
```
