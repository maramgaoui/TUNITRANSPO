/**
 * Upsert 31 Metro Sahel stations + route_stops + tariffs + route docs.
 * Uses Firestore set() which creates-or-overwrites — no deletion needed.
 * Then deletes orphan station/route_stop IDs from the old 22/29 schemes.
 */
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-key.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const stations = [
  { id: 'ms_mahdia',          name: 'Mahdia',                          cityId: 'mahdia',    lat: 35.5047, lng: 11.0622 },
  { id: 'ms_mahdia_ezzahra',  name: 'Mahdia - Ezzahra',               cityId: 'mahdia',    lat: 35.5095, lng: 11.0540 },
  { id: 'ms_borj_arif',      name: 'Borj Arif',                      cityId: 'mahdia',    lat: 35.5150, lng: 11.0450 },
  { id: 'ms_sidi_messaoud',  name: 'Sidi Messaoud',                  cityId: 'mahdia',    lat: 35.5230, lng: 11.0370 },
  { id: 'ms_mahdia_zt',      name: 'Mahdia - Zone Touristique',      cityId: 'mahdia',    lat: 35.5320, lng: 11.0260 },
  { id: 'ms_baghdadi',       name: 'Baghdadi',                       cityId: 'mahdia',    lat: 35.5420, lng: 11.0190 },
  { id: 'ms_bekalta',        name: 'Bekalta',                        cityId: 'moknine',   lat: 35.5810, lng: 10.9940 },
  { id: 'ms_teboulba',       name: 'Téboulba',                       cityId: 'moknine',   lat: 35.6050, lng: 10.9780 },
  { id: 'ms_teboulba_zi',    name: 'Téboulba - Zone Industrielle',   cityId: 'moknine',   lat: 35.6150, lng: 10.9650 },
  { id: 'ms_moknine_zi',     name: 'Moknine - Zone Industrielle',    cityId: 'moknine',   lat: 35.6250, lng: 10.9520 },
  { id: 'ms_moknine',        name: 'Moknine',                        cityId: 'moknine',   lat: 35.6350, lng: 10.9380 },
  { id: 'ms_moknine_gribaa', name: 'Moknine - Gribaa',               cityId: 'moknine',   lat: 35.6420, lng: 10.9230 },
  { id: 'ms_ksar_hellal',    name: 'Ksar Hellal',                    cityId: 'moknine',   lat: 35.6580, lng: 10.8920 },
  { id: 'ms_ksar_hellal_zi', name: 'Ksar Hellal - Zone Industrielle',cityId: 'moknine',   lat: 35.6500, lng: 10.8850 },
  { id: 'ms_sayada',         name: 'Sayada',                         cityId: 'moknine',   lat: 35.6760, lng: 10.8650 },
  { id: 'ms_lamta',          name: 'Lamta',                          cityId: 'moknine',   lat: 35.6890, lng: 10.8390 },
  { id: 'ms_bouhjar',        name: 'Bouhjar',                        cityId: 'monastir',  lat: 35.7020, lng: 10.8120 },
  { id: 'ms_ksiba_bennane',  name: 'Ksiba Bennane',                  cityId: 'monastir',  lat: 35.7180, lng: 10.7750 },
  { id: 'ms_khniss_bembla',  name: 'Khniss - Bembla',               cityId: 'monastir',  lat: 35.7160, lng: 10.7890 },
  { id: 'ms_monastir_zi',    name: 'Monastir - Zone Industrielle',   cityId: 'monastir',  lat: 35.7380, lng: 10.8040 },
  { id: 'ms_monastir',       name: 'Monastir',                       cityId: 'monastir',  lat: 35.7441, lng: 10.8081 },
  { id: 'ms_la_faculte',     name: 'La Faculté',                     cityId: 'monastir',  lat: 35.7520, lng: 10.7720 },
  { id: 'ms_aeroport',       name: 'Aéroport Skanès-Monastir',      cityId: 'monastir',  lat: 35.7572, lng: 10.7548 },
  { id: 'ms_les_hotels',     name: 'Les Hôtels',                     cityId: 'sousse',    lat: 35.7750, lng: 10.7200 },
  { id: 'ms_frina',          name: 'Frina',                          cityId: 'sousse',    lat: 35.7780, lng: 10.7150 },
  { id: 'ms_sahline_sebkha', name: 'Sahline Sebkha',                 cityId: 'sousse',    lat: 35.7810, lng: 10.7100 },
  { id: 'ms_sahline',        name: 'Sahline',                        cityId: 'sousse',    lat: 35.7900, lng: 10.6970 },
  { id: 'ms_sousse_zi',      name: 'Sousse - Zone Industrielle',     cityId: 'sousse',    lat: 35.8100, lng: 10.6700 },
  { id: 'ms_sousse_sud',     name: 'Sousse Sud',                     cityId: 'sousse',    lat: 35.8175, lng: 10.6550 },
  { id: 'ms_sousse_mhmdv',   name: 'Sousse - Mohamed V',             cityId: 'sousse',    lat: 35.8220, lng: 10.6430 },
  { id: 'ms_sousse_bab_jedid', name: 'Sousse - Bab Jedid',           cityId: 'sousse',    lat: 35.8256, lng: 10.6369 },
];

const GAP = 3; // 30 gaps × 3 min = 90 min total

function price(n) {
  if (n <= 0) return 0;
  return Math.round((0.55 + Math.floor((n - 1) / 3) * 0.25) * 1000) / 1000;
}
function ts(y, m, d, h, mn) {
  return admin.firestore.Timestamp.fromDate(new Date(y, m - 1, d, h || 0, mn || 0, 0));
}

// IDs from old 22/29-station seeds that no longer exist in new 31 set
const orphanStationIds = [
  'ms_ezzahra', 'ms_sidi_massoud', 'ms_teboulba_zind', 'ms_moknine_grba',
  'ms_monastir_med_bennane', 'ms_sahline_sabkha', 'ms_sahline_ville',
  'ms_sousse_znd',
];

async function run() {
  try {
    // ── 1. Upsert stations ──
    console.log(`🚉 Upserting ${stations.length} stations...`);
    let batch = db.batch(), ops = 0;
    const flush = async () => { if (ops > 0) { await batch.commit(); batch = db.batch(); ops = 0; } };
    const add = (ref, data) => { batch.set(ref, data); ops++; if (ops >= 490) { const p = batch.commit(); batch = db.batch(); ops = 0; return p; } };

    const hubs = new Set(['ms_mahdia', 'ms_sousse_bab_jedid', 'ms_monastir']);
    for (const s of stations) {
      await add(db.collection('stations').doc(s.id), {
        name: s.name, cityId: s.cityId, latitude: s.lat, longitude: s.lng,
        address: null, transportTypes: ['train'], operatorsHere: ['sncft_sahel'],
        services: { wifi: false, toilet: true, cafe: true, parking: false },
        isMainHub: hubs.has(s.id), createdAt: ts(2025, 1, 1),
      });
    }
    await flush();
    console.log('   ✓ Stations done.\n');

    // ── 2. Upsert route stops ──
    console.log('🚏 Upserting 62 route stops...');
    for (let i = 0; i < stations.length; i++) {
      await add(db.collection('route_stops').doc(`rs_504_${i + 1}`), {
        routeId: 'route_ms_504', stationId: stations[i].id,
        stopOrder: i + 1, estimatedArrivalTimeMinutes: i * GAP,
        arrivalNote: null, createdAt: ts(2025, 1, 1),
      });
    }
    for (let i = 0; i < stations.length; i++) {
      await add(db.collection('route_stops').doc(`rs_503_${i + 1}`), {
        routeId: 'route_ms_503', stationId: stations[stations.length - 1 - i].id,
        stopOrder: i + 1, estimatedArrivalTimeMinutes: i * GAP,
        arrivalNote: null, createdAt: ts(2025, 1, 1),
      });
    }
    await flush();
    console.log('   ✓ Route stops done.\n');

    // ── 3. Delete leftover route_stops (old seeds had 22 or 29 entries) ──
    console.log('🧹 Cleaning orphan route_stop docs (30-44)...');
    for (let i = stations.length + 1; i <= 44; i++) {
      batch.delete(db.collection('route_stops').doc(`rs_504_${i}`));
      batch.delete(db.collection('route_stops').doc(`rs_503_${i}`));
      ops += 2;
    }
    await flush();
    console.log('   ✓ Done.\n');

    // ── 4. Routes ──
    console.log('🛤️  Upserting routes...');
    await add(db.collection('routes').doc('route_ms_504'), {
      operatorId: 'sncft_sahel', typeId: 'train', lineNumber: '504',
      name: 'Mahdia → Sousse', description: 'Métro du Sahel Mahdia → Sousse - Bab Jedid',
      originStationId: 'ms_mahdia', destinationStationId: 'ms_sousse_bab_jedid',
      isCircular: false, isActive: true, stopIds: stations.map(s => s.id),
      createdAt: ts(2025, 1, 1),
    });
    await add(db.collection('routes').doc('route_ms_503'), {
      operatorId: 'sncft_sahel', typeId: 'train', lineNumber: '503',
      name: 'Sousse → Mahdia', description: 'Métro du Sahel Sousse - Bab Jedid → Mahdia',
      originStationId: 'ms_sousse_bab_jedid', destinationStationId: 'ms_mahdia',
      isCircular: false, isActive: true, stopIds: [...stations].reverse().map(s => s.id),
      createdAt: ts(2025, 1, 1),
    });
    await flush();
    console.log('   ✓ Routes done.\n');

    // ── 5. Tariffs — upsert all pairs ──
    console.log('💰 Upserting tariffs...');
    const vF = ts(2025, 10, 1), vT = ts(2026, 9, 30);
    let tc = 0;
    for (let i = 0; i < stations.length; i++) {
      for (let j = i + 1; j < stations.length; j++) {
        const a = stations[i].id, bId = stations[j].id, p = price(j - i);
        const base = { operatorId: 'sncft_sahel', price: p, currency: 'TND', tariffClass: null, validFrom: vF, validTo: vT, notes: null, specialDiscounts: [], createdAt: ts(2025, 1, 1) };
        await add(db.collection('tariffs').doc(`tariff_${a}_${bId}`), { ...base, fromStationId: a, toStationId: bId });
        await add(db.collection('tariffs').doc(`tariff_${bId}_${a}`), { ...base, fromStationId: bId, toStationId: a });
        tc += 2;
      }
    }
    await flush();
    console.log(`   ✓ ${tc} tariffs.\n`);

    // ── 6. Trip arrival times ──
    console.log('🕐 Updating trip arrival times...');
    const totalMin = (stations.length - 1) * GAP;
    const baseD = new Date(2025, 9, 1);
    const toMin = t => { const [h, m] = t.split(':').map(Number); return h * 60 + m; };
    const minTs = m => { const d = new Date(baseD); d.setHours(Math.floor(m / 60), m % 60, 0, 0); return admin.firestore.Timestamp.fromDate(d); };
    const t504 = [[504,'04:55'],[506,'05:25'],[508,'06:10'],[510,'06:40'],[512,'07:50'],[514,'08:55'],[516,'09:50'],[518,'10:55'],[520,'11:30'],[522,'12:05'],[524,'13:25'],[526,'14:30'],[528,'15:35'],[530,'16:25'],[532,'17:05'],[534,'18:15'],[536,'18:50'],[538,'19:50']];
    const t503 = [[501,'05:40'],[503,'06:50'],[505,'07:30'],[507,'08:30'],[509,'08:50'],[511,'09:55'],[513,'11:05'],[515,'12:25'],[517,'13:05'],[519,'13:30'],[521,'14:05'],[523,'15:35'],[525,'16:40'],[527,'17:25'],[529,'18:30'],[531,'19:00'],[533,'19:30'],[535,'20:10']];
    for (const [n, d] of t504) { batch.update(db.collection('trips').doc(`trip_504_${n}`), { arrivalTime: minTs(toMin(d) + totalMin) }); ops++; }
    for (const [n, d] of t503) { batch.update(db.collection('trips').doc(`trip_503_${n}`), { arrivalTime: minTs(toMin(d) + totalMin) }); ops++; }
    await flush();
    console.log(`   ✓ 36 trips → ${totalMin} min journey.\n`);

    // ── 7. Delete orphan station docs ──
    console.log('🧹 Deleting orphan station IDs...');
    for (const id of orphanStationIds) {
      batch.delete(db.collection('stations').doc(id));
      ops++;
    }
    await flush();
    console.log(`   ✓ ${orphanStationIds.length} orphan stations removed.\n`);

    // ── 8. Delete orphan tariffs referencing old station IDs ──
    console.log('🧹 Deleting orphan tariffs (old station IDs)...');
    let orphanTariffs = 0;
    const tariffSnap = await db.collection('tariffs').get();
    const validIds = new Set(stations.map(s => s.id));
    const toDelete = tariffSnap.docs.filter(d => {
      const data = d.data();
      if (!d.id.startsWith('tariff_ms_')) return false;
      return !validIds.has(data.fromStationId) || !validIds.has(data.toStationId);
    });
    for (const doc of toDelete) {
      batch.delete(doc.ref);
      ops++;
      orphanTariffs++;
      if (ops >= 490) { await batch.commit(); batch = db.batch(); ops = 0; }
    }
    await flush();
    console.log(`   ✓ ${orphanTariffs} orphan tariffs removed.\n`);

    console.log(`✅ DONE! ${stations.length} stations, ${tc} tariffs, ${totalMin} min journey time.`);
    process.exit(0);
  } catch (e) {
    console.error('❌', e);
    process.exit(1);
  }
}

run();
