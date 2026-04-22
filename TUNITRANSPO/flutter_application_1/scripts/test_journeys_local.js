/**
 * LOCAL-ONLY journey test — reads JSON timetable files, simulates app search
 * logic for 3 station pairs per timetable. No Firestore required.
 */
const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, 'data');
const now = new Date();
const dayOfWeek = now.getDay(); // 0=Sun ... 6=Sat
const nowMin = now.getHours() * 60 + now.getMinutes();

function timeToMin(t) {
  const [h, m] = t.split(':').map(Number);
  return h * 60 + m;
}
function minToTime(m) {
  const h = String(Math.floor(((m % 1440) + 1440) % 1440 / 60)).padStart(2, '0');
  const mm = String(((m % 1440) + 1440) % 1440 % 60).padStart(2, '0');
  return `${h}:${mm}`;
}

let passed = 0, failed = 0, skipped = 0;

function loadJson(filename) {
  return JSON.parse(fs.readFileSync(path.join(dataDir, filename), 'utf8'));
}

/**
 * Simulate journey search: given timetable JSON, find next trip from→to.
 */
function findTrip(timetable, routeId, fromStationId, toStationId) {
  // Find the route
  const allRoutes = timetable.routes;
  const route = allRoutes.find(r => r.id === routeId);
  if (!route) return { error: `route ${routeId} not found` };

  // Find route stops for this route
  const allStops = timetable.routeStops;
  
  // Route stops may use 'routeId' or 'direction' field depending on file format
  let routeStops;
  if (allStops[0] && allStops[0].routeId) {
    routeStops = allStops.filter(s => s.routeId === routeId);
  } else {
    routeStops = allStops.filter(s => s.direction === route.direction);
    // If no stops found for this direction (e.g. BS north), generate from reverse
    if (routeStops.length === 0) {
      const oppositeDir = route.direction === 'north' ? 'south'
                        : route.direction === 'reverse' ? 'forward'
                        : route.direction === 'south' ? 'north' : 'reverse';
      const fwdStops = allStops.filter(s => s.direction === oppositeDir)
        .sort((a, b) => a.stopOrder - b.stopOrder);
      if (fwdStops.length > 0) {
        const lastOffset = fwdStops[fwdStops.length - 1].estimatedArrivalTimeMinutes;
        routeStops = fwdStops.slice().reverse().map((s, i) => ({
          stationId: s.stationId,
          stopOrder: i + 1,
          estimatedArrivalTimeMinutes: lastOffset - s.estimatedArrivalTimeMinutes,
        }));
      }
    }
  }

  const fromStop = routeStops.find(s => s.stationId === fromStationId);
  const toStop = routeStops.find(s => s.stationId === toStationId);

  if (!fromStop) return { error: `from station ${fromStationId} not on route ${routeId}` };
  if (!toStop) return { error: `to station ${toStationId} not on route ${routeId}` };
  if (fromStop.stopOrder >= toStop.stopOrder) return { error: `from stop order ${fromStop.stopOrder} >= to ${toStop.stopOrder}` };

  const fromOffset = fromStop.estimatedArrivalTimeMinutes;
  const toOffset = toStop.estimatedArrivalTimeMinutes;

  // Get trips for today
  const trips = route.trips || [];
  const todayTrips = trips.filter(t => {
    const days = t.days || t.operatingDays || [0,1,2,3,4,5,6];
    return days.includes(dayOfWeek);
  });

  if (todayTrips.length === 0) return { error: `no trips today (day=${dayOfWeek})`, totalTrips: trips.length };

  // Find next trip
  let best = null;
  for (const trip of todayTrips) {
    const originMin = timeToMin(trip.departureTime);
    
    // Check stationTimeOverrides
    const overrides = trip.stationTimeOverrides;
    let actualDep, actualArr;
    
    if (overrides && overrides[fromStationId]) {
      actualDep = timeToMin(overrides[fromStationId]);
    } else {
      actualDep = originMin + fromOffset;
    }
    
    if (overrides && overrides[toStationId]) {
      actualArr = timeToMin(overrides[toStationId]);
    } else {
      actualArr = originMin + toOffset;
    }

    // Check terminatesAtStationId
    if (trip.terminatesAtStationId) {
      const termStop = routeStops.find(s => s.stationId === trip.terminatesAtStationId);
      if (termStop && toStop.stopOrder > termStop.stopOrder) continue;
    }

    // Check originStationId (partial-origin trips)
    if (trip.originStationId) {
      const originStop = routeStops.find(s => s.stationId === trip.originStationId);
      if (originStop && fromStop.stopOrder < originStop.stopOrder) continue;
    }

    const duration = actualArr - actualDep;
    if (duration <= 0) continue;
    
    const candidate = {
      tripNumber: trip.tripNumber,
      dep: actualDep,
      arr: actualArr,
      duration,
    };

    if (actualDep >= nowMin && (!best || actualDep < best.dep)) {
      best = candidate;
    }
    if (!best) best = candidate; // fallback to first valid trip
  }

  if (!best) return { error: `all ${todayTrips.length} trips filtered out (terminates/origin)` };
  return best;
}

function testJourney(label, timetableFile, routeId, fromId, toId) {
  process.stdout.write(`  ${label} ... `);
  try {
    const tt = loadJson(timetableFile);
    const result = findTrip(tt, routeId, fromId, toId);
    if (result.error) {
      console.log(`FAIL — ${result.error}`);
      failed++;
    } else {
      const next = result.dep >= nowMin ? '' : '(next day)';
      console.log(`OK  trip ${result.tripNumber}  dep ${minToTime(result.dep)} -> arr ${minToTime(result.arr)}  ${result.duration}min ${next}`);
      passed++;
    }
  } catch (e) {
    console.log(`FAIL — ${e.message}`);
    failed++;
  }
}

console.log(`\nLocal Journey Test — ${now.toLocaleString()}`);
console.log(`Day of week: ${dayOfWeek} (${['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][dayOfWeek]})  Now: ${minToTime(nowMin)}\n`);

// ═════════════════════════════════════════
// LINE E  (Tunis Ville <-> Bougatfa)
// ═════════════════════════════════════════
console.log('=== Line E (Tunis Ville <-> Bougatfa) ===');
testJourney('Tunis Ville -> Bougatfa',     'line_e_timetable.json', 'route_line_e_forward', 'bs_tunis_ville', 'be_bougatfa');
testJourney('Bougatfa -> Tunis Ville',     'line_e_timetable.json', 'route_line_e_reverse', 'be_bougatfa', 'bs_tunis_ville');
testJourney('Ennajah -> Bougatfa',         'line_e_timetable.json', 'route_line_e_forward', 'be_ennajah', 'be_bougatfa');

// ═════════════════════════════════════════
// SNCFT LINE 5  (Tunis <-> Tozeur)
// ═════════════════════════════════════════
console.log('\n=== SNCFT Line 5 (Tunis <-> Tozeur) ===');
testJourney('Tunis Ville -> Sfax',         'sncft_line5_timetable.json', 'route_sncft_l5_forward', 'bs_tunis_ville', 'sncft_sfax');
testJourney('Sousse -> Tunis (reverse)',   'sncft_line5_timetable.json', 'route_sncft_l5_reverse', 'sncft_sousse_voyageurs', 'bs_tunis_ville');
testJourney('Sfax -> Gabes',               'sncft_line5_timetable.json', 'route_sncft_l5_forward', 'sncft_sfax', 'sncft_gabes');

// ═════════════════════════════════════════
// SNCFT REDEYEF  (Metlaoui <-> Redeyef)
// ═════════════════════════════════════════
console.log('\n=== SNCFT Redeyef (Metlaoui <-> Redeyef) ===');
testJourney('Metlaoui -> Redeyef',         'sncft_line5_timetable.json', 'route_sncft_redeyef_forward', 'sncft_metlaoui', 'sncft_redeyef');
testJourney('Redeyef -> Metlaoui',         'sncft_line5_timetable.json', 'route_sncft_redeyef_reverse', 'sncft_redeyef', 'sncft_metlaoui');
testJourney('Redeyef -> Moulares',         'sncft_line5_timetable.json', 'route_sncft_redeyef_reverse', 'sncft_redeyef', 'sncft_moulares');

// ═════════════════════════════════════════
// BANLIEUE NABEUL  (Tunis <-> Nabeul)
// ═════════════════════════════════════════
console.log('\n=== Banlieue Nabeul (Tunis <-> Nabeul) ===');
testJourney('Tunis Ville -> Nabeul',       'banlieue_nabeul_timetable.json', 'route_bn_forward', 'bs_tunis_ville', 'bn_nabeul');
testJourney('Nabeul -> Tunis Ville',       'banlieue_nabeul_timetable.json', 'route_bn_reverse', 'bn_nabeul', 'bs_tunis_ville');
testJourney('Hammamet -> Nabeul',          'banlieue_nabeul_timetable.json', 'route_bn_forward', 'bn_hammamet', 'bn_nabeul');

// ═════════════════════════════════════════
// BANLIEUE SUD  (Tunis <-> Erriadh)
// ═════════════════════════════════════════
console.log('\n=== Banlieue Sud (Tunis <-> Erriadh) ===');
testJourney('Tunis Ville -> Erriadh',      'banlieue_sud_line_a_timetable.json', 'route_bs_south', 'bs_tunis_ville', 'bs_erriadh');
testJourney('Erriadh -> Tunis Ville',      'banlieue_sud_line_a_timetable.json', 'route_bs_north', 'bs_erriadh', 'bs_tunis_ville');
testJourney('Hammam Lif -> Erriadh',       'banlieue_sud_line_a_timetable.json', 'route_bs_south', 'bs_hammam_lif', 'bs_erriadh');

// ═════════════════════════════════════════
// GRANDES LIGNES ANNABA  (Tunis <-> Annaba)
// ═════════════════════════════════════════
console.log('\n=== Grandes Lignes Annaba (Tunis <-> Annaba via Béja/Jendouba) ===');
testJourney('Tunis Ville -> Beja',         'grandes_lignes_timetable.json', 'route_sncft_gl_annaba_forward', 'bs_tunis_ville', 'sncft_beja');
testJourney('Tunis Ville -> Ghardimaou',   'grandes_lignes_timetable.json', 'route_sncft_gl_annaba_forward', 'bs_tunis_ville', 'sncft_ghardimaou');
testJourney('Ghardimaou -> Tunis (rev)',   'grandes_lignes_timetable.json', 'route_sncft_gl_annaba_reverse', 'sncft_ghardimaou', 'bs_tunis_ville');

// ═════════════════════════════════════════
// GRANDES LIGNES BIZERTE  (Tunis <-> Bizerte)
// ═════════════════════════════════════════
console.log('\n=== Grandes Lignes Bizerte (Tunis <-> Bizerte) ===');
testJourney('Tunis Ville -> Bizerte',      'grandes_lignes_timetable.json', 'route_sncft_gl_bizerte_forward', 'bs_tunis_ville', 'sncft_bizerte');
testJourney('Bizerte -> Tunis Ville',      'grandes_lignes_timetable.json', 'route_sncft_gl_bizerte_reverse', 'sncft_bizerte', 'bs_tunis_ville');
testJourney('Mateur -> Bizerte',           'grandes_lignes_timetable.json', 'route_sncft_gl_bizerte_forward', 'sncft_mateur', 'sncft_bizerte');

// ═════════════════════════════════════════
// SNCFT KEF / KALAA KHASBA  (Tunis <-> Le Kef/Kalaa Khasba)
// ═════════════════════════════════════════
console.log('\n=== SNCFT Kef/Kalaa Khasba (Tunis <-> Le Kef/Kalaa Khasba) ===');
testJourney('Tunis Ville -> Le Kef',       'sncft_kef_timetable.json', 'route_sncft_kef_forward', 'bs_tunis_ville', 'sncft_kef_le_kef');
testJourney('Le Kef -> Tunis Ville',       'sncft_kef_timetable.json', 'route_sncft_kef_reverse', 'sncft_kef_le_kef', 'bs_tunis_ville');
testJourney('Dahmani -> Tunis Ville',      'sncft_kef_timetable.json', 'route_sncft_kef_reverse', 'sncft_kef_dahmani', 'bs_tunis_ville');

// ═════════════════════════════════════════
console.log(`\n${'═'.repeat(55)}`);
console.log(`  RESULTS: ${passed} passed, ${failed} failed, ${skipped} skipped  (${passed+failed+skipped} total)`);
console.log(`${'═'.repeat(55)}\n`);

process.exit(failed > 0 ? 1 : 0);
