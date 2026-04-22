/**
 * End-to-end test: simulates the exact Firestore queries the Flutter app
 * performs when a user types "Mahdia" → "Monastir" and taps Search.
 */
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function testSearchFlow(departureText, arrivalText) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`SEARCH: "${departureText}" → "${arrivalText}"`);
  console.log('='.repeat(60));

  // ── Step 1: searchStationsByName (what journey_input_screen does) ──
  console.log('\n── Step 1: Search stations by name ──');
  const allStations = await db.collection('stations').get();
  const fromMatches = allStations.docs
    .filter(d => d.data().name.toLowerCase().includes(departureText.toLowerCase()));
  const toMatches = allStations.docs
    .filter(d => d.data().name.toLowerCase().includes(arrivalText.toLowerCase()));

  console.log(`  "${departureText}" → ${fromMatches.length} match(es):`,
    fromMatches.map(d => `${d.id} (${d.data().name})`).join(', ') || 'NONE');
  console.log(`  "${arrivalText}" → ${toMatches.length} match(es):`,
    toMatches.map(d => `${d.id} (${d.data().name})`).join(', ') || 'NONE');

  if (fromMatches.length === 0 || toMatches.length === 0) {
    console.log('\n❌ FAIL: Station not found. The search text must contain a station name.');
    console.log('   Available station names:', allStations.docs.map(d => d.data().name).join(', '));
    return;
  }

  const fromStationId = fromMatches[0].id;
  const toStationId = toMatches[0].id;
  console.log(`  → fromStationId = ${fromStationId}`);
  console.log(`  → toStationId   = ${toStationId}`);

  // ── Step 2: getStationById (what journey_search_controller does) ──
  console.log('\n── Step 2: Get station docs by ID ──');
  const fromDoc = await db.collection('stations').doc(fromStationId).get();
  const toDoc = await db.collection('stations').doc(toStationId).get();

  if (!fromDoc.exists || !toDoc.exists) {
    console.log('❌ FAIL: Station doc not found by ID');
    return;
  }

  const fromData = fromDoc.data();
  const toData = toDoc.data();
  console.log(`  From: ${fromData.name} — operatorsHere: [${fromData.operatorsHere}]`);
  console.log(`  To:   ${toData.name} — operatorsHere: [${toData.operatorsHere}]`);

  const fromIsMetro = (fromData.operatorsHere || []).includes('sncft_sahel');
  const toIsMetro = (toData.operatorsHere || []).includes('sncft_sahel');
  console.log(`  isMetroSahel: from=${fromIsMetro}, to=${toIsMetro}`);

  if (!fromIsMetro || !toIsMetro) {
    console.log('❌ FAIL: One or both stations are not Metro Sahel stations');
    return;
  }

  // ── Step 3: findMetroSahelRouteId (route_repository) ──
  console.log('\n── Step 3: Find route and stop orders ──');
  const routeStops = await db.collection('route_stops')
    .where('routeId', '==', 'route_ms_504')
    .get();

  let fromOrder = -1, toOrder = -1;
  routeStops.docs.forEach(d => {
    const rs = d.data();
    if (rs.stationId === fromStationId) fromOrder = rs.stopOrder;
    if (rs.stationId === toStationId) toOrder = rs.stopOrder;
  });

  console.log(`  fromOrder = ${fromOrder}, toOrder = ${toOrder}`);

  let routeId;
  if (fromOrder !== -1 && toOrder !== -1) {
    routeId = fromOrder < toOrder ? 'route_ms_504' : 'route_ms_504_rev';
    console.log(`  Direction: ${fromOrder < toOrder ? 'forward' : 'reverse'} → routeId = ${routeId}`);
  } else {
    console.log('❌ FAIL: Station(s) not found in route_stops');
    return;
  }

  const numberOfStops = Math.abs(toOrder - fromOrder);
  console.log(`  numberOfStops = ${numberOfStops}`);

  // ── Step 4: Query trips (journey_repository) ──
  console.log('\n── Step 4: Query trips ──');
  const now = new Date();
  const dayOfWeek = now.getDay(); // 0=Sunday like Dart's weekday%7
  console.log(`  Current time: ${now.toLocaleTimeString()} (dayOfWeek=${dayOfWeek})`);

  const tripsSnap = await db.collection('trips')
    .where('routeId', '==', routeId)
    .where('daysOfWeek', 'array-contains', dayOfWeek)
    .get();

  console.log(`  Matching trips for routeId=${routeId}, day=${dayOfWeek}: ${tripsSnap.docs.length}`);

  if (tripsSnap.docs.length === 0) {
    console.log('❌ FAIL: No trips found for this route and day');
    return;
  }

  // ── Step 5: Parse timestamps and find next departure ──
  console.log('\n── Step 5: Find next departure ──');
  const searchMinutes = now.getHours() * 60 + now.getMinutes();
  console.log(`  Search time in minutes: ${searchMinutes}`);

  const candidates = [];
  let firstDepartureOfDay = null;
  let firstDepartureMinutes = 99999;

  tripsSnap.docs.forEach(doc => {
    const data = doc.data();
    const depTimestamp = data.departureTime;

    if (!depTimestamp || !depTimestamp.toDate) {
      console.log(`  ⚠️ Trip ${data.tripNumber}: departureTime is NOT a Timestamp! Type: ${typeof depTimestamp}`);
      return;
    }

    const depDate = depTimestamp.toDate();
    const tripMinutes = depDate.getHours() * 60 + depDate.getMinutes();
    const timeStr = `${String(depDate.getHours()).padStart(2, '0')}:${String(depDate.getMinutes()).padStart(2, '0')}`;

    if (tripMinutes < firstDepartureMinutes) {
      firstDepartureMinutes = tripMinutes;
      firstDepartureOfDay = timeStr;
    }

    if (tripMinutes >= searchMinutes) {
      candidates.push({ ...data, _minutes: tripMinutes, _timeStr: timeStr });
    }
  });

  console.log(`  First departure of day: ${firstDepartureOfDay}`);
  console.log(`  Candidates after current time: ${candidates.length}`);

  // ── Step 6: Build result ──
  console.log('\n── Step 6: Build result ──');
  if (candidates.length === 0) {
    console.log('  No more trains today → showing "tomorrow" result');
    const price = 0.550 + Math.floor((numberOfStops - 1) / 3) * 0.250;
    console.log(`  From: ${fromData.name}, To: ${toData.name}`);
    console.log(`  Price: ${price.toFixed(3)} TND`);
    console.log(`  Departure: ${firstDepartureOfDay} (next day)`);
    console.log('  ✅ PASS: Would display "no train today" card');
  } else {
    candidates.sort((a, b) => a._minutes - b._minutes);
    const next = candidates[0];
    const price = 0.550 + Math.floor((numberOfStops - 1) / 3) * 0.250;
    const durationMinutes = numberOfStops * 4;
    const depMin = next._minutes;
    const arrMin = depMin + durationMinutes;
    const arrivalTime = `${String(Math.floor(arrMin / 60)).padStart(2, '0')}:${String(arrMin % 60).padStart(2, '0')}`;

    console.log(`  Trip #${next.tripNumber}`);
    console.log(`  From: ${fromData.name} → To: ${toData.name}`);
    console.log(`  Departure: ${next._timeStr}`);
    console.log(`  Arrival:   ${arrivalTime}`);
    console.log(`  Duration:  ${durationMinutes} min`);
    console.log(`  Price:     ${price.toFixed(3)} TND`);
    console.log(`  Stops:     ${numberOfStops}`);
    console.log('  ✅ PASS: Would display Metro Sahel card');
  }
}

(async () => {
  try {
    // Test standard searches
    await testSearchFlow('Mahdia', 'Monastir');
    await testSearchFlow('Sousse', 'Mahdia');
    await testSearchFlow('Monastir', 'Sousse Sud');
    // Test partial name match
    await testSearchFlow('mah', 'mon');
    // Test non-existent station
    await testSearchFlow('Tunis', 'Monastir');
  } catch (err) {
    console.error('\n💥 UNCAUGHT ERROR:', err);
  }
  process.exit(0);
})();
