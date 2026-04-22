/**
 * Seed script: SNCFT Tunis <-> Le Kef <-> Kalaa Khasba
 *
 * Collections written:
 *   operators, stations, routes, route_stops, trips, tariffs
 *
 * Usage:
 *   node seed_sncft_kef.js
 *   node seed_sncft_kef.js --skip-cleanup
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccount = require('./firebase-key.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const dataPath = path.join(__dirname, 'data', 'sncft_kef_timetable.json');
const timetable = JSON.parse(fs.readFileSync(dataPath, 'utf8'));

const SHARED_HUB_IDS = new Set(['bs_tunis_ville', 'bs_jebel_jelloud']);

function ts(y, m, d, h = 0, mn = 0) {
  return admin.firestore.Timestamp.fromDate(new Date(y, m - 1, d, h, mn, 0, 0));
}

function timeToMin(t) {
  const [h, m] = t.split(':').map(Number);
  return h * 60 + m;
}

function minToTs(totalMinutes, baseDate) {
  const minutes = ((totalMinutes % 1440) + 1440) % 1440;
  const date = new Date(baseDate);
  date.setHours(Math.floor(minutes / 60), minutes % 60, 0, 0);
  return admin.firestore.Timestamp.fromDate(date);
}

async function deleteDocsByField(collection, field, value) {
  const snap = await db.collection(collection).where(field, '==', value).get();
  if (snap.empty) return 0;
  let removed = 0;
  let batch = db.batch();
  let ops = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    ops++;
    removed++;
    if (ops >= 490) {
      await batch.commit();
      batch = db.batch();
      ops = 0;
    }
  }
  if (ops > 0) await batch.commit();
  return removed;
}

async function seed() {
  console.log('🚂 Seeding SNCFT Kef/Kalaa Khasba line...\n');

  const stations = [...timetable.stations].sort((a, b) => a.order - b.order);
  const routes = timetable.routes;

  const routeStopsMap = {};
  for (const route of routes) {
    routeStopsMap[route.id] = timetable.routeStops
      .filter((rs) => rs.routeId === route.id)
      .sort((a, b) => a.stopOrder - b.stopOrder);
  }

  const stationOffsetByRoute = {};
  for (const route of routes) {
    const map = {};
    for (const stop of routeStopsMap[route.id]) {
      map[stop.stationId] = stop.estimatedArrivalTimeMinutes;
    }
    stationOffsetByRoute[route.id] = map;
  }

  const validFromDate = new Date(timetable.metadata.validFrom);
  const validToDate = new Date(timetable.metadata.validTo);
  const validFrom = admin.firestore.Timestamp.fromDate(validFromDate);
  const validTo = admin.firestore.Timestamp.fromDate(validToDate);
  const baseDate = validFromDate;

  const batches = [db.batch()];
  let ops = 0;
  function b() {
    if (ops >= 490) {
      batches.push(db.batch());
      ops = 0;
    }
    ops++;
    return batches[batches.length - 1];
  }

  console.log('🏢 Upserting operator...');
  b().set(
    db.collection('operators').doc(timetable.operator.id),
    {
      name: timetable.operator.name,
      typeId: timetable.operator.typeId,
      phone: timetable.operator.phone,
      createdAt: ts(2025, 1, 1),
    },
    { merge: true },
  );
  console.log(`   ✓ ${timetable.operator.id}\n`);

  console.log(`🚉 Upserting ${stations.length} stations...`);
  for (const s of stations) {
    if (SHARED_HUB_IDS.has(s.id)) {
      b().update(db.collection('stations').doc(s.id), {
        operatorsHere: admin.firestore.FieldValue.arrayUnion('sncft', 'sncft_grandes_lignes'),
      });
    } else {
      b().set(
        db.collection('stations').doc(s.id),
        {
          name: s.name,
          cityId: s.cityId,
          latitude: s.lat,
          longitude: s.lng,
          address: null,
          transportTypes: ['train'],
          operatorsHere: ['sncft', 'sncft_grandes_lignes'],
          services: { wifi: false, toilet: true, cafe: false, parking: false },
          isMainHub: s.isMainHub,
          createdAt: ts(2025, 1, 1),
        },
        { merge: true },
      );
    }
  }
  console.log(`   ✓ ${stations.length} stations.\n`);

  if (process.argv.includes('--skip-cleanup')) {
    console.log('⏭️  Skipping cleanup (--skip-cleanup flag).\n');
  } else {
    for (const route of routes) {
      console.log(`🗑️  Clearing old data for ${route.id}...`);
      const [t, rs] = await Promise.all([
        deleteDocsByField('trips', 'routeId', route.id),
        deleteDocsByField('route_stops', 'routeId', route.id),
      ]);
      console.log(`   ✓ removed ${t} trips, ${rs} route_stops.\n`);
    }
  }

  console.log('🛤️  Creating routes, route_stops and trips...');
  for (const route of routes) {
    const stops = routeStopsMap[route.id];
    const stationOffsetMap = stationOffsetByRoute[route.id];
    const lastOffset = stops[stops.length - 1].estimatedArrivalTimeMinutes;
    const stopIds = stops.map((s) => s.stationId);

    b().set(db.collection('routes').doc(route.id), {
      operatorId: timetable.operator.id,
      typeId: timetable.operator.typeId,
      lineNumber: route.lineNumber,
      name: route.name,
      description: route.name,
      originStationId: route.originStationId,
      destinationStationId: route.destinationStationId,
      isCircular: false,
      isActive: true,
      stopIds,
      validFrom,
      validTo,
      createdAt: ts(2025, 1, 1),
    });

    for (const stop of stops) {
      const rsDocId = `${route.id}_${stop.stationId}`;
      b().set(db.collection('route_stops').doc(rsDocId), {
        routeId: route.id,
        stationId: stop.stationId,
        stopOrder: stop.stopOrder,
        estimatedArrivalTimeMinutes: stop.estimatedArrivalTimeMinutes,
        createdAt: ts(2025, 1, 1),
      });
    }

    let tripCount = 0;
    for (const trip of route.trips) {
      const depMin = timeToMin(trip.departureTime);
      const depTs = minToTs(depMin, baseDate);
      const termOffset = trip.terminatesAtStationId
        ? (stationOffsetMap[trip.terminatesAtStationId] ?? lastOffset)
        : lastOffset;
      const arrMin = depMin + termOffset;
      const arrTs = minToTs(arrMin, baseDate);
      const tripDocId = `${route.id.replace('route_', 'trip_')}_${trip.tripNumber.replace(/[^a-zA-Z0-9]/g, '_')}`;

      const tripDoc = {
        routeId: route.id,
        operatorId: timetable.operator.id,
        tripNumber: trip.tripNumber,
        departureTime: depTs,
        arrivalTime: arrTs,
        daysOfWeek: trip.operatingDays,
        validFrom,
        validTo,
        createdAt: ts(2025, 1, 1),
      };
      if (trip.terminatesAtStationId) tripDoc.terminatesAtStationId = trip.terminatesAtStationId;
      if (trip.originStationId) tripDoc.originStationId = trip.originStationId;
      if (trip.notes) tripDoc.notes = trip.notes;
      if (trip.stationTimeOverrides) {
        const overrideMinutes = {};
        for (const [stationId, timeStr] of Object.entries(trip.stationTimeOverrides)) {
          overrideMinutes[stationId] = timeToMin(timeStr);
        }
        tripDoc.stationTimeOverridesMinutes = overrideMinutes;
      }

      b().set(db.collection('trips').doc(tripDocId), tripDoc, { merge: true });
      tripCount++;
    }

    console.log(`   ✓ ${route.id}: ${stops.length} stops, ${tripCount} trips.`);
  }

  console.log('\n💰 Creating tariffs from estimated fares...');
  let tariffCount = 0;
  for (const f of (timetable.pricing?.estimatedFares || [])) {
    const pairs = [
      [f.from, f.to],
      [f.to, f.from],
    ];
    for (const [fromId, toId] of pairs) {
      const docId = `tariff_${fromId}_${toId}`;
      b().set(
        db.collection('tariffs').doc(docId),
        {
          operatorId: timetable.operator.id,
          fromStationId: fromId,
          toStationId: toId,
          price: f.price2ndClass,
          currency: timetable.pricing.currency || 'TND',
          tariffClass: '2nd',
          validFrom,
          validTo,
          notes: timetable.pricing.notes || null,
          specialDiscounts: [],
          createdAt: ts(2025, 1, 1),
        },
        { merge: true },
      );
      tariffCount++;
    }
  }
  console.log(`   ✓ ${tariffCount} tariff(s).\n`);

  console.log(`📤 Committing ${batches.length} batch(es)...`);
  for (let i = 0; i < batches.length; i++) {
    await batches[i].commit();
    console.log(`   batch ${i + 1}/${batches.length} done`);
  }

  console.log('\n✅ SNCFT Kef/Kalaa Khasba seeded successfully.');
}

seed().catch((err) => {
  console.error('\n❌ Seeding failed:', err);
  process.exit(1);
});
