# Admin Firebase Auth Batch Creation

This script automatically creates Firebase Auth accounts for all admins defined in your Firestore `admins` collection.

## Prerequisites

1. **Node.js** installed on your machine
2. **Firebase service account key** (JSON file from Firebase Console)
3. Admin documents in Firestore with fields: `matricule`, `password`, and optionally `email`

## Setup

### Step 1: Download Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Project Settings** → **Service Accounts**
4. Click **Generate New Private Key**
5. Save the JSON file to a secure location, e.g., `scripts/firebase-key.json`

### Step 2: Install Dependencies

```bash
cd scripts
npm install firebase-admin
```

### Step 3: Run the Script

Set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable and run:

**On Windows (PowerShell):**
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "$(Get-Location)\firebase-key.json"
node create_admin_accounts.js
```

**On Windows (Command Prompt):**
```cmd
set GOOGLE_APPLICATION_CREDENTIALS=%cd%\firebase-key.json
node create_admin_accounts.js
```

**On macOS/Linux:**
```bash
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/firebase-key.json"
node create_admin_accounts.js
```

## Expected Firestore Collection Structure

Your `admins` collection should have documents like:

```
admins/
  doc1/
    matricule: "MAT001"
    password: "admin123"
    email: "mat001@admin.local"  (optional, defaults to matricule@admin.local)
    role: "superadmin"
    name: "Admin Name"
  doc2/
    matricule: "MAT002"
    password: "secure_password"
    role: "admin"
    name: "Another Admin"
```

## What the Script Does

1. Fetches all admin documents from Firestore
2. For each admin:
   - Uses the `email` field if present, otherwise constructs `matricule@admin.local`
   - Uses the `password` field to create the Firebase Auth account
   - Sets the `displayName` to the `matricule` value
3. Skips accounts that already exist
4. Reports success/error for each account

## Output Example

```
🔧 Starting admin Firebase Auth account batch creation...

📋 Found 2 admin(s) in Firestore.

✅ Created Firebase Auth account: mat001@admin.local (UID: abc123...)
⚠️  Admin account already exists: mat002@admin.local (UID: def456...)

📊 Summary:
  ✅ Created: 1
  ⚠️  Already exists: 1
  ❌ Errors: 0

✨ All admins processed successfully!
```

## Security Notes

⚠️ **Important:**
- Never commit `firebase-key.json` to version control
- Keep your Firebase service account key secure
- The script reads passwords from Firestore — consider migrating to password hashing if not already done
- Add `.gitignore` entry: `scripts/firebase-key.json`

## Troubleshooting

**Error: "GOOGLE_APPLICATION_CREDENTIALS environment variable not set"**
- Ensure you've exported/set the environment variable with the correct path to your JSON key

**Error: "auth/invalid-password"**
- The password must be at least 6 characters

**Error: "auth/invalid-email"**
- The constructed email address is invalid. Check the `email` field in Firestore or ensure `matricule` is email-compatible

**Error: "auth/too-many-requests"**
- You've exceeded Firebase auth API limits. Wait a few minutes and try again.

## Next Steps

Once accounts are created, admins can log in using:
- **Email:** The email from their Firestore doc (or matricule@admin.local)
- **Password:** The password from their Firestore doc
