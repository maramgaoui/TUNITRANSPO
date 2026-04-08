# Admin Firebase Auth Batch Creation

This script automatically creates Firebase Auth accounts for all admins defined in your Firestore `admins` collection.

## Prerequisites

1. **Node.js** installed on your machine
2. **Firebase Admin credentials via ADC** (Application Default Credentials)
3. Admin documents in Firestore with fields: `matricule`, `password`, and optionally `email`

## Setup

### Step 1: Prepare Firebase Admin Credentials (ADC)

1. In CI/Cloud runtime, use the runtime service account with required IAM roles.
2. For local runs, use a secure service account JSON outside the repository.
3. Set `GOOGLE_APPLICATION_CREDENTIALS` to that external JSON path.

### Step 2: Install Dependencies

```bash
cd scripts
npm install firebase-admin
```

### Step 3: Run the Script

Set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable and run:

**On Windows (PowerShell):**
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\secure\firebase\service-account.json"
node create_admin_accounts.js
```

**On Windows (Command Prompt):**
```cmd
set GOOGLE_APPLICATION_CREDENTIALS=C:\secure\firebase\service-account.json
node create_admin_accounts.js
```

**On macOS/Linux:**
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/secure/firebase/service-account.json"
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
- Never commit service account JSON files to version control
- Keep your Firebase service account key outside this repository
- The script reads passwords from Firestore — consider migrating to password hashing if not already done
- Use environment-based ADC wherever possible

## Troubleshooting

**Error: "Firebase Admin credentials not detected"**
- Ensure `GOOGLE_APPLICATION_CREDENTIALS` points to a valid service account file, or run in a trusted Google runtime.

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
