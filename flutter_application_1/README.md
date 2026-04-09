# TuniTransport

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Android Release Signing

This project uses `android/key.properties` for release signing with these required keys:

- `storeFile`
- `storePassword`
- `keyAlias`
- `keyPassword`

Important for CI/release machines:

1. Ensure `android/key.properties` exists with real values.
2. Ensure the keystore file referenced by `storeFile` is present on the runner.
3. Do not use debug signing for release builds.

The Android Gradle build is configured to fail fast if the release keystore file is missing.
