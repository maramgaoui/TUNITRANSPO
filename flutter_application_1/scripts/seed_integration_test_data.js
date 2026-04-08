#!/usr/bin/env node

const { admin, initializeFirebaseAdmin } = require('./firebase_admin_init');

const required = [
  'TEST_USER_EMAIL',
  'TEST_USER_PASSWORD',
  'TEST_BANNED_EMAIL',
  'TEST_BANNED_PASSWORD',
  'TEST_ADMIN_MATRICULE',
  'TEST_ADMIN_PASSWORD',
];

for (const name of required) {
  if (!process.env[name] || !process.env[name].trim()) {
    throw new Error(`Missing required env var: ${name}`);
  }
}

initializeFirebaseAdmin();

const auth = admin.auth();
const db = admin.firestore();

async function ensureUser(email, password, displayName) {
  try {
    const existing = await auth.getUserByEmail(email);
    await auth.updateUser(existing.uid, { password, displayName });
    return existing;
  } catch (error) {
    if (error.code !== 'auth/user-not-found') {
      throw error;
    }
  }

  return auth.createUser({ email, password, displayName });
}

async function main() {
  const now = new Date();
  const bannedUntil = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

  const testUser = await ensureUser(
    process.env.TEST_USER_EMAIL,
    process.env.TEST_USER_PASSWORD,
    'Integration User'
  );

  await db.collection('users').doc(testUser.uid).set(
    {
      uid: testUser.uid,
      email: process.env.TEST_USER_EMAIL,
      firstName: 'Integration',
      lastName: 'User',
      username: 'integration_user',
      avatarId: 'avatar-01',
      status: 'active',
      banUntil: null,
      city: 'Tunis',
    },
    { merge: true }
  );

  const bannedUser = await ensureUser(
    process.env.TEST_BANNED_EMAIL,
    process.env.TEST_BANNED_PASSWORD,
    'Banned User'
  );

  await db.collection('users').doc(bannedUser.uid).set(
    {
      uid: bannedUser.uid,
      email: process.env.TEST_BANNED_EMAIL,
      firstName: 'Banned',
      lastName: 'User',
      username: 'integration_banned',
      avatarId: 'avatar-01',
      status: 'banned',
      banUntil: admin.firestore.Timestamp.fromDate(bannedUntil),
      city: 'Tunis',
    },
    { merge: true }
  );

  const adminMatricule = process.env.TEST_ADMIN_MATRICULE.trim();
  const adminEmail =
    process.env.TEST_ADMIN_EMAIL?.trim() || `${adminMatricule.toLowerCase()}@admin.local`;
  const adminUser = await ensureUser(
    adminEmail,
    process.env.TEST_ADMIN_PASSWORD,
    process.env.TEST_ADMIN_NAME?.trim() || 'Integration Admin'
  );

  const adminPayload = {
    uid: adminUser.uid,
    email: adminEmail,
    matricule: adminMatricule,
    name: process.env.TEST_ADMIN_NAME?.trim() || 'Integration Admin',
    role: process.env.TEST_ADMIN_ROLE?.trim() || 'admin',
    password: process.env.TEST_ADMIN_PASSWORD,
  };

  await db.collection('admins').doc(adminUser.uid).set(adminPayload, { merge: true });
  await db.collection('admins').doc(adminEmail).set(adminPayload, { merge: true });

  console.log('Integration test data seeded successfully.');
  console.log(`user=${process.env.TEST_USER_EMAIL}`);
  console.log(`banned=${process.env.TEST_BANNED_EMAIL}`);
  console.log(`admin=${adminEmail} (${adminMatricule})`);
}

main()
  .catch((error) => {
    console.error(error.message || error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await admin.app().delete();
  });