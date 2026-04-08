# Firebase Key Rotation Runbook (TuniTranspo)

Date: 2026-04-08
Project ID: tuni-transport-20eaf

## Objective

Rotate Firebase/Google API keys exposed in source history, then regenerate local app configuration and validate deployment.

## Current Status

- Firestore chat read rule has been fixed and deployed.
- `lib/firebase_options.dart` has been removed from Git tracking (local file still exists).

## Step 1 - Rotate API Keys in Google Cloud Console

1. Open Google Cloud Console for project `tuni-transport-20eaf`.
2. Go to APIs & Services > Credentials > API keys.
3. For each key currently used by Flutter platforms, do one of these options:
	- Preferred: Create a new key, migrate clients, then delete old key.
	- Fast: Regenerate existing key if available in your workflow.
4. Apply application restrictions:
	- Web key: HTTP referrers (production domains only).
	- Android key: Android apps (package name + SHA-1 certificate).
	- iOS key: iOS apps (bundle identifier).
5. Apply API restrictions to only required Firebase/Google APIs used by the app.
6. Disable or delete old exposed keys after regeneration is complete.

## Step 2 - Regenerate Firebase Config Files

Run from repo root:

```bash
flutterfire configure --project=tuni-transport-20eaf --out=lib/firebase_options.dart --platforms=android,ios,web,macos,windows
```

Then verify native files are refreshed:

- android/app/google-services.json
- ios/Runner/GoogleService-Info.plist

## Step 3 - Verify Ignore Rules

Ensure root `.gitignore` contains:

- lib/firebase_options.dart
- android/app/google-services.json
- android/app/src/google-services.json
- ios/Runner/GoogleService-Info.plist

## Step 4 - Local Validation

Run:

```bash
flutter pub get
flutter analyze
flutter test
```

If app startup is part of validation:

```bash
flutter run -d chrome
```

Confirm Firebase init still succeeds on your target platforms.

## Step 5 - Security Validation

1. Confirm unauthenticated read on `community_messages` now fails with permission denied.
2. Confirm authenticated user can still read/write according to rules.
3. Review Firebase Auth, Firestore, and API metrics for abnormal traffic after rotation.

## Step 6 - Commit and Push

Security patch commit:

```bash
git add firestore.rules docs/firebase_key_rotation_runbook.md
git commit -m "security: restrict community_messages reads and add key rotation runbook"
git push
```

Note: `lib/firebase_options.dart` is intentionally untracked and should not be re-added.

## Optional Step 7 - Purge Historical Exposure

If repository is public or had external access, remove sensitive file history:

1. Use `git filter-repo` or BFG to purge historical blobs.
2. Force-push rewritten history.
3. Coordinate with team because all collaborators must re-clone or reset.

Even with history rewrite, key rotation is still mandatory.
