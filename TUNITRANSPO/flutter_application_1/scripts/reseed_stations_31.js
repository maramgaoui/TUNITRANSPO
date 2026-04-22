/**
 * Reseed Metro Sahel with the correct 31 official SNCFT stations.
 * Added vs previous 29: Frina, Moknine - Zone Industrielle
 */

const admin = require('firebase-admin');
const serviceAccount = require('./firebase-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ============================================================================
// 31 OFFICIAL STATIONS — Mahdia → Sousse order (route_ms_504)
// ============================================================================
const stations = [
  // -- Mahdia Region --
  { id: 'ms_mahdia',          name: 'Mahdia',                          cityId: 'mahdia',    lat: 35.5047, lng: 11.0622 },
  { id: 'ms_mahdia_ezzahra',  name: 'Mahdia - Ezzahra',               cityId: 'mahdia',    lat: 35.5095, lng: 11.0540 },
  { id: 'ms_borj_arif',      name: 'Borj Arif',                      cityId: 'mahdia',    lat: 35.5150, lng: 11.0450 },
  { id: 'ms_sidi_messaoud',  name: 'Sidi Messaoud',                  cityId: 'mahdia',    lat: 35.5230, lng: 11.0370 },
  { id: 'ms_mahdia_zt',      name: 'Mahdia - Zone Touristique',      cityId: 'mahdia',    lat: 35.5320, lng: 11.0260 },
  { id: 'ms_baghdadi',       name: 'Baghdadi',                       cityId: 'mahdia',    lat: 35.5420, lng: 11.0190 },
  // -- Bekalta / Téboulba --
  { id: 'ms_bekalta',        name: 'Bekalta',                        cityId: 'moknine',   lat: 35.5810, lng: 10.9940 },
  { id: 'ms_teboulba',       name: 'Téboulba',                       cityId: 'moknine',   lat: 35.6050, lng: 10.9780 },
  { id: 'ms_teboulba_zi',    name: 'Téboulba - Zone Industrielle',   cityId: 'moknine',   lat: 35.6150, lng: 10.9650 },
  // -- Moknine / Ksar Hellal --
  { id: 'ms_moknine_zi',     name: 'Moknine - Zone Industrielle',    cityId: 'moknine',   lat: 35.6250, lng: 10.9520 },
  { id: 'ms_moknine',        name: 'Moknine',                        cityId: 'moknine',   lat: 35.6350, lng: 10.9380 },
  { id: 'ms_moknine_gribaa', name: 'Moknine - Gribaa',               cityId: 'moknine',   lat: 35.6420, lng: 10.9230 },
  { id: 'ms_ksar_hellal',    name: 'Ksar Hellal',                    cityId: 'moknine',   lat: 35.6580, lng: 10.8920 },
  { id: 'ms_ksar_hellal_zi', name: 'Ksar Hellal - Zone Industrielle',cityId: 'moknine',   lat: 35.6500, lng: 10.8850 },
  // -- Sayada / Lamta / Bouhjar --
  { id: 'ms_sayada',         name: 'Sayada',                         cityId: 'moknine',   lat: 35.6760, lng: 10.8650 },
  { id: 'ms_lamta',          name: 'Lamta',                          cityId: 'moknine',   lat: 35.6890, lng: 10.8390 },
  { id: 'ms_bouhjar',        name: 'Bouhjar',                        cityId: 'monastir',  lat: 35.7020, lng: 10.8120 },
  { id: 'ms_ksiba_bennane',  name: 'Ksiba Bennane',                  cityId: 'monastir',  lat: 35.7180, lng: 10.7750 },
  { id: 'ms_khniss_bembla',  name: 'Khniss - Bembla',               cityId: 'monastir',  lat: 35.7160, lng: 10.7890 },
  // -- Monastir --
  { id: 'ms_monastir_zi',    name: 'Monastir - Zone Industrielle',   cityId: 'monastir',  lat: 35.7380, lng: 10.8040 },
  { id: 'ms_monastir',       name: 'Monastir',                       cityId: 'monastir',  lat: 35.7441, lng: 10.8081 },
  { id: 'ms_la_faculte',     name: 'La Faculté',                     cityId: 'monastir',  lat: 35.7520, lng: 10.7720 },
  { id: 'ms_aeroport',       name: 'Aéroport Skanès-Monastir',      cityId: 'monastir',  lat: 35.7572, lng: 10.7548 },
  // -- Frina / Sahline / Sousse --
  { id: 'ms_les_hotels',     name: 'Les Hôtels',                     cityId: 'sousse',    lat: 35.7750, lng: 10.7200 },
  { id: 'ms_frina',          name: 'Frina',                          cityId: 'sousse',    lat: 35.7780, lng: 10.7150 },
  { id: 'ms_sahline_sebkha', name: 'Sahline Sebkha',                 cityId: 'sousse',    lat: 35.7810, lng: 10.7100 },
  { id: 'ms_sahline',        name: 'Sahline',                        cityId: 'sousse',    lat: 35.7900, lng: 10.6970 },
  { id: 'ms_sousse_zi',      name: 'Sousse - Zone Industrielle',     cityId: 'sousse',    lat: 35.8100, lng: 10.6700 },
  { id: 'ms_sousse_sud',     name: 'Sousse Sud',                     cityId: 'sousse',    lat: 35.8175, lng: 10.6550 },
  { id: 'ms_sousse_mhmdv',   name: 'Sousse - Mohamed V',             cityId: 'sousse',    lat: 35.8220, lng: 10.6430 },
  { id: 'ms_sousse_bab_jedid', name: 'Sousse - Bab Jedid',           cityId: 'sousse',    lat: 35.8256, lng: 10.6369 },
];

const MINUTES_PER_GAP = 3; // 30 gaps × 3 = 90 min total (matches real schedule)

function calculatePrice(numberOfStops) {
  if (numberOfStops <= 0) return 0.0;
  return Math.round((0.55 + Math.floor((numberOfStops - 1) / 3) * 0.25) * 1000) / 1000;
}

function ts(y, m, d, h = 0, min = 0) {
  return admin.firestore.Timestamp.fromDate(new Date(y, m - 1, d, h, min, 0));
}

async function deletePrefix(col, prefix) {
  const snap = await db.collection(col).get();
  const docs = snap.docs.filter((d) => d.id.startsWith(prefix));
  console.log(`   Deleting ${docs.length} from ${col} (${prefix}*)`);
  for (let i = 0; i < docs.length; i += 490) {
    const b = db.batch();
    docs.slice(i, i + 490).forEach((d) => b.delete(d.ref));
    await b.commit();
  }
}

async function reseed() {
  try {
    console.log('🗑️  Phase 1: Cleaning old data...\n');
    await deletePrefix('stations', 'ms_');
    await deletePrefix('route_stops', 'rs_');
    await deletePrefix('tariffs', 'tariff_ms_');
    console.log('   ✅ Done.\n');

    const batches = [db.batch()];
    let ops = 0;
    function b() {
      if (ops >= 490) { batches.push(db.batch()); ops = 0; }
      ops++;
      return batches[batches.length - 1];
    }

    // Stations
    console.log(`🚉 Phase 2: Creating ${stations.length} stations...`);
    const hubs = new Set(['ms_mahdia', 'ms_sousse_bab_jedid', 'ms_monastir']);
    for (const s of stations) {
      b().set(db.collection('stations').doc(s.id), {
        name: s.name, cityId: s.cityId,
        latitude: s.lat, longitude: s.lng, address: null,
        transportTypes: ['train'], operatorsHere: ['sncft_sahel'],
        services: { wifi: false, toilet: true, cafe: true, parking: false },
        isMainHub: hubs.has(s.id), createdAt: ts(2025, 1, 1),
      });
    }
    console.log(`   ✓ ${stations.length} stations.\n`);

    // Route stops
    console.log('🚏 Phase 3: Creating route stops...');
    for (let i = 0; i < stations.length; i++) {
      b().set(db.collection('route_stops').doc(`rs_504_${i + 1}`), {
        routeId: 'route_ms_504', stationId: stations[i].id,
        stopOrder: i + 1, estimatedArrivalTimeMinutes: i * MINUTES_PER_GAP,
        arrivalNote: null, createdAt: ts(2025, 1, 1),
      });
    }
    for (let i = 0; i < stations.length; i++) {
      b().set(db.collection('route_stops').doc(`rs_503_${i + 1}`), {
        routeId: 'route_ms_503', stationId: stations[stations.length - 1 - i].id,
        stopOrder: i + 1, estimatedArrivalTimeMinutes: i * MINUTES_PER_GAP,
        arrivalNote: null, createdAt: ts(2025, 1, 1),
      });
    }
    console.log(`   ✓ ${stations.length * 2} route stops.\n`);

    // Routes
    console.log('🛤️  Phase 4: Updating routes...');
    b().set(db.collection('routes').doc('route_ms_504'), {
      operatorId: 'sncft_sahel', typeId: 'train', lineNumber: '504',
      name: 'Mahdia → Sousse', description: 'Métro du Sahel Mahdia vers Sousse - Bab Jedid',
      originStationId: 'ms_mahdia', destinationStationId: 'ms_sousse_bab_jedid',
      isCircular: false, isActive: true, stopIds: stations.map(s => s.id),
      createdAt: ts(2025, 1, 1),
    });
    b().set(db.collection('routes').doc('route_ms_503'), {
      operatorId: 'sncft_sahel', typeId: 'train', lineNumber: '503',
      name: 'Sousse → Mahdia', description: 'Métro du Sahel Sousse - Bab Jedid vers Mahdia',
      originStationId: 'ms_sousse_bab_jedid', destinationStationId: 'ms_mahdia',
      isCircular: false, isActive: true, stopIds: [...stations].reverse().map(s => s.id),
      createdAt: ts(2025, 1, 1),
    });
    console.log('   ✓ 2 routes.\n');

    // Tariffs
    console.log('💰 Phase 5: Creating tariffs...');
    const vF = ts(2025, 10, 1), vT = ts(2026, 9, 30);
    let tc = 0;
    for (let i = 0; i < stations.length; i++) {
      for (let j = i + 1; j < stations.length; j++) {
        const a = stations[i].id, bId = stations[j].id;
        const p = calculatePrice(j - i);
        b().set(db.collection('tariffs').doc(`tariff_${a}_${bId}`), {
          operatorId: 'sncft_sahel', fromStationId: a, toStationId: bId,
          price: p, currency: 'TND', tariffClass: null,
          validFrom: vF, validTo: vT, notes: null, specialDiscounts: [],
          createdAt: ts(2025, 1, 1),
        });
        tc++;
        b().set(db.collection('tariffs').doc(`tariff_${bId}_${a}`), {
          operatorId: 'sncft_sahel', fromStationId: bId, toStationId: a,
          price: p, currency: 'TND', tariffClass: null,
          validFrom: vF, validTo: vT, notes: null, specialDiscounts: [],
          createdAt: ts(2025, 1, 1),
        });
        tc++;
      }
    }
    console.log(`   ✓ ${tc} tariffs.\n`);

    // Trip arrival times
    console.log('🕐 Phase 6: Updating trip arrival times...');
    const totalMin = (stations.length - 1) * MINUTES_PER_GAP; // 90 min
    const base = new Date(2025, 9, 1);
    function toMin(t) { const [h, m] = t.split(':').map(Number); return h * 60 + m; }
    function minTs(m) { const d = new Date(base); d.setHours(Math.floor(m / 60), m % 60, 0, 0); return admin.firestore.Timestamp.fromDate(d); }

    const t504 = [
      [504,'04:55'],[506,'05:25'],[508,'06:10'],[510,'06:40'],
      [512,'07:50'],[514,'08:55'],[516,'09:50'],[518,'10:55'],
      [520,'11:30'],[522,'12:05'],[524,'13:25'],[526,'14:30'],
      [528,'15:35'],[530,'16:25'],[532,'17:05'],[534,'18:15'],
      [536,'18:50'],[538,'19:50'],
    ];
    const t503 = [
      [501,'05:40'],[503,'06:50'],[505,'07:30'],[507,'08:30'],
      [509,'08:50'],[511,'09:55'],[513,'11:05'],[515,'12:25'],
      [517,'13:05'],[519,'13:30'],[521,'14:05'],[523,'15:35'],
      [525,'16:40'],[527,'17:25'],[529,'18:30'],[531,'19:00'],
      [533,'19:30'],[535,'20:10'],
    ];
    for (const [n, d] of t504) b().update(db.collection('trips').doc(`trip_504_${n}`), { arrivalTime: minTs(toMin(d) + totalMin) });
    for (const [n, d] of t503) b().update(db.collection('trips').doc(`trip_503_${n}`), { arrivalTime: minTs(toMin(d) + totalMin) });
    console.log(`   ✓ 36 trips updated (${totalMin} min journey).\n`);

    // Commit
    console.log(`⏳ Committing ${batches.length} batch(es)...`);
    for (let i = 0; i < batches.length; i++) {
      await batches[i].commit();
      console.log(`   ✓ Batch ${i + 1}/${batches.length}`);
    }

    console.log(`\n✅ DONE! ${stations.length} stations, ${tc} tariffs, 90 min journey.`);
    process.exit(0);
  } catch (err) {
    console.error('❌', err);
    process.exit(1);
  }
}

reseed();
