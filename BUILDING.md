# Building the Tracking App Frontend

Run all commands in this guide from the `frontend/` directory unless stated
otherwise.

The supported build workflows are:

- Linux debug for everyday development
- ARM64 Android release APKs for testing on Samsung A14 devices
- Android App Bundles for Google Play distribution
- Web release builds for the production server

The production API URL is `https://tracking.mekis.dev`. Release commands specify
it explicitly so the configuration of each artifact is clear and reproducible.

## Install dependencies and run checks

Install packages after a clean checkout or dependency change:

```bash
flutter pub get
```

Before making a release build, run:

```bash
flutter analyze
flutter test
```

## Linux development

Linux is the everyday debug target:

```bash
flutter run -d linux
```

The frontend uses `http://127.0.0.1:8000` by default in debug mode. To run it
against another backend, provide the URL explicitly:

```bash
flutter run -d linux --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Android signing

Android release builds use the signing configuration in
`android/app/build.gradle.kts`. Create `android/key.properties` locally with the
release keystore details:

```properties
storePassword=replace-with-store-password
keyPassword=replace-with-key-password
keyAlias=replace-with-key-alias
storeFile=/absolute/path/to/release-key.jks
```

Keep the properties file and keystore private and backed up. Do not commit them.
Before a Play Store release, update `version` in `pubspec.yaml`; its value has the
form `versionName+versionCode`, for example `1.2.0+12`.

## ARM64 Android APK for device testing

The Samsung A14 test devices use ARM64. Build a release APK containing only that
ABI:

```bash
flutter build apk --release \
  --target-platform android-arm64 \
  --dart-define=API_BASE_URL=https://tracking.mekis.dev
```

The generated APK is:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Install or replace it on a connected test device:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

This APK is deliberately unsuitable for ARM32-only and x86/x86-64 devices. The
restriction applies only to local APK testing; do not use it for Play Store
distribution.

## Google Play release

Build an Android App Bundle without an ABI restriction:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://tracking.mekis.dev
```

The generated bundle is:

```text
build/app/outputs/bundle/release/app-release.aab
```

Upload the `.aab` to the appropriate Google Play testing or production track.
Google Play generates optimized APKs for each supported device architecture.
Do not add a project-wide `abiFilters` restriction: the tracking app must remain
installable on supported new and old phones and tablets.

## Production web release

Build the web frontend with the production API URL:

```bash
flutter build web --release \
  --base-href /tracking/ \
  --dart-define=API_BASE_URL=https://tracking.mekis.dev
```

The web app is served at `https://mekis.dev/tracking/`, and the deployable
static site is written to:

```text
build/web/
```

Deploy the contents of `build/web/` using the server's established static-site
deployment process. The backend deployment files under `deployment/` do not
deploy this web output.

## Disk usage and cleanup

Flutter and Gradle retain generated files to accelerate later builds. The
ARM64-only APK command keeps routine Android testing smaller, while a Play Store
bundle necessarily rebuilds all supported Android architectures.

Use a full cleanup only when generated output is stale or disk space is needed:

```bash
flutter clean
flutter pub get
```

Cleaning removes outputs for Linux, Android, and web, so their next builds will
take longer. Preserve any APK, AAB, or web artifact that still needs to be
installed, uploaded, or deployed before cleaning.
