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

async function verifyStructure() {
  const routes = await db.collection('routes').where('lineNumber', '==', 'BS').get();
  const ids = routes.docs.map((d) => d.id).sort();

  assert(ids.includes('route_bs_south'), 'Missing route_bs_south');
  assert(ids.includes('route_bs_north'), 'Missing route_bs_north');

  const stations = await db
    .collection('stations')
    .where('operatorsHere', 'array-contains', 'sncft_banlieue_sud')
    .get();
  assert(stations.size >= 19, `Expected at least 19 Banlieue Sud stations, got ${stations.size}`);

  const routeStops = await db.collection('route_stops').where('routeId', '==', 'route_bs_north').get();
  assert(routeStops.size === 19, `Expected 19 northbound route stops, got ${routeStops.size}`);

  console.log('PASS structure: routes, stations, and route stops found');
}

async function verifyFareTiers() {
  const checks = [
    ['tariff_bs_tunis_ville_bs_megrine', 0.5],
    ['tariff_bs_tunis_ville_bs_ezzahra', 1.0],
    ['tariff_bs_tunis_ville_bs_tahar_sfar', 1.45],
    ['tariff_bs_tunis_ville_bs_erriadh', 1.9],
    ['tariff_bs_erriadh_bs_tunis_ville', 1.9],
  ];

  for (const [id, expected] of checks) {
    const doc = await db.collection('tariffs').doc(id).get();
    assert(doc.exists, `Missing ${id}`);
    const data = doc.data();
    assert(data.price === expected, `Expected ${id} to be ${expected}, got ${data.price}`);
  }

  console.log('PASS fares: section-based tiers match expected prices');
}

async function verifyDayBuckets() {
  const southTrips = await db.collection('trips').where('routeId', '==', 'route_bs_south').get();
  const northTrips = await db.collection('trips').where('routeId', '==', 'route_bs_north').get();

  assert(southTrips.size === 53, `Expected 53 southbound trips, got ${southTrips.size}`);
  assert(northTrips.size === 52, `Expected 52 northbound trips, got ${northTrips.size}`);

  const allowedDayBuckets = new Set([
    '[0,6]',
    '[1,2,3,4,5]',
    '[0]',
    '[0,1,2,3,4,5,6]',
  ]);

  for (const doc of southTrips.docs) {
    const raw = JSON.stringify(doc.data().daysOfWeek || []);
    assert(allowedDayBuckets.has(raw), `Southbound trip ${doc.id} has invalid daysOfWeek ${raw}`);
  }

  for (const doc of northTrips.docs) {
    const raw = JSON.stringify(doc.data().daysOfWeek || []);
    assert(allowedDayBuckets.has(raw), `Northbound trip ${doc.id} has invalid daysOfWeek ${raw}`);
  }

  console.log('PASS day buckets: Banlieue Sud uses only expected daily, weekday, and weekend arrays');
}

async function verifyNorthboundDayBehavior() {
  const mondayMorning = await findNextTripAtStation({
    routeId: 'route_bs_north',
    stationId: 'bs_erriadh',
    dayOfWeek: 1,
    searchTime: '06:26',
  });
  assert(
    mondayMorning.tripNumber === 122,
    `Expected Monday northbound trip 122 after 06:26, got ${mondayMorning.tripNumber}`,
  );

  const sundayMorning = await findNextTripAtStation({
    routeId: 'route_bs_north',
    stationId: 'bs_erriadh',
    dayOfWeek: 0,
    searchTime: '06:26',
  });
  assert(
    sundayMorning.tripNumber === 124,
    `Expected Sunday northbound trip 124 after 06:26, got ${sundayMorning.tripNumber}`,
  );

  const mondayAfternoon = await findNextTripAtStation({
    routeId: 'route_bs_north',
    stationId: 'bs_erriadh',
    dayOfWeek: 1,
    searchTime: '16:15',
  });
  assert(
    mondayAfternoon.tripNumber === 212,
    `Expected Monday northbound trip 212 after 16:15, got ${mondayAfternoon.tripNumber}`,
  );

  const sundayAfternoon = await findNextTripAtStation({
    routeId: 'route_bs_north',
    stationId: 'bs_erriadh',
    dayOfWeek: 0,
    searchTime: '16:15',
  });
  assert(
    sundayAfternoon.tripNumber === 208,
    `Expected Sunday northbound trip 208 after 16:15, got ${sundayAfternoon.tripNumber}`,
  );

  console.log('PASS day behavior: weekday vs Sunday northbound selection works as expected');
}

async function verifySouthboundDayBehavior() {
  const mondayMorning = await findNextTripAtStation({
    routeId: 'route_bs_south',
    stationId: 'bs_tunis_ville',
    dayOfWeek: 1,
    searchTime: '07:31',
  });
  assert(
    mondayMorning.tripNumber === 133,
    `Expected Monday southbound trip 133 after 07:31, got ${mondayMorning.tripNumber}`,
  );

  const sundayMorning = await findNextTripAtStation({
    routeId: 'route_bs_south',
    stationId: 'bs_tunis_ville',
    dayOfWeek: 0,
    searchTime: '07:31',
  });
  assert(
    sundayMorning.tripNumber === 131,
    `Expected Sunday southbound trip 131 after 07:31, got ${sundayMorning.tripNumber}`,
  );

  console.log('PASS day behavior: weekday vs Sunday southbound selection works as expected');
}

(async () => {
  try {
    console.log('Running Banlieue Sud validation...');

    await verifyStructure();
    await verifyFareTiers();
    await verifyDayBuckets();
    await verifyNorthboundDayBehavior();
    await verifySouthboundDayBehavior();

    console.log('ALL PASS: Banlieue Sud data is consistent with timetable, fares, and day logic.');
    process.exit(0);
  } catch (error) {
    console.error('FAIL:', error.message || error);
    process.exit(1);
  }
})();