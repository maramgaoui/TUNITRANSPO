const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccount = require('./firebase-key.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const dataPath = path.join(__dirname, 'data', 'line_d_timetable.json');
const timetable = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
const SHARED_TUNIS_VILLE_ID = 'bs_tunis_ville';
const OLD_TUNIS_VILLE_ID = 'rd_tunis_ville';
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

async function deleteDocsByRouteId(collectionName, routeId) {
  const snap = await db.collection(collectionName).where('routeId', '==', routeId).get();
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

async function deleteTariffsForStationId(stationId) {
  const snap = await db.collection('tariffs').get();
  const docs = snap.docs.filter((doc) => {
    const data = doc.data();
    return data.fromStationId === stationId || data.toStationId === stationId;
  });
  if (docs.length === 0) return 0;

  let removed = 0;
  let batch = db.batch();
  let ops = 0;
  for (const doc of docs) {
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

async function deleteDocumentIfExists(collectionName, documentId) {
  const ref = db.collection(collectionName).doc(documentId);
  const snap = await ref.get();
  if (!snap.exists) return false;
  await ref.delete();
  return true;
}

async function seedLineD() {
  try {
    console.log('Starting Line D seeding...');

    const stations = [...timetable.stations].sort((a, b) => a.order - b.order);
    const stationIdsForward = stations.map((s) => s.id);
    const stationIdsReverse = [...stationIdsForward].reverse();
    const routeStopsForward = [...timetable.routeStops].sort((a, b) => a.stopOrder - b.stopOrder);

    const routeStopsByDirection = {
      forward: routeStopsForward,
      reverse: routeStopsForward
        .slice()
        .reverse()
        .map((s, i) => ({
          stationId: s.stationId,
          stopOrder: i + 1,
          estimatedArrivalTimeMinutes: (routeStopsForward[routeStopsForward.length - 1].estimatedArrivalTimeMinutes || 0) - (s.estimatedArrivalTimeMinutes || 0),
        })),
    };

    const batches = [db.batch()];
    let opCount = 0;

    function batch() {
      if (opCount >= 490) {
        batches.push(db.batch());
        opCount = 0;
      }
      opCount += 1;
      return batches[batches.length - 1];
    }

    const validFrom = ts(2025, 9, 1);
    const validTo = ts(2026, 6, 30);
    const baseDate = new Date(2025, 8, 1);

    let removedRouteStops = 0;
    let removedTrips = 0;
    for (const route of timetable.routes) {
      removedRouteStops += await deleteDocsByRouteId('route_stops', route.id);
      removedTrips += await deleteDocsByRouteId('trips', route.id);
    }
    const removedLegacyTariffs = await deleteTariffsForStationId(OLD_TUNIS_VILLE_ID);
    const removedLegacyStation = await deleteDocumentIfExists('stations', OLD_TUNIS_VILLE_ID);

    // 1) Operator
    batch().set(db.collection('operators').doc(timetable.operator.id), {
      name: timetable.operator.name,
      typeId: timetable.operator.typeId,
      phone: timetable.operator.phone,
      website: 'https://www.sncft.com.tn',
      color: '#455A64',
      createdAt: ts(2025, 1, 1),
    }, { merge: true });

    // 2) Stations
    const hubs = new Set(['rd_tunis_ville', 'rd_gobaa_ville']);
    for (const s of stations) {
      batch().set(db.collection('stations').doc(s.id), {
        name: s.name,
        cityId: s.city.toLowerCase(),
        latitude: s.id === SHARED_TUNIS_VILLE_ID ? 36.7992 : 36.8,
        longitude: s.id === SHARED_TUNIS_VILLE_ID ? 10.1802 : 10.18,
        address: null,
        transportTypes: ['train'],
        operatorsHere: s.id === SHARED_TUNIS_VILLE_ID
          ? SHARED_TUNIS_VILLE_OPERATORS
          : ['sncft', 'sncft_banlieue_d'],
        services: {
          wifi: false,
          toilet: true,
          cafe: false,
          parking: false,
        },
        isMainHub: hubs.has(s.id),
        createdAt: ts(2025, 1, 1),
      }, { merge: true });
    }

    // 3) Routes
    for (const route of timetable.routes) {
      const stopIds = route.direction === 'forward' ? stationIdsForward : stationIdsReverse;
      batch().set(db.collection('routes').doc(route.id), {
        operatorId: timetable.operator.id,
        typeId: timetable.operator.typeId,
        lineNumber: route.lineNumber,
        name: route.name,
        description: `Ligne ${route.lineNumber}: ${route.name}`,
        originStationId: route.originStationId,
        destinationStationId: route.destinationStationId,
        isCircular: false,
        isActive: true,
        stopIds,
        createdAt: ts(2025, 1, 1),
      }, { merge: true });
    }

    // 4) Route stops
    for (const route of timetable.routes) {
      const routeStops = routeStopsByDirection[route.direction] || [];
      for (const rs of routeStops) {
        const routeStopDocId = `rs_${route.id}_${rs.stopOrder}`;
        batch().set(db.collection('route_stops').doc(routeStopDocId), {
          routeId: route.id,
          stationId: rs.stationId,
          stopOrder: rs.stopOrder,
          estimatedArrivalTimeMinutes: rs.estimatedArrivalTimeMinutes,
          arrivalNote: null,
          createdAt: ts(2025, 1, 1),
        }, { merge: true });
      }
    }

    // 5) Trips
    for (const route of timetable.routes) {
      const routeStops = routeStopsByDirection[route.direction] || [];
      const duration = Math.max(...routeStops.map((s) => s.estimatedArrivalTimeMinutes || 0));
      const operatingDays = Array.isArray(route.operatingDays) && route.operatingDays.length > 0
        ? route.operatingDays
        : [0, 1, 2, 3, 4, 5, 6];

      for (const trip of route.trips) {
        const tripNumber = Number.parseInt(String(trip.tripNumber), 10);
        const depMin = timeToMin(trip.departureTime);
        const arrMin = depMin + duration;
        const tripDocId = `trip_${route.id}_${tripNumber}`;

        batch().set(db.collection('trips').doc(tripDocId), {
          routeId: route.id,
          tripNumber,
          departureTime: minToTs(depMin, baseDate),
          arrivalTime: minToTs(arrMin, baseDate),
          capacity: 300,
          availableSeats: 300,
          daysOfWeek: operatingDays,
          validFrom,
          validTo,
          isActive: true,
          vehicleId: null,
          driverName: null,
          createdAt: ts(2025, 1, 1),
        }, { merge: true });
      }
    }

    // 6) Tariffs (unified flat fare)
    const fare = typeof timetable.pricing?.fare_standard_tnd === 'number'
      ? timetable.pricing.fare_standard_tnd
      : 0.7;
    for (let i = 0; i < stations.length; i += 1) {
      for (let j = i + 1; j < stations.length; j += 1) {
        const from = stations[i];
        const to = stations[j];

        batch().set(db.collection('tariffs').doc(`tariff_${from.id}_${to.id}`), {
          operatorId: timetable.operator.id,
          fromStationId: from.id,
          toStationId: to.id,
          price: fare,
          currency: timetable.pricing?.currency || 'TND',
          tariffClass: null,
          validFrom,
          validTo,
          notes: timetable.pricing?.note || 'Line D unified flat fare',
          specialDiscounts: [],
          createdAt: ts(2025, 1, 1),
        }, { merge: true });

        batch().set(db.collection('tariffs').doc(`tariff_${to.id}_${from.id}`), {
          operatorId: timetable.operator.id,
          fromStationId: to.id,
          toStationId: from.id,
          price: fare,
          currency: timetable.pricing?.currency || 'TND',
          tariffClass: null,
          validFrom,
          validTo,
          notes: timetable.pricing?.note || 'Line D unified flat fare',
          specialDiscounts: [],
          createdAt: ts(2025, 1, 1),
        }, { merge: true });
      }
    }

    for (let i = 0; i < batches.length; i += 1) {
      await batches[i].commit();
      console.log(`Committed batch ${i + 1}/${batches.length}`);
    }

    if (removedRouteStops > 0 || removedTrips > 0 || removedLegacyTariffs > 0 || removedLegacyStation) {
      console.log(
        `Cleanup: ${removedRouteStops} route_stops, ${removedTrips} trips, ${removedLegacyTariffs} tariffs, station removed=${removedLegacyStation}`,
      );
    }

    const forwardTrips = timetable.routes.find((r) => r.id === 'route_rd_line_d_forward')?.trips.length || 0;
    const reverseTrips = timetable.routes.find((r) => r.id === 'route_rd_line_d_reverse')?.trips.length || 0;

    console.log('Line D seed complete.');
    console.log(`Stations: ${stations.length}`);
    console.log(`Routes: ${timetable.routes.length}`);
    console.log(`Trips: ${forwardTrips + reverseTrips} (${forwardTrips} forward + ${reverseTrips} reverse)`);

    process.exit(0);
  } catch (error) {
    console.error('Line D seed failed:', error);
    process.exit(1);
  }
}

seedLineD();
