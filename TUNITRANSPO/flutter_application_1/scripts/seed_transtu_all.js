#!/usr/bin/env node
/**
 * Seed ALL TRANSTU data from the new JSON files in scripts/data/.
 *
 * Handles two JSON formats that exist across the 17 files:
 *
 * FORMAT A (full — 10 files):  transtu10dec, ariana, barcelone, bebalioua,
 *   belhouanel, bellevie, carthage, charguia, intileka, jardinthh
 *   → has { stations[], routes[{ id, trips[], ... }], routeStops[] }
 *
 * FORMAT B (loose — 7 files):  khaireddine, marine, montazah, mornag,
 *   reste, slimane, tbourba
 *   → has { stations[], routes[{ lineNumber, destinationAr, firstDepartureHub, ... }] }
 *   → route IDs, routeStops, and trip docs are synthesised here
 *
 * Written to Firestore:
 *   stations      transtu_hub_* / transtu_dest_*
 *   routes        route_transtu_*
 *   route_stops   one doc per (route x stop)
 *   trips         trip_transtu_*  (one per route, from first departure)
 *
 * Operator doc (transtu) is upserted but never deleted.
 */

const path = require('path');
const fs   = require('fs');
const { admin, initializeFirebaseAdmin } = require('./firebase_admin_init');

initializeFirebaseAdmin();
const db = admin.firestore();

// ─── BatchWriter ─────────────────────────────────────────────────────────────

const BATCH_SIZE = 490;

class BatchWriter {
  constructor() {
    this._batch = db.batch();
    this._count = 0;
  }

  set(ref, data) {
    this._batch.set(ref, data, { merge: true });
    this._count++;
  }

  async flushIfFull() {
    if (this._count >= BATCH_SIZE) await this.flush();
  }

  async flush() {
    if (this._count === 0) return;
    await this._batch.commit();
    this._batch = db.batch();
    this._count = 0;
  }
}

// ─── helpers ─────────────────────────────────────────────────────────────────

/**
 * Very light slugifier used to build synthetic IDs from Arabic/French text.
 * Keeps only a-z, 0-9 and underscores.
 */
function slugify(str) {
  return String(str)
    .toLowerCase()
    .replace(/[أإآا]/g, 'a').replace(/ة/g, 'a').replace(/[ىي]/g, 'i')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

/** Parse "20 min" / "20" → 20.  Returns null if unparseable. */
function parsePeakFreq(raw) {
  if (!raw) return null;
  const n = parseInt(String(raw), 10);
  return isNaN(n) ? null : n;
}

// ─── Format detection ────────────────────────────────────────────────────────

/** Format A routes carry an explicit `id` field. */
function isFormatA(d) {
  return Array.isArray(d.routes) && d.routes.length > 0 && 'id' in d.routes[0];
}

// ─── FORMAT A ────────────────────────────────────────────────────────────────

async function seedFormatA(d, bw, stats) {
  const { stations = [], routes = [], routeStops = [] } = d;

  for (const s of stations) {
    bw.set(db.collection('stations').doc(s.id), {
      name:           s.name,
      nameAr:         s.nameAr ?? s.name,
      cityId:         s.cityId ?? 'tunis',
      latitude:       s.lat ?? s.latitude ?? null,
      longitude:      s.lng ?? s.longitude ?? null,
      isMainHub:      s.isMainHub ?? false,
      transportTypes: ['bus'],
      operatorsHere:  ['transtu'],
    });
    await bw.flushIfFull();
    stats.stations++;
  }

  for (const r of routes) {
    bw.set(db.collection('routes').doc(r.id), {
      lineNumber:               r.lineNumber,
      name:                     r.name ?? null,
      direction:                r.direction ?? 'forward',
      operatorId:               'transtu',
      transportType:            'bus',
      originStationId:          r.originStationId ?? null,
      destinationStationId:     r.destinationStationId ?? null,
      firstDepartureFromHub:    r.firstDepartureFromHub ?? null,
      lastDepartureFromHub:     r.lastDepartureFromHub ?? null,
      firstDepartureFromSuburb: r.firstDepartureFromSuburb ?? null,
      lastDepartureFromSuburb:  r.lastDepartureFromSuburb ?? null,
      peakFrequencyMinutes:     r.peakFrequencyMinutes ?? null,
      zone:                     r.zone ?? 'urbaine',
      price:                    r.price ?? 0.5,
    });
    await bw.flushIfFull();
    stats.routes++;

    // Inline trips → trips collection
    for (const t of r.trips ?? []) {
      const tripId = `trip_transtu_${r.id.replace('route_transtu_', '')}_${t.tripNumber}`;
      bw.set(db.collection('trips').doc(tripId), {
        routeId:       r.id,
        operatorId:    'transtu',
        tripNumber:    t.tripNumber,
        departureTime: t.departureTime,
        operatingDays: t.operatingDays ?? [0, 1, 2, 3, 4, 5, 6],
        terminatesAt:  t.terminatesAtStationId ?? null,
      });
      await bw.flushIfFull();
      stats.trips++;
    }
  }

  for (const rs of routeStops) {
    const docId = `${rs.routeId}_stop_${rs.stopOrder}_${rs.stationId}`;
    bw.set(db.collection('route_stops').doc(docId), {
      routeId:                     rs.routeId,
      stationId:                   rs.stationId,
      stopOrder:                   rs.stopOrder,
      estimatedArrivalTimeMinutes: rs.estimatedArrivalTimeMinutes ?? 0,
    });
    await bw.flushIfFull();
    stats.routeStops++;
  }
}

// ─── FORMAT B ────────────────────────────────────────────────────────────────

/**
 * Loose-format files have no route IDs, no routeStops, no trips arrays.
 * We synthesise all three so the Firestore schema stays consistent.
 */
async function seedFormatB(d, bw, stats) {
  const { stations = [], routes = [] } = d;

  for (const s of stations) {
    bw.set(db.collection('stations').doc(s.id), {
      name:           s.name,
      nameAr:         s.nameAr ?? s.name,
      cityId:         s.cityId ?? 'tunis',
      latitude:       s.lat ?? s.latitude ?? null,
      longitude:      s.lng ?? s.longitude ?? null,
      isMainHub:      s.isMainHub ?? false,
      transportTypes: ['bus'],
      operatorsHere:  ['transtu'],
    });
    await bw.flushIfFull();
    stats.stations++;
  }

  // Hub = first station with isMainHub=true, or fall back to stations[0]
  const hubStation = stations.find(s => s.isMainHub) ?? stations[0];
  const hubId      = hubStation?.id ?? 'transtu_hub_unknown';
  const hubSlug    = hubId.replace('transtu_hub_', '');
  const hubName    = hubStation?.name ?? hubId;

  for (const r of routes) {
    const lineSlug = slugify(r.lineNumber ?? 'unknown');
    const routeId  = `route_transtu_${hubSlug}_ligne${lineSlug}`;
    const destSlug = slugify(r.destinationAr ?? 'unknown');
    const destId   = `transtu_dest_${destSlug}`;

    bw.set(db.collection('routes').doc(routeId), {
      lineNumber:               r.lineNumber,
      name:                     `${hubName} \u2192 ${r.destinationAr ?? ''}`,
      direction:                'forward',
      operatorId:               'transtu',
      transportType:            'bus',
      originStationId:          hubId,
      destinationStationId:     destId,
      firstDepartureFromHub:    r.firstDepartureHub ?? null,
      lastDepartureFromHub:     r.lastDepartureHub ?? null,
      firstDepartureFromSuburb: r.firstDepartureSuburb ?? null,
      lastDepartureFromSuburb:  r.lastDepartureSuburb ?? null,
      peakFrequencyMinutes:     parsePeakFreq(r.peakFrequency),
      zone:                     'urbaine',
      price:                    0.5,
    });
    await bw.flushIfFull();
    stats.routes++;

    // One representative trip (first departure from hub)
    const firstDep = r.firstDepartureHub ?? r.firstDepartureSuburb;
    if (firstDep) {
      const tripId = `trip_transtu_${hubSlug}_ligne${lineSlug}_1`;
      bw.set(db.collection('trips').doc(tripId), {
        routeId:       routeId,
        operatorId:    'transtu',
        tripNumber:    `${r.lineNumber}_1`,
        departureTime: firstDep,
        operatingDays: [0, 1, 2, 3, 4, 5, 6],
        terminatesAt:  destId,
      });
      await bw.flushIfFull();
      stats.trips++;
    }

    // Two route_stops: hub (order 1) → destination (order 2)
    bw.set(db.collection('route_stops').doc(`${routeId}_stop_1_${hubId}`), {
      routeId, stationId: hubId, stopOrder: 1, estimatedArrivalTimeMinutes: 0,
    });
    bw.set(db.collection('route_stops').doc(`${routeId}_stop_2_${destId}`), {
      routeId, stationId: destId, stopOrder: 2, estimatedArrivalTimeMinutes: null,
    });
    await bw.flushIfFull();
    stats.routeStops += 2;
  }
}

// ─── main ─────────────────────────────────────────────────────────────────────

async function main() {
  const dataDir = path.join(__dirname, 'data');
  const files = fs.readdirSync(dataDir)
    .filter(f => f.startsWith('transtu') && f.endsWith('.json'))
    .sort();

  console.log(`\uD83D\uDE8C Seeding TRANSTU data from ${files.length} JSON files...\n`);

  // Upsert operator doc (cleanup never touches this)
  await db.collection('operators').doc('transtu').set({
    name:      'TRANSTU - Soci\u00e9t\u00e9 de Transport de Tunis',
    shortName: 'TRANSTU',
    phone:     '+216 71 102 000',
    typeId:    'bus',
  }, { merge: true });
  console.log('  \u2713 Operator doc upserted\n');

  const grandStats = { stations: 0, routes: 0, routeStops: 0, trips: 0 };

  for (const file of files) {
    const d     = JSON.parse(fs.readFileSync(path.join(dataDir, file), 'utf8'));
    const bw    = new BatchWriter();
    const stats = { stations: 0, routes: 0, routeStops: 0, trips: 0 };
    const fmt   = isFormatA(d) ? 'A' : 'B';

    if (fmt === 'A') {
      await seedFormatA(d, bw, stats);
    } else {
      await seedFormatB(d, bw, stats);
    }
    await bw.flush();

    console.log(
      `  \u2713 ${file.padEnd(30)} [fmt ${fmt}]` +
      `  stations=${stats.stations}` +
      `  routes=${stats.routes}` +
      `  routeStops=${stats.routeStops}` +
      `  trips=${stats.trips}`
    );

    for (const k of Object.keys(grandStats)) grandStats[k] += stats[k];
  }

  console.log('\n\uD83D\uDCCA Grand total:');
  console.log(`   stations   : ${grandStats.stations}`);
  console.log(`   routes     : ${grandStats.routes}`);
  console.log(`   route_stops: ${grandStats.routeStops}`);
  console.log(`   trips      : ${grandStats.trips}`);
  console.log('\n\u2705 TRANSTU seed complete!\n');
  process.exit(0);
}

main().catch(err => {
  console.error('\u274C Fatal error:', err);
  process.exit(1);
});
