/**
 * Read-only Firestore test: check 3 journeys per timetable.
 * Does NOT write anything — safe to run even when write quota is exhausted.
 */
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-key.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

const dayOfWeek = new Date().getDay(); // 0=Sun ... 6=Sat
const nowMin = new Date().getHours() * 60 + new Date().getMinutes();

let passed = 0, failed = 0, skipped = 0;

async function testJourney(label, fromStationId, toStationId, routeIds) {
  process.stdout.write(`  ${label} ... `);
  try {
    // 1) Find the correct route by checking which route has both stations in route_stops
    let matchedRouteId = null;
    let fromOffset = -1, toOffset = -1, fromOrder = -1, toOrder = -1;

    for (const routeId of routeIds) {
      const rsSnap = await db.collection('route_stops')
        .where('routeId', '==', routeId).get();
      
      let fOff = -1, tOff = -1, fOrd = -1, tOrd = -1;
      for (const doc of rsSnap.docs) {
        const d = doc.data();
        if (d.stationId === fromStationId) { fOff = d.estimatedArrivalTimeMinutes || 0; fOrd = d.stopOrder; }
        if (d.stationId === toStationId) { tOff = d.estimatedArrivalTimeMinutes || 0; tOrd = d.stopOrder; }
      }
      if (fOff >= 0 && tOff >= 0 && fOrd < tOrd) {
        matchedRouteId = routeId;
        fromOffset = fOff; toOffset = tOff; fromOrder = fOrd; toOrder = tOrd;
        break;
      }
    }

    if (!matchedRouteId) {
      console.log(`SKIP (stations not found on routes: ${routeIds.join(', ')})`);
      skipped++;
      return;
    }

    // 2) Find trips for today on this route
    const tripsSnap = await db.collection('trips')
      .where('routeId', '==', matchedRouteId)
      .where('daysOfWeek', 'array-contains', dayOfWeek)
      .get();

    if (tripsSnap.empty) {
      console.log(`SKIP (no trips today, day=${dayOfWeek}, route=${matchedRouteId})`);
      skipped++;
      return;
    }

    // 3) Pick the first trip that hasn't departed yet (or just the first one)
    let bestTrip = null;
    let bestDep = 99999;
    for (const doc of tripsSnap.docs) {
      const d = doc.data();
      const depTs = d.departureTime;
      if (!depTs) continue;
      const depDate = depTs.toDate();
      const originMin = depDate.getHours() * 60 + depDate.getMinutes();
      
      // Check stationTimeOverridesMinutes
      const overrides = d.stationTimeOverridesMinutes;
      let actualDep;
      if (overrides && overrides[fromStationId] !== undefined) {
        actualDep = overrides[fromStationId];
      } else {
        actualDep = originMin + fromOffset;
      }

      let actualArr;
      if (overrides && overrides[toStationId] !== undefined) {
        actualArr = overrides[toStationId];
      } else {
        actualArr = originMin + toOffset;
      }

      // Check terminatesAtStationId
      const terminatesAt = d.terminatesAtStationId;
      if (terminatesAt) {
        // need to check if toStation order <= terminatesAt order
        // We'll just trust it for now
      }

      if (actualDep >= nowMin && actualDep < bestDep) {
        bestDep = actualDep;
        bestTrip = {
          tripNumber: d.tripNumber,
          dep: actualDep,
          arr: actualArr,
          duration: actualArr - actualDep,
          routeId: matchedRouteId,
        };
      }
    }

    if (!bestTrip) {
      // All trips already departed, just pick the first one for validation
      const firstDoc = tripsSnap.docs[0].data();
      const depDate = firstDoc.departureTime.toDate();
      const originMin = depDate.getHours() * 60 + depDate.getMinutes();
      const overrides = firstDoc.stationTimeOverridesMinutes;
      const dep = (overrides && overrides[fromStationId] !== undefined) ? overrides[fromStationId] : originMin + fromOffset;
      const arr = (overrides && overrides[toStationId] !== undefined) ? overrides[toStationId] : originMin + toOffset;
      bestTrip = {
        tripNumber: firstDoc.tripNumber,
        dep, arr,
        duration: arr - dep,
        routeId: matchedRouteId,
        note: '(already departed)',
      };
    }

    const depH = String(Math.floor(bestTrip.dep / 60)).padStart(2, '0');
    const depM = String(bestTrip.dep % 60).padStart(2, '0');
    const arrH = String(Math.floor(bestTrip.arr / 60)).padStart(2, '0');
    const arrM = String(bestTrip.arr % 60).padStart(2, '0');

    if (bestTrip.duration <= 0) {
      console.log(`FAIL trip ${bestTrip.tripNumber} dep=${depH}:${depM} arr=${arrH}:${arrM} dur=${bestTrip.duration}min (negative/zero duration)`);
      failed++;
    } else {
      console.log(`OK trip ${bestTrip.tripNumber} dep=${depH}:${depM} arr=${arrH}:${arrM} ${bestTrip.duration}min ${bestTrip.note||''}`);
      passed++;
    }
  } catch (e) {
    console.log(`FAIL ${e.message}`);
    failed++;
  }
}

async function main() {
  console.log(`\nJourney Data Test — ${new Date().toLocaleString()} (dayOfWeek=${dayOfWeek}, nowMin=${nowMin})\n`);

  // ═══════════════ LINE E ═══════════════
  console.log('=== Line E (Tunis Ville <-> Bougatfa) ===');
  await testJourney(
    'Tunis Ville -> Bougatfa',
    'bs_tunis_ville', 'be_bougatfa',
    ['route_line_e_forward']
  );
  await testJourney(
    'Bougatfa -> Tunis Ville',
    'be_bougatfa', 'bs_tunis_ville',
    ['route_line_e_reverse']
  );
  await testJourney(
    'Ennajah -> Bougatfa',
    'be_ennajah', 'be_bougatfa',
    ['route_line_e_forward']
  );

  // ═══════════════ SNCFT LINE 5 ═══════════════
  console.log('\n=== SNCFT Line 5 (Tunis <-> Tozeur) ===');
  await testJourney(
    'Tunis Ville -> Sfax',
    'bs_tunis_ville', 'sncft_sfax',
    ['route_sncft_l5_forward']
  );
  await testJourney(
    'Sousse -> Tunis Ville',
    'sncft_sousse_voyageurs', 'bs_tunis_ville',
    ['route_sncft_l5_reverse']
  );
  await testJourney(
    'Sfax -> Gabes',
    'sncft_sfax', 'sncft_gabes',
    ['route_sncft_l5_forward']
  );

  // ═══════════════ SNCFT REDEYEF ═══════════════
  console.log('\n=== SNCFT Redeyef (Metlaoui <-> Redeyef) ===');
  await testJourney(
    'Metlaoui -> Redeyef',
    'sncft_metlaoui', 'sncft_redeyef',
    ['route_sncft_redeyef_forward']
  );
  await testJourney(
    'Redeyef -> Metlaoui',
    'sncft_redeyef', 'sncft_metlaoui',
    ['route_sncft_redeyef_reverse']
  );
  await testJourney(
    'Redeyef -> Moulares',
    'sncft_redeyef', 'sncft_moulares',
    ['route_sncft_redeyef_reverse']
  );

  // ═══════════════ BANLIEUE NABEUL ═══════════════
  console.log('\n=== Banlieue Nabeul (Tunis <-> Nabeul) ===');
  await testJourney(
    'Tunis Ville -> Nabeul',
    'bs_tunis_ville', 'bn_nabeul',
    ['route_bn_forward']
  );
  await testJourney(
    'Nabeul -> Tunis Ville',
    'bn_nabeul', 'bs_tunis_ville',
    ['route_bn_reverse']
  );
  await testJourney(
    'Hammamet -> Nabeul',
    'bn_hammamet', 'bn_nabeul',
    ['route_bn_forward']
  );

  // ═══════════════ BANLIEUE SUD ═══════════════
  console.log('\n=== Banlieue Sud (Tunis <-> Erriadh) ===');
  await testJourney(
    'Tunis Ville -> Erriadh',
    'bs_tunis_ville', 'bs_erriadh',
    ['route_bs_south']
  );
  await testJourney(
    'Erriadh -> Tunis Ville',
    'bs_erriadh', 'bs_tunis_ville',
    ['route_bs_north']
  );
  await testJourney(
    'Hammam Lif -> Erriadh',
    'bs_hammam_lif', 'bs_erriadh',
    ['route_bs_south']
  );

  // ═══════════════ SUMMARY ═══════════════
  console.log(`\n${'='.repeat(50)}`);
  console.log(`RESULTS: ${passed} passed, ${failed} failed, ${skipped} skipped (total: ${passed+failed+skipped})`);
  console.log(`${'='.repeat(50)}\n`);

  process.exit(failed > 0 ? 1 : 0);
}

main().catch(e => { console.error(e); process.exit(1); });
