#!/usr/bin/env node

/**
 * Batch create Firebase Auth accounts for admins from Firestore.
 * 
 * Usage:
 *   1. Install dependencies: npm install firebase-admin
 *   2. Set GOOGLE_APPLICATION_CREDENTIALS environment variable to your Firebase service account key
 *   3. Run: node create_admin_accounts.js
 * 
 * This script reads all admin documents from Firestore and creates corresponding
 * Firebase Auth accounts using the email and password from each admin doc.
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
// Ensure GOOGLE_APPLICATION_CREDENTIALS environment variable is set
if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error(
    'Error: GOOGLE_APPLICATION_CREDENTIALS environment variable not set.'
  );
  console.error('Please set it to the path of your Firebase service account key JSON file.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const auth = admin.auth();
const db = admin.firestore();

/**
 * Create a Firebase Auth account for an admin.
 */
async function createAdminAuthAccount(admin_email, password, matricule) {
  try {
    // Check if user already exists
    try {
      const existingUser = await auth.getUserByEmail(admin_email);
      console.log(
        `⚠️  Admin account already exists: ${admin_email} (UID: ${existingUser.uid})`
      );
      return existingUser.uid;
    } catch (err) {
      if (err.code !== 'auth/user-not-found') {
        throw err;
      }
      // User doesn't exist, proceed with creation
    }

    // Create the user
    const userRecord = await auth.createUser({
      email: admin_email,
      password: password,
      displayName: matricule,
    });

    console.log(
      `✅ Created Firebase Auth account: ${admin_email} (UID: ${userRecord.uid})`
    );
    return userRecord.uid;
  } catch (error) {
    console.error(
      `❌ Error creating account for ${admin_email}:`,
      error.message
    );
    throw error;
  }
}

/**
 * Main script: fetch admins from Firestore and create Auth accounts.
 */
async function main() {
  try {
    console.log('🔧 Starting admin Firebase Auth account batch creation...\n');

    // Fetch all admin documents from Firestore
    const adminSnapshot = await db.collection('admins').get();

    if (adminSnapshot.empty) {
      console.log('⚠️  No admins found in Firestore.');
      return;
    }

    console.log(`📋 Found ${adminSnapshot.size} admin(s) in Firestore.\n`);

    let successCount = 0;
    let skipCount = 0;
    let errorCount = 0;

    // Process each admin
    for (const doc of adminSnapshot.docs) {
      const adminData = doc.data();
      const matricule = adminData.matricule;
      const password = adminData.password;

      // Use email from doc, or construct from matricule
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
        const uid = await createAdminAuthAccount(email, password, matricule);
        successCount++;
      } catch (error) {
        if (error.code === 'auth/email-already-exists') {
          console.log(`⚠️  Email already registered: ${email}`);
          skipCount++;
        } else {
          errorCount++;
        }
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
