const admin = require('firebase-admin');
const serviceAccount = require('./firebase-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function hhmmToMinutes(hhmm) {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
}

async function findNextTripAtStation({ routeId, stationId, dayOfWeek, searchTime }) {
  const routeStopsSnap = await db
    .collection('route_stops')
    .where('routeId', '==', routeId)
    .where('stationId', '==', stationId)
    .limit(1)
    .get();

  assert(!routeStopsSnap.empty, `No route_stop found for ${routeId} + ${stationId}`);
  const offset = routeStopsSnap.docs[0].data().estimatedArrivalTimeMinutes || 0;

  const tripsSnap = await db
    .collection('trips')
    .where('routeId', '==', routeId)
    .where('daysOfWeek', 'array-contains', dayOfWeek)
    .get();

  assert(!tripsSnap.empty, `No trips found for route ${routeId} on day ${dayOfWeek}`);

  const searchMinutes = hhmmToMinutes(searchTime);
  const candidates = [];

  for (const doc of tripsSnap.docs) {
    const data = doc.data();
    const depTs = data.departureTime;
    if (!depTs || typeof depTs.toDate !== 'function') continue;

    const depDate = depTs.toDate();
    const originMinutes = depDate.getHours() * 60 + depDate.getMinutes();
    const actualDepAtStation = originMinutes + offset;

    if (actualDepAtStation >= searchMinutes) {
      candidates.push({
        tripNumber: data.tripNumber,
        departureAtStation: actualDepAtStation,
      });
    }
  }

  assert(candidates.length > 0, `No upcoming trip for ${routeId} from ${stationId} at ${searchTime}`);

  candidates.sort((a, b) => a.departureAtStation - b.departureAtStation);
  return candidates[0];
}

async function verifyFare() {
  const t1 = await db.collection('tariffs').doc('tariff_bs_tunis_ville_be_bougatfa').get();
  const t2 = await db.collection('tariffs').doc('tariff_be_bougatfa_bs_tunis_ville').get();

  assert(t1.exists, 'Missing tariff_bs_tunis_ville_be_bougatfa');
  assert(t2.exists, 'Missing tariff_be_bougatfa_bs_tunis_ville');

  const d1 = t1.data();
  const d2 = t2.data();

  assert(d1.price === 0.7, `Expected fare 0.7 for tunis->bougatfa, got ${d1.price}`);
  assert(d2.price === 0.7, `Expected fare 0.7 for bougatfa->tunis, got ${d2.price}`);

  const discounts = d1.specialDiscounts || [];
  const child49 = discounts.find((x) => x.code === 'CHILD_4_9');
  const child03 = discounts.find((x) => x.code === 'CHILD_0_3');

  assert(child49 && child49.price === 0.525, 'Missing/invalid CHILD_4_9 discount');
  assert(child03 && child03.price === 0.0, 'Missing/invalid CHILD_0_3 discount');

  console.log('PASS fare: unified 0.700 with children discounts');
}

async function verifyDayBuckets() {
  const routeIds = ['route_line_e_forward', 'route_line_e_reverse'];
  const allowed = new Set([
    '[0]',
    '[1,2,3,4,5,6]',
    '[0,1,2,3,4,5,6]',
  ]);

  for (const routeId of routeIds) {
    const trips = await db.collection('trips').where('routeId', '==', routeId).get();
    assert(!trips.empty, `No trips for ${routeId}`);

    let invalid = 0;
    for (const doc of trips.docs) {
      const raw = JSON.stringify(doc.data().daysOfWeek || []);
      if (!allowed.has(raw)) invalid += 1;
    }

    assert(invalid === 0, `${routeId} contains ${invalid} trips with invalid daysOfWeek`);
  }

  console.log('PASS day buckets: only A/B/- mapping arrays are present');
}

async function verifyMarkerBehavior() {
  // Forward from origin station be_tunis:
  // Monday 05:26 should skip Sunday-only 05:25 and return 05:40 (trip 409)
  const mondayForward = await findNextTripAtStation({
    routeId: 'route_line_e_forward',
    stationId: 'bs_tunis_ville',
    dayOfWeek: 1,
    searchTime: '05:26',
  });
  assert(
    mondayForward.tripNumber === 409,
    `Expected Monday forward trip 409, got ${mondayForward.tripNumber}`,
  );

  // Sunday 05:26 should return 06:00 daily (trip 411) because 05:25 already passed
  const sundayForward = await findNextTripAtStation({
    routeId: 'route_line_e_forward',
    stationId: 'bs_tunis_ville',
    dayOfWeek: 0,
    searchTime: '05:26',
  });
  assert(
    sundayForward.tripNumber === 411,
    `Expected Sunday forward trip 411, got ${sundayForward.tripNumber}`,
  );

  // Reverse from origin station be_bougatfa:
  // Monday 05:45 should skip Sunday-only 05:50 and return 06:00 (trip 410)
  const mondayReverse = await findNextTripAtStation({
    routeId: 'route_line_e_reverse',
    stationId: 'be_bougatfa',
    dayOfWeek: 1,
    searchTime: '05:45',
  });
  assert(
    mondayReverse.tripNumber === 410,
    `Expected Monday reverse trip 410, got ${mondayReverse.tripNumber}`,
  );

  // Sunday 05:45 should return 05:50 Sunday-only (trip 408)
  const sundayReverse = await findNextTripAtStation({
    routeId: 'route_line_e_reverse',
    stationId: 'be_bougatfa',
    dayOfWeek: 0,
    searchTime: '05:45',
  });
  assert(
    sundayReverse.tripNumber === 408,
    `Expected Sunday reverse trip 408, got ${sundayReverse.tripNumber}`,
  );

  console.log('PASS marker behavior: weekday vs Sunday scheduling works as expected');
}

async function verifyStructure() {
  const routes = await db.collection('routes').where('lineNumber', '==', 'E').get();
  const ids = routes.docs.map((d) => d.id).sort();

  assert(ids.includes('route_line_e_forward'), 'Missing route_line_e_forward');
  assert(ids.includes('route_line_e_reverse'), 'Missing route_line_e_reverse');

  const stations = await db.collection('stations').where('operatorsHere', 'array-contains', 'sncft_banlieue_e').get();
  assert(stations.size >= 7, `Expected at least 7 Line E stations, got ${stations.size}`);

  console.log('PASS structure: routes and stations found');
}

(async () => {
  try {
    console.log('Running Line E validation...');

    await verifyStructure();
    await verifyDayBuckets();
    await verifyMarkerBehavior();
    await verifyFare();

    console.log('ALL PASS: Line E data is consistent with timetable and pricing logic.');
    process.exit(0);
  } catch (error) {
    console.error('FAIL:', error.message || error);
    process.exit(1);
  }
})();
