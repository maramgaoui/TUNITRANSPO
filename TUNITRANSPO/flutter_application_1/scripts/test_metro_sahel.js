const admin = require('firebase-admin');
const sa = require('./firebase-key.json');
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

async function test() {
  // 1. Check stations
  const stations = await db.collection('stations').get();
  console.log('=== STATIONS (' + stations.size + ') ===');
  stations.docs.forEach(d => {
    const data = d.data();
    console.log('  ' + d.id + ' => "' + data.name + '" operators:', data.operatorsHere);
  });

  // 2. Check route_stops
  const stops = await db.collection('route_stops').get();
  console.log('\n=== ROUTE_STOPS (' + stops.size + ') ===');
  stops.docs.slice(0, 3).forEach(d => console.log('  ', d.id, JSON.stringify(d.data())));

  // 3. Check trips
  const trips = await db.collection('trips').get();
  console.log('\n=== TRIPS (' + trips.size + ') ===');
  trips.docs.slice(0, 3).forEach(d => console.log('  ', d.id, JSON.stringify(d.data())));

  // 4. Simulate search
  const mahdia = stations.docs.filter(d => d.data().name.toLowerCase().includes('mahdia'));
  const monastir = stations.docs.filter(d => d.data().name.toLowerCase().includes('monastir'));
  console.log('\n=== SEARCH TEST ===');
  console.log('Mahdia matches:', mahdia.map(d => d.id + ' = ' + d.data().name));
  console.log('Monastir matches:', monastir.map(d => d.id + ' = ' + d.data().name));

  if (mahdia.length > 0 && monastir.length > 0) {
    const fromId = mahdia[0].id;
    const toId = monastir[0].id;
    console.log('From:', fromId, 'To:', toId);

    const routeStops504 = await db.collection('route_stops').where('routeId', '==', 'route_ms_504').get();
    let fromOrder = -1, toOrder = -1;
    routeStops504.docs.forEach(d => {
      if (d.data().stationId === fromId) fromOrder = d.data().stopOrder;
      if (d.data().stationId === toId) toOrder = d.data().stopOrder;
    });
    console.log('fromOrder:', fromOrder, 'toOrder:', toOrder);
    const routeId = fromOrder < toOrder ? 'route_ms_504' : 'route_ms_503';
    console.log('routeId:', routeId);

    const now = new Date();
    const dow = now.getDay();
    console.log('Day of week (JS):', dow, '  Dart weekday%7 would be:', now.getDay());
    const tripsForRoute = await db.collection('trips').where('routeId', '==', routeId).where('daysOfWeek', 'array-contains', dow).get();
    console.log('Trips matching route+day:', tripsForRoute.size);
    if (tripsForRoute.size > 0) {
      console.log('Sample trip:', JSON.stringify(tripsForRoute.docs[0].data()));
    } else {
      console.log('NO TRIPS FOUND! Checking what daysOfWeek values exist...');
      const allTripsForRoute = await db.collection('trips').where('routeId', '==', routeId).get();
      console.log('Total trips for route:', allTripsForRoute.size);
      if (allTripsForRoute.size > 0) {
        console.log('Sample daysOfWeek:', JSON.stringify(allTripsForRoute.docs[0].data().daysOfWeek));
      }
    }
  } else {
    console.log('PROBLEM: Station name search returned no matches!');
  }

  process.exit(0);
}
test().catch(e => { console.error(e); process.exit(1); });
