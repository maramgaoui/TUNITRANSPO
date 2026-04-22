const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccount = require('./firebase-key.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const dataPath = path.join(__dirname, 'data', 'banlieue_sud_line_a_timetable.json');
const timetable = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
const SHARED_TUNIS_VILLE_ID = 'bs_tunis_ville';
const SHARED_TUNIS_VILLE_OPERATORS = [
  'sncft',
  'sncft_banlieue_sud',
  'sncft_banlieue_d',
  'sncft_banlieue_e',
];

function ts(y, m, d, h = 0, mn = 0) {
  return admin.firestore.Timestamp.fromDate(new Date(y, m - 1, d, h, mn, 0));
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

function parseDateISO(dateStr, fallback) {
  if (typeof dateStr !== 'string' || !dateStr.trim()) return fallback;
  const dt = new Date(dateStr);
  return Number.isNaN(dt.getTime()) ? fallback : dt;
}

function calculateFare(fromSection, toSection, rules) {
  const sectionsTraversed = Math.abs(toSection - fromSection) + 1;
  for (const rule of rules) {
    if (sectionsTraversed <= rule.maxSections) {
      return rule.price;
    }
  }
  return rules[rules.length - 1].price;
}

function getTripDays(route, trip) {
  if (Array.isArray(trip.operatingDays) && trip.operatingDays.length > 0) {
    return trip.operatingDays;
  }
  if (Array.isArray(route.operatingDays) && route.operatingDays.length > 0) {
    return route.operatingDays;
  }
  return [0, 1, 2, 3, 4, 5, 6];
}

function getTripDocId(routeId, tripNumber) {
  return `${routeId.replace('route_', 'trip_')}_${tripNumber}`;
}

async function deleteTripsForRoute(routeId) {
  const snap = await db.collection('trips').where('routeId', '==', routeId).get();
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

async function deleteRouteStopsForRoute(routeId) {
  const snap = await db.collection('route_stops').where('routeId', '==', routeId).get();
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

// ============================================================================
// MAIN
// ============================================================================
async function seed() {
  try {
    console.log('🚂 Seeding Banlieue Sud (Tunis ↔ Erriadh)...\n');

    const stations = [...timetable.stations].sort((a, b) => a.order - b.order);
    const routes = [...timetable.routes];
    const routeStopsSouth = timetable.routeStops
      .filter((stop) => stop.direction === 'south')
      .sort((a, b) => a.stopOrder - b.stopOrder);
    const lastForwardOffset = routeStopsSouth[routeStopsSouth.length - 1].estimatedArrivalTimeMinutes;
    const routeStopsNorth = routeStopsSouth
      .slice()
      .reverse()
      .map((stop, index) => ({
        stationId: stop.stationId,
        stopOrder: index + 1,
        estimatedArrivalTimeMinutes: lastForwardOffset - stop.estimatedArrivalTimeMinutes,
      }));

    const routeStopsByDirection = {
      south: routeStopsSouth,
      north: routeStopsNorth,
    };

    const validFromDate = parseDateISO(timetable.metadata?.validFrom, new Date(2025, 8, 1));
    const validToDate = parseDateISO(timetable.metadata?.validTo, new Date(2026, 5, 30));
    const validFrom = admin.firestore.Timestamp.fromDate(validFromDate);
    const validTo = admin.firestore.Timestamp.fromDate(validToDate);
    const baseDate = validFromDate;
    const totalJourneyMinutes = timetable.metadata?.journeyDurationMinutes || lastForwardOffset;
    const fareRules = timetable.pricing?.sectionFareRules || [];

    const batches = [db.batch()];
    let ops = 0;
    function b() {
      if (ops >= 490) { batches.push(db.batch()); ops = 0; }
      ops++;
      return batches[batches.length - 1];
    }

    // ── 1. Operator ──
    console.log('🏢 Creating operator...');
    b().set(db.collection('operators').doc(timetable.operator.id), {
      name: timetable.operator.name,
      typeId: timetable.operator.typeId,
      phone: timetable.operator.phone,
      website: timetable.operator.website,
      color: timetable.operator.color,
      createdAt: ts(2025, 1, 1),
    });
    console.log(`   ✓ ${timetable.operator.id}\n`);

    // ── 2. Stations ──
    console.log(`🚉 Creating ${stations.length} stations...`);
    for (const s of stations) {
      b().set(db.collection('stations').doc(s.id), {
        name: s.name,
        cityId: s.cityId,
        latitude: s.lat,
        longitude: s.lng,
        address: null,
        transportTypes: ['train'],
        operatorsHere: s.id == SHARED_TUNIS_VILLE_ID
          ? SHARED_TUNIS_VILLE_OPERATORS
          : [timetable.operator.id],
        services: { wifi: false, toilet: true, cafe: false, parking: false },
        isMainHub: s.isMainHub,
        section: s.section,
        createdAt: ts(2025, 1, 1),
      });
    }
    console.log(`   ✓ ${stations.length} stations.\n`);

    // ── 3. Routes ──
    console.log('🛤️  Creating routes...');
    for (const route of routes) {
      const stopIds = route.direction === 'south'
        ? stations.map((station) => station.id)
        : [...stations].reverse().map((station) => station.id);

      b().set(db.collection('routes').doc(route.id), {
        operatorId: timetable.operator.id,
        typeId: timetable.operator.typeId,
        lineNumber: route.lineNumber,
        name: route.name,
        description: route.description,
        originStationId: route.originStationId,
        destinationStationId: route.destinationStationId,
        isCircular: false,
        isActive: true,
        stopIds,
        createdAt: ts(2025, 1, 1),
      });
    }
    console.log(`   ✓ ${routes.length} routes.\n`);

    // ── 4. Route stops ──
    console.log('🚏 Creating route stops...');
    let removedRouteStops = 0;
    for (const route of routes) {
      removedRouteStops += await deleteRouteStopsForRoute(route.id);
    }
    if (removedRouteStops > 0) {
      console.log(`   ✓ removed ${removedRouteStops} old route stop docs.`);
    }
    for (const route of routes) {
      const routeStops = routeStopsByDirection[route.direction] || [];
      for (const stop of routeStops) {
        b().set(db.collection('route_stops').doc(`rs_${route.id}_${stop.stopOrder}`), {
          routeId: route.id,
          stationId: stop.stationId,
          stopOrder: stop.stopOrder,
          estimatedArrivalTimeMinutes: stop.estimatedArrivalTimeMinutes,
          arrivalNote: null,
          createdAt: ts(2025, 1, 1),
        });
      }
    }
    console.log(`   ✓ ${stations.length * 2} route stops.\n`);

    // ── 5. Tariffs (section-based, all pairs) ──
    console.log('💰 Creating tariffs...');
    let tc = 0;
    for (let i = 0; i < stations.length; i++) {
      for (let j = i + 1; j < stations.length; j++) {
        const a = stations[i], bSt = stations[j];
        const p = calculateFare(a.section, bSt.section, fareRules);
        // a → b
        b().set(db.collection('tariffs').doc(`tariff_${a.id}_${bSt.id}`), {
          operatorId: timetable.operator.id,
          fromStationId: a.id, toStationId: bSt.id,
          price: p, currency: timetable.pricing.currency, tariffClass: null,
          validFrom, validTo, notes: null, specialDiscounts: [],
          createdAt: ts(2025, 1, 1),
        });
        tc++;
        // b → a (symmetric)
        b().set(db.collection('tariffs').doc(`tariff_${bSt.id}_${a.id}`), {
          operatorId: timetable.operator.id,
          fromStationId: bSt.id, toStationId: a.id,
          price: p, currency: timetable.pricing.currency, tariffClass: null,
          validFrom, validTo, notes: null, specialDiscounts: [],
          createdAt: ts(2025, 1, 1),
        });
        tc++;
      }
    }
    console.log(`   ✓ ${tc} tariffs.\n`);

    // ── 6. Trips ──
    console.log('🧹 Removing existing Banlieue Sud trips...');
    let removedTrips = 0;
    for (const route of routes) {
      removedTrips += await deleteTripsForRoute(route.id);
    }
    console.log(`   ✓ removed ${removedTrips} old trip docs.\n`);

    console.log('🚆 Creating trips...');
    let tripCount = 0;
    for (const route of routes) {
      for (const trip of route.trips) {
        const depMin = timeToMin(trip.departureTime);
        const arrMin = depMin + totalJourneyMinutes;
        b().set(db.collection('trips').doc(getTripDocId(route.id, trip.tripNumber)), {
          routeId: route.id,
          tripNumber: trip.tripNumber,
          departureTime: minToTs(depMin, baseDate),
          arrivalTime: minToTs(arrMin, baseDate),
          capacity: 400,
          availableSeats: 400,
          daysOfWeek: getTripDays(route, trip),
          validFrom,
          validTo,
          isActive: true,
          vehicleId: null,
          driverName: null,
          createdAt: ts(2025, 1, 1),
        });
        tripCount++;
      }
    }
    const southTripCount = routes.find((route) => route.direction === 'south')?.trips.length || 0;
    const northTripCount = routes.find((route) => route.direction === 'north')?.trips.length || 0;
    console.log(`   ✓ ${tripCount} trips (${southTripCount} south + ${northTripCount} north).\n`);

    // ── COMMIT ──
    console.log(`⏳ Committing ${batches.length} batch(es)...`);
    for (let i = 0; i < batches.length; i++) {
      await batches[i].commit();
      console.log(`   ✓ Batch ${i + 1}/${batches.length}`);
    }

    console.log(`\n✅ BANLIEUE SUD SEED COMPLETE!`);
    console.log(`📊 Summary:`);
    console.log(`   - 1 Operator (${timetable.operator.id})`);
    console.log(`   - ${stations.length} Stations (8 sections)`);
    console.log(`   - ${routes.length} Routes`);
    console.log(`   - ${stations.length * 2} Route stops`);
    console.log(`   - ${tripCount} Trips`);
    console.log(`   - ${tc} Tariffs (section-based pricing)`);
    console.log(`   - Journey time: ${totalJourneyMinutes} min`);

    process.exit(0);
  } catch (e) {
    console.error('❌', e);
    process.exit(1);
  }
}

seed();
