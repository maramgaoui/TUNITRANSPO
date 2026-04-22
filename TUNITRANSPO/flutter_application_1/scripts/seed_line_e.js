const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccount = require('./firebase-key.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const dataPath = path.join(__dirname, 'data', 'line_e_timetable.json');
const timetable = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
const SHARED_TUNIS_VILLE_ID = 'bs_tunis_ville';
const OLD_TUNIS_ID = 'be_tunis';
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

function getTripDays(trip, scheduleLogic) {
  if (Array.isArray(trip.days) && trip.days.length > 0) {
    return trip.days;
  }
  const marker = (trip.dayMarker || trip.marker || '-').toString();
  if (Array.isArray(scheduleLogic?.[marker])) {
    return scheduleLogic[marker];
  }
  return [0, 1, 2, 3, 4, 5, 6];
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

async function seedLineE() {
  try {
    console.log('Starting Line E seeding...');

    const stations = [...timetable.stations].sort((a, b) => a.order - b.order);
    const stationIdsForward = stations.map((s) => s.id);
    const stationIdsReverse = [...stationIdsForward].reverse();

    const routesById = new Map(timetable.routes.map((r) => [r.id, r]));
    const routeStopsByDirection = {
      forward: timetable.routeStops
        .filter((s) => s.direction === 'forward')
        .sort((a, b) => a.stopOrder - b.stopOrder),
      reverse: timetable.routeStops
        .filter((s) => s.direction === 'reverse')
        .sort((a, b) => a.stopOrder - b.stopOrder),
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

    const pricing = timetable.pricing || {};
    const scheduleLogic = timetable.schedule_logic || {
      A: [1, 2, 3, 4, 5, 6],
      B: [0],
      '-': [0, 1, 2, 3, 4, 5, 6],
    };
    const validFromDate = parseDateISO(timetable.metadata?.valid_from, new Date(2025, 8, 1));
    const validToDate = parseDateISO(timetable.metadata?.valid_to, new Date(2026, 5, 30));
    const validFrom = admin.firestore.Timestamp.fromDate(validFromDate);
    const validTo = admin.firestore.Timestamp.fromDate(validToDate);
    const baseDate = validFromDate;

    let removedRouteStops = 0;
    let removedTrips = 0;
    for (const route of timetable.routes) {
      removedRouteStops += await deleteDocsByRouteId('route_stops', route.id);
      removedTrips += await deleteDocsByRouteId('trips', route.id);
    }
    const removedLegacyTariffs = await deleteTariffsForStationId(OLD_TUNIS_ID);
    const removedLegacyStation = await deleteDocumentIfExists('stations', OLD_TUNIS_ID);

    // 1) Operator
    batch().set(db.collection('operators').doc(timetable.operator.id), {
      name: timetable.operator.name,
      typeId: timetable.operator.typeId,
      phone: timetable.operator.phone,
      website: 'https://www.sncft.com.tn',
      color: '#00695C',
      createdAt: ts(2025, 1, 1),
    }, { merge: true });

    // 2) Stations
    const hubs = new Set(['be_tunis', 'be_bougatfa']);
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
          : s.id === 'rd_saida_manoubia'
            ? ['sncft', 'sncft_banlieue_d', 'sncft_banlieue_e']
            : ['sncft', 'sncft_banlieue_e'],
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
      const stopIds = route.direction === 'forward'
        ? stationIdsForward
        : stationIdsReverse;

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
      const duration = Math.max(
        ...routeStopsByDirection[route.direction].map((s) => s.estimatedArrivalTimeMinutes),
      );

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
          daysOfWeek: getTripDays(trip, scheduleLogic),
          validFrom,
          validTo,
          isActive: true,
          vehicleId: null,
          driverName: null,
          createdAt: ts(2025, 1, 1),
        }, { merge: true });
      }
    }

    // 6) Tariffs (unified flat fare for all station pairs)
    const adultFare = typeof pricing.base_fare === 'number' ? pricing.base_fare : 0.7;
    const childFare = typeof pricing.children_4_9_fare === 'number' ? pricing.children_4_9_fare : 0.525;
    for (let i = 0; i < stations.length; i += 1) {
      for (let j = i + 1; j < stations.length; j += 1) {
        const from = stations[i];
        const to = stations[j];
        const price = adultFare;

        batch().set(db.collection('tariffs').doc(`tariff_${from.id}_${to.id}`), {
          operatorId: timetable.operator.id,
          fromStationId: from.id,
          toStationId: to.id,
          price,
          currency: 'TND',
          tariffClass: null,
          validFrom,
          validTo,
          notes: 'Line E unified flat fare',
          specialDiscounts: [
            { code: 'CHILD_4_9', price: childFare, description: 'Children 4-9 years' },
            { code: 'CHILD_0_3', price: 0.0, description: 'Children 0-3 years' },
          ],
          createdAt: ts(2025, 1, 1),
        }, { merge: true });

        batch().set(db.collection('tariffs').doc(`tariff_${to.id}_${from.id}`), {
          operatorId: timetable.operator.id,
          fromStationId: to.id,
          toStationId: from.id,
          price,
          currency: 'TND',
          tariffClass: null,
          validFrom,
          validTo,
          notes: 'Line E unified flat fare',
          specialDiscounts: [
            { code: 'CHILD_4_9', price: childFare, description: 'Children 4-9 years' },
            { code: 'CHILD_0_3', price: 0.0, description: 'Children 0-3 years' },
          ],
          createdAt: ts(2025, 1, 1),
        }, { merge: true });
      }
    }

    // Commit
    for (let i = 0; i < batches.length; i += 1) {
      await batches[i].commit();
      console.log(`Committed batch ${i + 1}/${batches.length}`);
    }

    if (removedRouteStops > 0 || removedTrips > 0 || removedLegacyTariffs > 0 || removedLegacyStation) {
      console.log(
        `Cleanup: ${removedRouteStops} route_stops, ${removedTrips} trips, ${removedLegacyTariffs} tariffs, station removed=${removedLegacyStation}`,
      );
    }

    const forwardTrips = routesById.get('route_line_e_forward')?.trips.length ?? 0;
    const reverseTrips = routesById.get('route_line_e_reverse')?.trips.length ?? 0;

    console.log('Line E seed complete.');
    console.log(`Stations: ${stations.length}`);
    console.log(`Routes: ${timetable.routes.length}`);
    console.log(`Trips: ${forwardTrips + reverseTrips} (${forwardTrips} forward + ${reverseTrips} reverse)`);
    process.exit(0);
  } catch (error) {
    console.error('Line E seed failed:', error);
    process.exit(1);
  }
}

seedLineE();
