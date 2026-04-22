const { admin, initializeFirebaseAdmin } = require('./firebase_admin_init');

initializeFirebaseAdmin();
const db = admin.firestore();

const ARABIC_NAMES = {
  bs_tunis_ville: 'تونس العاصمة',
  ms_mahdia: 'المهدية',
  ms_sousse_bab_jedid: 'سوسة باب الجديد',
  ms_monastir: 'المنستير',
  sncft_sfax: 'صفاقس',
  sncft_gabes: 'قابس',
  sncft_gafsa: 'قفصة',
  sncft_tozeur: 'توزر',
  sncft_bizerte: 'بنزرت',
};

async function run() {
  console.log('Starting station nameAr migration...');
  const stationsSnap = await db.collection('stations').get();

  if (stationsSnap.empty) {
    console.log('No station documents found.');
    return;
  }

  let updated = 0;
  let alreadyCorrect = 0;
  let usedNameFallback = 0;
  let skipped = 0;

  let batch = db.batch();
  let ops = 0;

  const commitBatch = async () => {
    if (ops === 0) return;
    await batch.commit();
    batch = db.batch();
    ops = 0;
  };

  for (const doc of stationsSnap.docs) {
    const data = doc.data();
    const mappedArabic = ARABIC_NAMES[doc.id];
    const existingNameAr = typeof data.nameAr === 'string' ? data.nameAr.trim() : '';
    const fallbackArabic = existingNameAr || (typeof data.name === 'string' ? data.name.trim() : '');

    const nameAr = mappedArabic || fallbackArabic;

    if (!nameAr) {
      skipped++;
      continue;
    }

    // Skip the write if the stored value is already correct
    if (data.nameAr === nameAr) {
      alreadyCorrect++;
      continue;
    }

    if (!mappedArabic) {
      usedNameFallback++;
    }

    batch.update(doc.ref, { nameAr });
    updated++;
    ops++;

    if (ops >= 450) {
      await commitBatch();
    }
  }

  await commitBatch();

  console.log(`Updated:          ${updated} station docs`);
  console.log(`Already correct:  ${alreadyCorrect}`);
  console.log(`Name fallback:    ${usedNameFallback}`);
  console.log(`Skipped:          ${skipped}`);
  console.log('Done. Extend ARABIC_NAMES and rerun for full Arabic coverage.');
}

run().catch((error) => {
  console.error('Migration failed:', error);
  process.exitCode = 1;
});