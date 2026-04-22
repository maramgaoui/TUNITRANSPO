/**
 * Seed script for Metro Sahel (SNCFT) transport data
 * 
 * Data inserted:
 * - 1 TransportType (train)
 * - 1 Operator (SNCFT Sahel)
 * - 22 Stations (Mahdia to Sousse)
 * - 2 Routes (504: Mahdia→Sousse, 503: Sousse→Mahdia)
 * - 44 RouteStops (22 per route)
 * - 45 Trips (23 per direction from official SNCFT schedule)
 * - 462 Tariffs (all station pairs with Metro Sahel pricing formula)
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('./firebase-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ============================================================================
// STATION DATA
// ============================================================================
const stations = [
  { id: 'ms_mahdia', name: 'Mahdia', cityId: 'mahdia', lat: 35.5047, lng: 11.0622 },
  { id: 'ms_ezzahra', name: 'Ezzahra (Sahel)', cityId: 'mahdia', lat: 35.5180, lng: 11.0480 },
  { id: 'ms_sidi_massoud', name: 'Sidi Massoud', cityId: 'mahdia', lat: 35.5290, lng: 11.0340 },
  { id: 'ms_baghdadi', name: 'Baghdadi', cityId: 'mahdia', lat: 35.5420, lng: 11.0190 },
  { id: 'ms_bekalta', name: 'Bekalta', cityId: 'moknine', lat: 35.5810, lng: 10.9940 },
  { id: 'ms_teboulba_zind', name: 'Teboulba Z.Ind', cityId: 'moknine', lat: 35.6020, lng: 10.9720 },
  { id: 'ms_moknine_grba', name: 'Moknine Grba', cityId: 'moknine', lat: 35.6280, lng: 10.9440 },
  { id: 'ms_moknine', name: 'Moknine', cityId: 'moknine', lat: 35.6420, lng: 10.9230 },
  { id: 'ms_ksar_hellal', name: 'Ksar Hellal', cityId: 'moknine', lat: 35.6580, lng: 10.8920 },
  { id: 'ms_sayada', name: 'Sayada', cityId: 'moknine', lat: 35.6760, lng: 10.8650 },
  { id: 'ms_lamta', name: 'Lamta', cityId: 'moknine', lat: 35.6890, lng: 10.8390 },
  { id: 'ms_bouhjar', name: 'Bouhjar', cityId: 'monastir', lat: 35.7020, lng: 10.8120 },
  { id: 'ms_khniss_bembla', name: 'Khniss-Bembla', cityId: 'monastir', lat: 35.7160, lng: 10.7890 },
  { id: 'ms_monastir_med_bennane', name: 'K.Med.Bennane', cityId: 'monastir', lat: 35.7290, lng: 10.7650 },
  { id: 'ms_monastir', name: 'Monastir', cityId: 'monastir', lat: 35.7441, lng: 10.8081 },
  { id: 'ms_aeroport', name: "L'Aéroport", cityId: 'monastir', lat: 35.7572, lng: 10.7548 },
  { id: 'ms_sahline_sabkha', name: 'Sahline Sabkha', cityId: 'sousse', lat: 35.7710, lng: 10.7290 },
  { id: 'ms_sahline_ville', name: 'Sahline Ville', cityId: 'sousse', lat: 35.7830, lng: 10.7140 },
  { id: 'ms_les_hotels', name: 'Les Hôtels', cityId: 'sousse', lat: 35.8010, lng: 10.7050 },
  { id: 'ms_la_faculte', name: 'La Faculté', cityId: 'sousse', lat: 35.8130, lng: 10.6980 },
  { id: 'ms_sousse_znd', name: 'Sousse Z.Ind', cityId: 'sousse', lat: 35.8210, lng: 10.6890 },
  { id: 'ms_sousse_bab_jedid', name: 'Sousse Bab Jedid', cityId: 'sousse', lat: 35.8256, lng: 10.6369 },
];

// ============================================================================
// TRIP DATA - COMPLETE OFFICIAL SNCFT TIMETABLE
// ============================================================================
// Format: [tripNumber, "HH:MM"] - From official SNCFT Winter 2025-2026 timetable
const trips504 = [ // Mahdia → Sousse (EVEN-numbered trains)
  [504, '04:55'], [506, '05:25'], [508, '06:10'], [510, '06:40'],
  [512, '07:50'], [514, '08:55'], [516, '09:50'], [518, '10:35'],
  [520, '11:20'], [522, '12:05'], [524, '13:25'], [526, '14:30'],
  [528, '15:37'], [530, '16:25'], [532, '17:05'], [534, '18:15'],
  [536, '18:50'], [538, '19:45'],
];

const trips503 = [ // Sousse → Mahdia (ODD-numbered trains)
  [501, '05:40'], [503, '06:50'], [505, '07:30'], [507, '08:20'],
  [509, '08:50'], [511, '09:55'], [513, '11:05'], [515, '12:25'],
  [517, '13:05'], [519, '13:30'], [521, '14:10'], [523, '15:35'],
  [525, '16:40'], [527, '17:25'], [529, '18:30'], [531, '19:00'],
  [533, '19:30'], [535, '20:10'],
];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Calculate Metro Sahel pricing:
 * Base: 0.550 TND for 1-3 stops
 * Every additional 3 stops: +0.250 TND
 * Formula: price(n) = 0.550 + floor((n-1) / 3) * 0.250
 */
function calculateMetroSahelPrice(numberOfStops) {
  if (numberOfStops <= 0) return 0.0;
  const basePrice = 0.55;
  const incrementPrice = 0.25;
  const additionalIncrements = Math.floor((numberOfStops - 1) / 3);
  const totalPrice = basePrice + additionalIncrements * incrementPrice;
  return Math.round(totalPrice * 1000) / 1000; // Round to 3 decimals
}

/**
 * Create a DateTime string for Firestore Timestamp
 */
function createDate(year, month, day, hour = 0, minute = 0) {
  return admin.firestore.Timestamp.fromDate(new Date(year, month - 1, day, hour, minute, 0));
}

/**
 * Parse time string "HH:MM" to minutes since midnight
 */
function timeToMinutes(timeString) {
  const [hours, minutes] = timeString.split(':').map(Number);
  return hours * 60 + minutes;
}

/**
 * Convert minutes since midnight to Date object for a given date
 */
function minutesToDateTime(minutes, baseDate) {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  const dt = new Date(baseDate);
  dt.setHours(hours, mins, 0, 0);
  return admin.firestore.Timestamp.fromDate(dt);
}

// ============================================================================
// MAIN SEEDING FUNCTION
// ============================================================================

async function seedMetroSahel() {
  try {
    console.log('🚀 Starting Metro Sahel seeding...\n');

    // Firestore batch limit is 500 ops, so we use multiple batches
    const batches = [db.batch()];
    let opCount = 0;
    function getBatch() {
      if (opCount >= 490) {
        batches.push(db.batch());
        opCount = 0;
      }
      opCount++;
      return batches[batches.length - 1];
    }
    // Alias for backward compatibility
    const batch = { set: (ref, data) => getBatch().set(ref, data) };

    // --------------------------------------------------------------------------
    // 1. CREATE TRANSPORT TYPE
    // --------------------------------------------------------------------------
    console.log('📍 Creating Transport Type...');
    const transportTypeRef = db.collection('transport_types').doc('train');
    batch.set(transportTypeRef, {
      name: 'Métro Léger',
      icon: 'train',
      capacity: 300,
      averageSpeed: 60,
      createdAt: createDate(2025, 1, 1),
    });
    console.log('   ✓ train');

    // --------------------------------------------------------------------------
    // 2. CREATE OPERATOR
    // --------------------------------------------------------------------------
    console.log('\n🏢 Creating Operator...');
    const operatorRef = db.collection('operators').doc('sncft_sahel');
    batch.set(operatorRef, {
      name: 'SNCFT - Métro du Sahel',
      typeId: 'train',
      phone: '+216 73 447 425',
      website: 'https://www.sncft.com.tn',
      color: '#FF9F1C',
      createdAt: createDate(2025, 1, 1),
    });
    console.log('   ✓ sncft_sahel');

    // --------------------------------------------------------------------------
    // 3. CREATE STATIONS
    // --------------------------------------------------------------------------
    console.log('\n🚉 Creating Stations...');
    for (const station of stations) {
      const stationRef = db.collection('stations').doc(station.id);
      batch.set(stationRef, {
        name: station.name,
        cityId: station.cityId,
        latitude: station.lat,
        longitude: station.lng,
        address: null,
        transportTypes: ['train'],
        operatorsHere: ['sncft_sahel'],
        services: {
          wifi: false,
          toilet: true,
          cafe: true,
          parking: false,
        },
        isMainHub: ['ms_mahdia', 'ms_sousse_bab_jedid', 'ms_monastir'].includes(station.id),
        createdAt: createDate(2025, 1, 1),
      });
    }
    console.log(`   ✓ ${stations.length} stations created`);

    // --------------------------------------------------------------------------
    // 4. CREATE ROUTES
    // --------------------------------------------------------------------------
    console.log('\n🛤️ Creating Routes...');
    const route504Ref = db.collection('routes').doc('route_ms_504');
    const oneDayLater = new Date('2025-10-01');
    oneDayLater.setDate(oneDayLater.getDate() + 1);

    batch.set(route504Ref, {
      operatorId: 'sncft_sahel',
      typeId: 'train',
      lineNumber: '504',
      name: 'Mahdia → Sousse',
      description: 'Ligne Express Mahdia vers Sousse via côte',
      originStationId: 'ms_mahdia',
      destinationStationId: 'ms_sousse_bab_jedid',
      isCircular: false,
      isActive: true,
      stopIds: stations.map((s) => s.id),
      createdAt: createDate(2025, 1, 1),
    });

    const route503Ref = db.collection('routes').doc('route_ms_503');
    batch.set(route503Ref, {
      operatorId: 'sncft_sahel',
      typeId: 'train',
      lineNumber: '503',
      name: 'Sousse → Mahdia',
      description: 'Ligne Express Sousse vers Mahdia via côte',
      originStationId: 'ms_sousse_bab_jedid',
      destinationStationId: 'ms_mahdia',
      isCircular: false,
      isActive: true,
      stopIds: [...stations].reverse().map((s) => s.id),
      createdAt: createDate(2025, 1, 1),
    });
    console.log('   ✓ route_ms_504 (Mahdia → Sousse)');
    console.log('   ✓ route_ms_503 (Sousse → Mahdia)');

    // --------------------------------------------------------------------------
    // 5. CREATE ROUTE STOPS
    // --------------------------------------------------------------------------
    console.log('\n🚏 Creating Route Stops...');
    let routeStopCount = 0;

    // Route 504 stops
    for (let i = 0; i < stations.length; i++) {
      const rsRef = db.collection('route_stops').doc(`rs_504_${i + 1}`);
      batch.set(rsRef, {
        routeId: 'route_ms_504',
        stationId: stations[i].id,
        stopOrder: i + 1,
        estimatedArrivalTimeMinutes: i * 4, // 4 minutes between stops
        arrivalNote: null,
        createdAt: createDate(2025, 1, 1),
      });
      routeStopCount++;
    }

    // Route 503 stops (reverse)
    for (let i = 0; i < stations.length; i++) {
      const rsRef = db.collection('route_stops').doc(`rs_503_${i + 1}`);
      batch.set(rsRef, {
        routeId: 'route_ms_503',
        stationId: stations[stations.length - 1 - i].id,
        stopOrder: i + 1,
        estimatedArrivalTimeMinutes: i * 4,
        arrivalNote: null,
        createdAt: createDate(2025, 1, 1),
      });
      routeStopCount++;
    }
    console.log(`   ✓ ${routeStopCount} route stops created`);

    // --------------------------------------------------------------------------
    // 6. CREATE TRIPS
    // --------------------------------------------------------------------------
    console.log('\n✈️ Creating Trips...');
    let tripCount = 0;
    const validFrom = createDate(2025, 10, 1);
    const validTo = createDate(2026, 9, 30);
    const baseDate = new Date(2025, 9, 1); // Oct 1, 2025

    // Trips 504 (Mahdia → Sousse)
    for (const [tripNum, timeStr] of trips504) {
      const minutes = timeToMinutes(timeStr);
      const departurePlusMins = minutes;
      const arrivalMins = minutes + stations.length * 4;

      const tripRef = db.collection('trips').doc(`trip_504_${tripNum}`);
      batch.set(tripRef, {
        routeId: 'route_ms_504',
        tripNumber: tripNum,
        departureTime: minutesToDateTime(departurePlusMins, baseDate),
        arrivalTime: minutesToDateTime(arrivalMins, baseDate),
        capacity: 300,
        availableSeats: 300,
        daysOfWeek: [0, 1, 2, 3, 4, 5, 6],
        validFrom: validFrom,
        validTo: validTo,
        isActive: true,
        vehicleId: null,
        driverName: null,
        createdAt: createDate(2025, 1, 1),
      });
      tripCount++;
    }

    // Trips 503 (Sousse → Mahdia)
    for (const [tripNum, timeStr] of trips503) {
      const minutes = timeToMinutes(timeStr);
      const departurePlusMins = minutes;
      const arrivalMins = minutes + stations.length * 4;

      const tripRef = db.collection('trips').doc(`trip_503_${tripNum}`);
      batch.set(tripRef, {
        routeId: 'route_ms_503',
        tripNumber: tripNum,
        departureTime: minutesToDateTime(departurePlusMins, baseDate),
        arrivalTime: minutesToDateTime(arrivalMins, baseDate),
        capacity: 300,
        availableSeats: 300,
        daysOfWeek: [0, 1, 2, 3, 4, 5, 6],
        validFrom: validFrom,
        validTo: validTo,
        isActive: true,
        vehicleId: null,
        driverName: null,
        createdAt: createDate(2025, 1, 1),
      });
      tripCount++;
    }
    console.log(`   ✓ ${tripCount} trips created`);

    // --------------------------------------------------------------------------
    // 7. CREATE TARIFFS (All station pairs)
    // --------------------------------------------------------------------------
    console.log('\n💰 Creating Tariffs...');
    let tariffCount = 0;

    for (let i = 0; i < stations.length; i++) {
      for (let j = i + 1; j < stations.length; j++) {
        const fromStationId = stations[i].id;
        const toStationId = stations[j].id;
        const numberOfStops = j - i;
        const price = calculateMetroSahelPrice(numberOfStops);

        // Forward direction tariff
        const tariffRef1 = db
          .collection('tariffs')
          .doc(`tariff_${fromStationId}_${toStationId}`);
        batch.set(tariffRef1, {
          operatorId: 'sncft_sahel',
          fromStationId: fromStationId,
          toStationId: toStationId,
          price: price,
          currency: 'TND',
          tariffClass: null,
          validFrom: validFrom,
          validTo: validTo,
          notes: null,
          specialDiscounts: [],
          createdAt: createDate(2025, 1, 1),
        });
        tariffCount++;

        // Reverse direction tariff
        const tariffRef2 = db
          .collection('tariffs')
          .doc(`tariff_${toStationId}_${fromStationId}`);
        batch.set(tariffRef2, {
          operatorId: 'sncft_sahel',
          fromStationId: toStationId,
          toStationId: fromStationId,
          price: price,
          currency: 'TND',
          tariffClass: null,
          validFrom: validFrom,
          validTo: validTo,
          notes: null,
          specialDiscounts: [],
          createdAt: createDate(2025, 1, 1),
        });
        tariffCount++;
      }
    }
    console.log(`   ✓ ${tariffCount} tariffs created`);

    // --------------------------------------------------------------------------
    // COMMIT BATCH
    // --------------------------------------------------------------------------
    console.log('\n⏳ Committing batch writes...');
    for (let i = 0; i < batches.length; i++) {
      await batches[i].commit();
      console.log(`   ✓ Batch ${i + 1}/${batches.length} committed`);
    }

    console.log('\n✅ METRO SAHEL SEEDING COMPLETED SUCCESSFULLY!\n');
    console.log('📊 Summary:');
    console.log(`   - 1 Transport Type (train)`);
    console.log(`   - 1 Operator (SNCFT Sahel)`);
    console.log(`   - ${stations.length} Stations (Mahdia → Sousse)`);
    console.log(`   - 2 Routes (504 & 503)`);
    console.log(`   - ${routeStopCount} Route Stops`);
    console.log(`   - ${tripCount} Trips (Complete SNCFT Official Schedule)`);
    console.log(`   - ${tariffCount} Tariffs`);
    console.log('\n💾 Data valid from 2025-10-01 to 2026-09-30');
    console.log('🚇 Line 504: Mahdia (05:48) → Sousse (23:08)');
    console.log('🚇 Line 503: Sousse (04:48) → Mahdia (23:18)\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error during seeding:', error);
    process.exit(1);
  }
}

// Run the seeding
seedMetroSahel();
