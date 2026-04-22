const admin = require('firebase-admin');

function initializeFirebaseAdmin() {
  // Guard specifically against the default app, since named apps also
  // increment admin.apps but don't satisfy admin.app().
  const existing = admin.apps.find(a => a.name === '[DEFAULT]');
  if (existing) return existing;

  // GCLOUD_PROJECT / FIREBASE_AUTH_EMULATOR_HOST signal a Google-managed
  // runtime where ADC is injected automatically.
  // FIREBASE_CONFIG is a client-SDK variable and is intentionally excluded.
  const hasCredentialHint =
    !!process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    !!process.env.GCLOUD_PROJECT;

  if (!hasCredentialHint) {
    throw new Error(
      'Firebase Admin credentials not detected. ' +
      'Set GOOGLE_APPLICATION_CREDENTIALS or run in a trusted Google runtime.'
    );
  }

  const options = {
    credential: admin.credential.applicationDefault(),
  };

  const projectId = process.env.FIREBASE_PROJECT_ID?.trim();
  if (projectId) {
    options.projectId = projectId;
  }

  admin.initializeApp(options);
  return admin.app();
}

module.exports = { admin, initializeFirebaseAdmin };