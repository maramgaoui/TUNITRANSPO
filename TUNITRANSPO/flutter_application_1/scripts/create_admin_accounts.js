#!/usr/bin/env node

const { admin, initializeFirebaseAdmin } = require('./firebase_admin_init');

try {
  initializeFirebaseAdmin();
} catch (error) {
  console.error(`Error: ${error.message}`);
  process.exit(1);
}

const auth = admin.auth();
const db = admin.firestore();

/** @returns {{ uid: string, created: boolean }} */
async function createAdminAuthAccount(admin_email, password, matricule) {
  // Check if user already exists
  try {
    const existingUser = await auth.getUserByEmail(admin_email);
    console.log(
      `⚠️  Admin account already exists: ${admin_email} (UID: ${existingUser.uid})`
    );
    return { uid: existingUser.uid, created: false };
  } catch (err) {
    if (err.code !== 'auth/user-not-found') throw err;
  }

  // Create the user
  const userRecord = await auth.createUser({
    email: admin_email,
    password,
    displayName: matricule,
  });

  console.log(
    `✅ Created Firebase Auth account: ${admin_email} (UID: ${userRecord.uid})`
  );
  return { uid: userRecord.uid, created: true };
}

async function main() {
  try {
    console.log('🔧 Starting admin Firebase Auth account batch creation...\n');

    const adminSnapshot = await db.collection('admins').get();

    if (adminSnapshot.empty) {
      console.log('⚠️  No admins found in Firestore.');
      return;
    }

    console.log(`📋 Found ${adminSnapshot.size} admin(s) in Firestore.\n`);

    let successCount = 0;
    let skipCount = 0;
    let errorCount = 0;

    for (const doc of adminSnapshot.docs) {
      const adminData = doc.data();
      const { matricule, password } = adminData;

      let email = adminData.email;
      if (!email) {
        email = `${matricule.toLowerCase()}@admin.local`;
      }

      if (!password) {
        console.error(`❌ Admin ${matricule} has no password in Firestore. Skipping.`);
        errorCount++;
        continue;
      }

      try {
        const { uid, created } = await createAdminAuthAccount(email, password, matricule);

        await db.collection('admins').doc(uid).set(
          { ...adminData, uid },
          { merge: true }
        );
        console.log(`  🔑 UID document written: admins/${uid}`);

        if (created) {
          successCount++;
        } else {
          skipCount++;
        }
      } catch (error) {
        console.error(`❌ Error processing ${email}:`, error.message);
        errorCount++;
      }
    }

    console.log('\n📊 Summary:');
    console.log(`  ✅ Created: ${successCount}`);
    console.log(`  ⚠️  Already exists: ${skipCount}`);
    console.log(`  ❌ Errors: ${errorCount}`);

    if (errorCount === 0 && successCount + skipCount === adminSnapshot.size) {
      console.log('\n✨ All admins processed successfully!');
    }
  } catch (error) {
    console.error('💥 Fatal error:', error.message);
    process.exit(1);
  } finally {
    await admin.app().delete();
  }
}

main();