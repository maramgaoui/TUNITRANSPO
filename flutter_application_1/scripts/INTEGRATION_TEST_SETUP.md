# Integration Test Setup

## Required environment variables for seeding

Set these before running the seed script:

- `GOOGLE_APPLICATION_CREDENTIALS`
- Optional: `FIREBASE_PROJECT_ID` (if your ADC context does not expose project automatically)
- `TEST_USER_EMAIL`
- `TEST_USER_PASSWORD`
- `TEST_BANNED_EMAIL`
- `TEST_BANNED_PASSWORD`
- `TEST_ADMIN_MATRICULE`
- `TEST_ADMIN_PASSWORD`
- Optional: `TEST_ADMIN_EMAIL`
- Optional: `TEST_ADMIN_NAME`
- Optional: `TEST_ADMIN_ROLE`

## Seed command

From `scripts/` dependencies already installed:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\secure\firebase\service-account.json"
node scripts/seed_integration_test_data.js
```

Or:

```powershell
cd scripts
npm run seed-integration
```

## Required dart-defines for executable auth flow tests

- `INTEGRATION_TEST_MODE=true`
- `IT_RUN_AUTH_FLOW=true`
- `IT_USER_EMAIL`
- `IT_USER_PASSWORD`
- `IT_BANNED_EMAIL`
- `IT_BANNED_PASSWORD`
- `IT_ADMIN_MATRICULE`
- `IT_ADMIN_PASSWORD`
- `IT_SIGNUP_PASSWORD`
- `IT_SIGNUP_EMAIL_DOMAIN`
- `TEST_FIREBASE_API_KEY`
- `TEST_FIREBASE_APP_ID`
- `TEST_FIREBASE_MESSAGING_SENDER_ID`
- `TEST_FIREBASE_PROJECT_ID`
- Optional: `TEST_FIREBASE_STORAGE_BUCKET`
- Optional: `TEST_FIREBASE_AUTH_DOMAIN`
- Optional: `TEST_FIREBASE_MEASUREMENT_ID`
- Optional: `TEST_FIREBASE_IOS_BUNDLE_ID`
- Optional: `TEST_FIREBASE_IOS_CLIENT_ID`

## Example run command

```powershell
flutter test integration_test/auth_flow_test.dart -d 2201123G `
  --dart-define=INTEGRATION_TEST_MODE=true `
  --dart-define=IT_RUN_AUTH_FLOW=true `
  --dart-define=IT_USER_EMAIL=user@test.local `
  --dart-define=IT_USER_PASSWORD=Test123!A `
  --dart-define=IT_BANNED_EMAIL=banned@test.local `
  --dart-define=IT_BANNED_PASSWORD=Test123!A `
  --dart-define=IT_ADMIN_MATRICULE=9001 `
  --dart-define=IT_ADMIN_PASSWORD=Admin123!A `
  --dart-define=IT_SIGNUP_PASSWORD=Test123!A `
  --dart-define=IT_SIGNUP_EMAIL_DOMAIN=example.com `
  --dart-define=TEST_FIREBASE_API_KEY=... `
  --dart-define=TEST_FIREBASE_APP_ID=... `
  --dart-define=TEST_FIREBASE_MESSAGING_SENDER_ID=... `
  --dart-define=TEST_FIREBASE_PROJECT_ID=...
```