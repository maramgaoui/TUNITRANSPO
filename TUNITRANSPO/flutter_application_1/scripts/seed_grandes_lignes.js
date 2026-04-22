/**
 * Seed script: SNCFT Grandes Lignes
 *   - Tunis ↔ Annaba (via Béja, Jendouba, Ghardimaou, Souk Ahras)
 *   - Tunis ↔ Bizerte (via Manouba, Mateur, Tinja)
 *
 * Collections written:
 *   operators, stations, routes, route_stops, trips, tariffs
 *
 * Usage:
 *   node seed_grandes_lignes.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccount = require('./firebase-key.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const dataPath = path.join(__dirname, 'data', 'grandes_lignes_timetable.json');
const timetable = JSON.parse(fs.readFileSync(dataPath, 'utf8'));

// Shared hub stations (already created by other scripts).
// We use Firestore update + arrayUnion so we don't overwrite their operator lists.
const SHARED_HUB_IDS = new Set(['bs_tunis_ville']);

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

// ── helpers ──────────────────────────────────────────────────────────────────

async function deleteDocsByField(collection, field, value) {
  const snap = await db.collection(collection).where(field, '==', value).get();
  if (snap.empty) return 0;
  let removed = 0, batch = db.batch(), ops = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    ops++; removed++;
    if (ops >= 490) { await batch.commit(); batch = db.batch(); ops = 0; }
  }
  if (ops > 0) await batch.commit();
  return removed;
}

// ── main ─────────────────────────────────────────────────────────────────────

async function seed() {
  console.log('🚂 Seeding SNCFT Grandes Lignes (Annaba + Bizerte)…\n');

  const stations = [...timetable.stations].sort((a, b) => a.order - b.order);
  const routes   = timetable.routes;

  // Build per-route stop lists from routeStops
  const routeStopsMap = {};
  for (const route of routes) {
    routeStopsMap[route.id] = timetable.routeStops
      .filter((rs) => rs.routeId === route.id)
      .sort((a, b) => a.stopOrder - b.stopOrder);
  }

  // Build stationOffsetMap keyed by routeId → stationId → offset
  const stationOffsetByRoute = {};
  for (const route of routes) {
    const map = {};
    for (const stop of routeStopsMap[route.id]) {
      map[stop.stationId] = stop.estimatedArrivalTimeMinutes;
    }
    stationOffsetByRoute[route.id] = map;
  }

  const validFromDate = new Date(timetable.metadata.validFrom);
  const validToDate   = new Date(timetable.metadata.validTo);
  const validFrom     = admin.firestore.Timestamp.fromDate(validFromDate);
  const validTo       = admin.firestore.Timestamp.fromDate(validToDate);
  const baseDate      = validFromDate;

  const batches = [db.batch()];
  let ops = 0;
  function b() {
    if (ops >= 490) { batches.push(db.batch()); ops = 0; }
    ops++;
    return batches[batches.length - 1];
  }

  // ── 1. Operator ───────────────────────────────────────────────────────────
  console.log('🏢 Upserting operator…');
  b().set(
    db.collection('operators').doc(timetable.operator.id),
    {
      name:      timetable.operator.name,
      typeId:    timetable.operator.typeId,
      phone:     timetable.operator.phone,
      createdAt: ts(2025, 1, 1),
    },
    { merge: true },
  );
  console.log(`   ✓ ${timetable.operator.id}\n`);

  // ── 2. Stations ───────────────────────────────────────────────────────────
  console.log(`🚉 Upserting ${stations.length} stations…`);
  for (const s of stations) {
    if (SHARED_HUB_IDS.has(s.id)) {
      // Shared hub: just add our operator tag without overwriting existing data
      b().update(db.collection('stations').doc(s.id), {
        operatorsHere: admin.firestore.FieldValue.arrayUnion('sncft', 'sncft_grandes_lignes'),
      });
    } else {
      b().set(
        db.collection('stations').doc(s.id),
        {
          name:           s.name,
          cityId:         s.cityId,
          latitude:       s.lat,
          longitude:      s.lng,
          address:        null,
          transportTypes: ['train'],
          operatorsHere:  ['sncft', 'sncft_grandes_lignes'],
          services:       { wifi: false, toilet: true, cafe: false, parking: false },
          isMainHub:      s.isMainHub,
          createdAt:      ts(2025, 1, 1),
        },
        { merge: true },
      );
    }
  }
  console.log(`   ✓ ${stations.length} stations.\n`);

  // ── 3. Old trips / route_stops cleanup (skip with --skip-cleanup) ────────
  if (process.argv.includes('--skip-cleanup')) {
    console.log('⏭️  Skipping cleanup (--skip-cleanup flag).\n');
  } else {
    for (const route of routes) {
      console.log(`🗑️  Clearing old data for ${route.id}…`);
      const [t, rs] = await Promise.all([
        deleteDocsByField('trips',        'routeId', route.id),
        deleteDocsByField('route_stops',  'routeId', route.id),
      ]);
      console.log(`   ✓ removed ${t} trips, ${rs} route_stops.\n`);
    }
  }

  // ── 4. Routes + route_stops + trips ───────────────────────────────────────
  console.log('🛤️  Creating routes, route_stops and trips…');
  for (const route of routes) {
    const stops = routeStopsMap[route.id];
    const stationOffsetMap = stationOffsetByRoute[route.id];
    const lastOffset = stops[stops.length - 1].estimatedArrivalTimeMinutes;
    const stopIds = stops.map((s) => s.stationId);

    b().set(db.collection('routes').doc(route.id), {
      operatorId:           timetable.operator.id,
      typeId:               timetable.operator.typeId,
      lineNumber:           route.lineNumber,
      name:                 route.name,
      description:          route.name,
      originStationId:      route.originStationId,
      destinationStationId: route.destinationStationId,
      isCircular:           false,
      isActive:             true,
      stopIds,
      validFrom,
      validTo,
      createdAt:            ts(2025, 1, 1),
    });

    for (const stop of stops) {
      const rsDocId = `${route.id}_${stop.stationId}`;
      b().set(db.collection('route_stops').doc(rsDocId), {
        routeId:                       route.id,
        stationId:                     stop.stationId,
        stopOrder:                     stop.stopOrder,
        estimatedArrivalTimeMinutes:   stop.estimatedArrivalTimeMinutes,
        createdAt:                     ts(2025, 1, 1),
      });
    }

    let tripCount = 0;
    for (const trip of route.trips) {
      const depMin  = timeToMin(trip.departureTime);
      const depTs   = minToTs(depMin, baseDate);
      // Use terminatesAtStationId offset if available, otherwise full route
      const termOffset = trip.terminatesAtStationId
        ? (stationOffsetMap[trip.terminatesAtStationId] ?? lastOffset)
        : lastOffset;
      const arrMin  = depMin + termOffset;
      const arrTs   = minToTs(arrMin, baseDate);
      const tripDocId = `${route.id.replace('route_', 'trip_')}_${trip.tripNumber.replace(/[^a-zA-Z0-9]/g, '_')}`;

      const tripDoc = {
        routeId:          route.id,
        operatorId:       timetable.operator.id,
        tripNumber:       trip.tripNumber,
        departureTime:    depTs,
        arrivalTime:      arrTs,
        daysOfWeek:       trip.operatingDays,
        validFrom,
        validTo,
        createdAt:        ts(2025, 1, 1),
      };
      if (trip.terminatesAtStationId) {
        tripDoc.terminatesAtStationId = trip.terminatesAtStationId;
      }
      if (trip.originStationId) {
        tripDoc.originStationId = trip.originStationId;
      }
      if (trip.stationTimeOverrides) {
        const overrideMinutes = {};
        for (const [stationId, timeStr] of Object.entries(trip.stationTimeOverrides)) {
          overrideMinutes[stationId] = timeToMin(timeStr);
        }
        tripDoc.stationTimeOverridesMinutes = overrideMinutes;
      }
      b().set(db.collection('trips').doc(tripDocId), tripDoc);
      tripCount++;
    }

    console.log(`   ✓ ${route.id}: ${stops.length} stops, ${tripCount} trips.`);
  }
  console.log();

  // ── 5. Tariffs ────────────────────────────────────────────────────────────
  console.log('💰 Creating tariffs from estimated fares…');

  if (!process.argv.includes('--skip-cleanup')) {
    const stationIds = new Set(stations.map((s) => s.id));
    const tariffSnap = await db.collection('tariffs').get();
    const oldTariffs = tariffSnap.docs.filter((d) => {
      const data = d.data();
      return stationIds.has(data.fromStationId) && stationIds.has(data.toStationId);
    });
    if (oldTariffs.length > 0) {
      let batch = db.batch(), bOps = 0;
      for (const doc of oldTariffs) {
        batch.delete(doc.ref); bOps++;
        if (bOps >= 490) { await batch.commit(); batch = db.batch(); bOps = 0; }
      }
      if (bOps > 0) await batch.commit();
      console.log(`   🗑️  Removed ${oldTariffs.length} old tariff(s).`);
    }
  }

  const fares = timetable.pricing.estimatedFares;
  let tariffCount = 0;
  for (const fare of fares) {
    const tariffId    = `tariff_gl_${fare.from}_${fare.to}`;
    const tariffIdRev = `tariff_gl_${fare.to}_${fare.from}`;

    b().set(db.collection('tariffs').doc(tariffId), {
      operatorId:    timetable.operator.id,
      fromStationId: fare.from,
      toStationId:   fare.to,
      price:         fare.price2ndClass,
      currency:      timetable.pricing.currency,
      classType:     '2nd',
      createdAt:     ts(2025, 1, 1),
    });
    b().set(db.collection('tariffs').doc(tariffIdRev), {
      operatorId:    timetable.operator.id,
      fromStationId: fare.to,
      toStationId:   fare.from,
      price:         fare.price2ndClass,
      currency:      timetable.pricing.currency,
      classType:     '2nd',
      createdAt:     ts(2025, 1, 1),
    });
    tariffCount += 2;
  }
  console.log(`   ✓ ${tariffCount} tariff(s).\n`);

  // ── 6. Commit all batches ─────────────────────────────────────────────────
  console.log(`📤 Committing ${batches.length} batch(es)…`);
  for (let i = 0; i < batches.length; i++) {
    await batches[i].commit();
    process.stdout.write(`   batch ${i + 1}/${batches.length} done\r`);
  }
  console.log('\n\n✅ SNCFT Grandes Lignes seeded successfully.');
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Seed failed:', err);
  process.exit(1);
});
