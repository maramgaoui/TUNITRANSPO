/**
 * Reseed Metro Sahel trips with CORRECT data from the official
 * SNCFT Winter 2025-2026 timetable (Mahdia-Monastir-Sousse).
 *
 * Fixes:
 * - Correct train numbers per direction (even=Mahdia→Sousse, odd=Sousse→Mahdia)
 * - Correct departure times from the official printed timetable
 * - Correct number of trains: 18 per direction (36 total), not 45
 */

const admin = require('firebase-admin');
const serviceAccount = require('./firebase-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ============================================================================
// OFFICIAL SNCFT METRO SAHEL TIMETABLE — Winter 2025-2026
// ============================================================================

// Mahdia → Sousse  (route_ms_504) — EVEN-numbered trains
// Departure time = from MAHDIA origin station
const trips_mahdia_sousse = [
  [504, '04:55'],
  [506, '05:25'],
  [508, '06:10'],
  [510, '06:40'],
  [512, '07:50'],
  [514, '08:55'],
  [516, '09:50'],
  [518, '10:55'],   // semi-direct
  [520, '11:30'],
  [522, '12:05'],
  [524, '13:25'],
  [526, '14:30'],
  [528, '15:35'],
  [530, '16:25'],
  [532, '17:05'],
  [534, '18:15'],   // semi-direct
  [536, '18:50'],
  [538, '19:50'],
];

// Sousse → Mahdia  (route_ms_503) — ODD-numbered trains
// Departure time = from SOUSSE BAB JEDID origin station
const trips_sousse_mahdia = [
  [501, '05:40'],
  [503, '06:50'],
  [505, '07:30'],
  [507, '08:30'],
  [509, '08:50'],
  [511, '09:55'],
  [513, '11:05'],
  [515, '12:25'],
  [517, '13:05'],
  [519, '13:30'],
  [521, '14:05'],
  [523, '15:35'],
  [525, '16:40'],
  [527, '17:25'],
  [529, '18:30'],
  [531, '19:00'],
  [533, '19:30'],
  [535, '20:10'],
];

// ============================================================================
// HELPERS
// ============================================================================

function timeToMinutes(timeStr) {
  const [h, m] = timeStr.split(':').map(Number);
  return h * 60 + m;
}

function minutesToTimestamp(minutes, baseDate) {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  const dt = new Date(baseDate);
  dt.setHours(h, m, 0, 0);
  return admin.firestore.Timestamp.fromDate(dt);
}

const STATION_COUNT = 22;            // stops on our seeded line
const AVG_MINUTES_PER_STOP = 4;
const baseDate = new Date(2025, 9, 1); // Oct 1, 2025

// ============================================================================
// MAIN
// ============================================================================

async function reseedTrips() {
  console.log('=== Metro Sahel Trip Reseed ===\n');

  // ── Step 1: Delete ALL existing trips for both routes ──
  console.log('Step 1: Deleting old trip documents...');

  const oldTrips504 = await db.collection('trips')
    .where('routeId', '==', 'route_ms_504').get();
  const oldTrips503 = await db.collection('trips')
    .where('routeId', '==', 'route_ms_503').get();

  const allOld = [...oldTrips504.docs, ...oldTrips503.docs];
  console.log(`  Found ${allOld.length} old trip documents to delete.`);

  // Delete in batches of 400
  for (let i = 0; i < allOld.length; i += 400) {
    const batch = db.batch();
    const slice = allOld.slice(i, i + 400);
    for (const doc of slice) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    console.log(`  Deleted batch ${Math.floor(i / 400) + 1} (${slice.length} docs)`);
  }
  console.log(`  ✓ All old trips deleted.\n`);

  // ── Step 2: Create new trips ──
  console.log('Step 2: Creating new trip documents...');

  const validFrom = admin.firestore.Timestamp.fromDate(new Date(2025, 9, 1));
  const validTo   = admin.firestore.Timestamp.fromDate(new Date(2026, 8, 30));
  const createdAt = admin.firestore.Timestamp.fromDate(new Date(2025, 0, 1));

  const batch = db.batch();
  let count = 0;

  // Mahdia → Sousse (route_ms_504)
  for (const [tripNum, timeStr] of trips_mahdia_sousse) {
    const depMin = timeToMinutes(timeStr);
    const arrMin = depMin + STATION_COUNT * AVG_MINUTES_PER_STOP;

    const ref = db.collection('trips').doc(`trip_504_${tripNum}`);
    batch.set(ref, {
      routeId: 'route_ms_504',
      tripNumber: tripNum,
      departureTime: minutesToTimestamp(depMin, baseDate),
      arrivalTime: minutesToTimestamp(arrMin, baseDate),
      capacity: 300,
      availableSeats: 300,
      daysOfWeek: [0, 1, 2, 3, 4, 5, 6],
      validFrom,
      validTo,
      isActive: true,
      vehicleId: null,
      driverName: null,
      createdAt,
    });
    count++;
  }

  // Sousse → Mahdia (route_ms_503)
  for (const [tripNum, timeStr] of trips_sousse_mahdia) {
    const depMin = timeToMinutes(timeStr);
    const arrMin = depMin + STATION_COUNT * AVG_MINUTES_PER_STOP;

    const ref = db.collection('trips').doc(`trip_503_${tripNum}`);
    batch.set(ref, {
      routeId: 'route_ms_503',
      tripNumber: tripNum,
      departureTime: minutesToTimestamp(depMin, baseDate),
      arrivalTime: minutesToTimestamp(arrMin, baseDate),
      capacity: 300,
      availableSeats: 300,
      daysOfWeek: [0, 1, 2, 3, 4, 5, 6],
      validFrom,
      validTo,
      isActive: true,
      vehicleId: null,
      driverName: null,
      createdAt,
    });
    count++;
  }

  await batch.commit();
  console.log(`  ✓ ${count} new trips created (${trips_mahdia_sousse.length} forward + ${trips_sousse_mahdia.length} return)\n`);

  // ── Step 3: Verify ──
  console.log('Step 3: Verification...');
  const fwd = await db.collection('trips').where('routeId', '==', 'route_ms_504').get();
  const ret = await db.collection('trips').where('routeId', '==', 'route_ms_503').get();
  console.log(`  route_ms_504 (Mahdia→Sousse): ${fwd.docs.length} trips`);
  console.log(`  route_ms_503 (Sousse→Mahdia): ${ret.docs.length} trips`);

  // Show first + last departure for each route
  const showRange = (docs, label) => {
    const times = docs.map(d => {
      const ts = d.data().departureTime.toDate();
      return { num: d.data().tripNumber, h: ts.getHours(), m: ts.getMinutes() };
    }).sort((a, b) => a.h * 60 + a.m - (b.h * 60 + b.m));
    const first = times[0];
    const last  = times[times.length - 1];
    console.log(`  ${label}: first #${first.num} at ${String(first.h).padStart(2,'0')}:${String(first.m).padStart(2,'0')}, last #${last.num} at ${String(last.h).padStart(2,'0')}:${String(last.m).padStart(2,'0')}`);
  };
  showRange(fwd.docs, 'Mahdia→Sousse');
  showRange(ret.docs, 'Sousse→Mahdia');

  console.log('\n✅ Done! Trip data now matches the official SNCFT timetable.');
}

reseedTrips().catch(err => {
  console.error('ERROR:', err);
  process.exit(1);
}).then(() => process.exit(0));
