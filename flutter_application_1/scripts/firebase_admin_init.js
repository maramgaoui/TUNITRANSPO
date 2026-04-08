const admin = require('firebase-admin');

function initializeFirebaseAdmin() {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  const hasCredentialHint =
    !!process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    !!process.env.GCLOUD_PROJECT ||
    !!process.env.FIREBASE_CONFIG;

  if (!hasCredentialHint) {
    throw new Error(
      'Firebase Admin credentials not detected. Set GOOGLE_APPLICATION_CREDENTIALS or run in a trusted Google runtime.'
    );
  }

  const options = {
    credential: admin.credential.applicationDefault(),
  };

  if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PROJECT_ID.trim()) {
    options.projectId = process.env.FIREBASE_PROJECT_ID.trim();
  }

  admin.initializeApp(options);
  return admin.app();
}

module.exports = {
  admin,
  initializeFirebaseAdmin,
};
