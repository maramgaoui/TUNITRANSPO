import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/metro_sahel_result.dart';
import '../models/tariff_model.dart';
import 'route_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Configuration object — one per line type.
//  All the per-line differences live here; the core search algorithm is shared.
// ─────────────────────────────────────────────────────────────────────────────

/// Resolves the Firestore routeId for a given (from, to) pair.
typedef RouteIdResolver = Future<String?> Function(
  String fromStationId,
  String toStationId,
);

/// Computes the fare given the resolved stop/section metadata.
typedef FareCalculator = double Function(_StopMeta from, _StopMeta to);

/// Metadata extracted from a single `route_stops` document.
class _StopMeta {
  final int offset;   // estimatedArrivalTimeMinutes from route origin
  final int order;    // stopOrder
  final int section;  // section number (used for section-based fares)

  const _StopMeta({
    required this.offset,
    required this.order,
    required this.section,
  });
}

/// Per-line static configuration.
class _LineConfig {
  final String lineType;
  final String operatorName;
  final String operatorPhone;
  /// First departure fallback shown when no trip is found today.
  final String fallbackFirstDeparture;
  final RouteIdResolver resolveRouteId;
  final FareCalculator calculateFare;
  /// Whether trips may have partial-origin / partial-destination overrides
  /// (only needed for SNCFT mainline long-distance trains).
  final bool supportsPartialTrips;

  const _LineConfig({
    required this.lineType,
    required this.operatorName,
    required this.operatorPhone,
    required this.fallbackFirstDeparture,
    required this.resolveRouteId,
    required this.calculateFare,
    this.supportsPartialTrips = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Repository
// ─────────────────────────────────────────────────────────────────────────────

class JourneyRepository {
  final FirebaseFirestore _firestore;
  final RouteRepository _routeRepository;

  JourneyRepository(this._firestore, this._routeRepository);

  // ── Public API — one thin wrapper per line type ───────────────────────────

  Future<MetroSahelResult?> findNextMetroSahelTrip({
    required String fromStationId,
    required String toStationId,
    required DateTime searchDateTime,
  }) =>
      _findNextMetroSahelTripInternal(
        fromStationId: fromStationId,
        toStationId: toStationId,
        searchDateTime: searchDateTime,
      );

  Future<MetroSahelResult?> findNextBanlieueSudTrip({
    required String fromStationId,
    required String toStationId,
    required DateTime searchDateTime,
  }) =>
      _findNextOffsetBasedTrip(
        fromStationId: fromStationId,
        toStationId: toStationId,
        searchDateTime: searchDateTime,
        config: _LineConfig(
          lineType: 'banlieue_sud',
          operatorName: 'Trains des Banlieues sud et ouest de Tunis',
          operatorPhone: '+216 71 337 000',
          fallbackFirstDeparture: '04:35',
          resolveRouteId: (f, t) =>
              _routeRepository.findBanlieueSudRouteId(f, t),
          calculateFare: (from, to) {
            final sectionsTraveled = (from.section - to.section).abs() + 1;
            return _bsFare(sectionsTraveled);
          },
        ),
      );

  Future<MetroSahelResult?> findNextBanlieueETrip({
    required String fromStationId,
    required String toStationId,
    required DateTime searchDateTime,
  }) =>
      _findNextOffsetBasedTrip(
        fromStationId: fromStationId,
        toStationId: toStationId,
        searchDateTime: searchDateTime,
        config: _LineConfig(
          lineType: 'banlieue_e',
          operatorName: 'Trains des Banlieues sud et ouest de Tunis',
          operatorPhone: '+216 71 334 444',
          fallbackFirstDeparture: '04:40',
          resolveRouteId: (f, t) =>
              _routeRepository.findBanlieueERouteId(f, t),
          calculateFare: (from, to) => 0.700,
        ),
      );

  Future<MetroSahelResult?> findNextBanlieueDTrip({
    required String fromStationId,
    required String toStationId,
    required DateTime searchDateTime,
  }) =>
      _findNextOffsetBasedTrip(
        fromStationId: fromStationId,
        toStationId: toStationId,
        searchDateTime: searchDateTime,
        config: _LineConfig(
          lineType: 'banlieue_d',
          operatorName: 'Trains des Banlieues sud et ouest de Tunis',
          operatorPhone: '+216 71 334 444',
          fallbackFirstDeparture: '04:10',
          resolveRouteId: (f, t) =>
              _routeRepository.findBanlieueDRouteId(f, t),
          calculateFare: (from, to) => 0.700,
        ),
      );

  Future<MetroSahelResult?> findNextBanlieueNabeulTrip({
    required String fromStationId,
    required String toStationId,
    required DateTime searchDateTime,
  }) =>
      _findNextOffsetBasedTrip(
        fromStationId: fromStationId,
        toStationId: toStationId,
        searchDateTime: searchDateTime,
        config: _LineConfig(
          lineType: 'banlieue_nabeul',
          operatorName: 'SNCFT - Banlieue de Nabeul',
          operatorPhone: '+216 71 334 444',
          fallbackFirstDeparture: '06:15',
          resolveRouteId: (f, t) =>
              _routeRepository.findBanlieueNabeulRouteId(f, t),
          calculateFare: (from, to) =>
              _bnFare((from.order - to.order).abs()),
        ),
      );

  Future<MetroSahelResult?> findNextSncftL5Trip({
    required String fromStationId,
    required String toStationId,
    required DateTime searchDateTime,
  }) =>
      _findNextOffsetBasedTrip(
        fromStationId: fromStationId,
        toStationId: toStationId,
        searchDateTime: searchDateTime,
        config: _LineConfig(
          lineType: 'sncft_mainline',
          operatorName: 'SNCFT – Société Nationale des Chemins de Fer Tunisiens',
          operatorPhone: '+216 71 334 444',
          fallbackFirstDeparture: '07:35',
          resolveRouteId: (f, t) async =>
              await _routeRepository.findSncftL5RouteId(f, t) ??
              await _routeRepository.findSncftRedeyefRouteId(f, t) ??
              await _routeRepository.findSncftKefRouteId(f, t) ??
              await _routeRepository.findSncftGlAnnabaRouteId(f, t) ??
              await _routeRepository.findSncftGlBizerteRouteId(f, t),
          calculateFare: (from, to) =>
              _sncftL5Fare(_sncftFromId, _sncftToId),
          supportsPartialTrips: true,
        ),
      );

  // ── Metro Sahel — kept separate due to its unique stop-order lookup ────────
  //
  // Metro Sahel uses RouteRepository.getStopOrder() rather than route_stops
  // offsets, and uses a per-stop duration model (numberOfStops * 4 min).
  // Every other line uses the offset-based model in _findNextOffsetBasedTrip.

  Future<MetroSahelResult?> _findNextMetroSahelTripInternal({
    required String fromStationId,
    required String toStationId,
    required DateTime searchDateTime,
  }) async {
    final routeId = await _routeRepository.findMetroSahelRouteId(
      fromStationId,
      toStationId,
    );
    if (routeId == null) return null;

    final fromDoc =
        await _firestore.collection('stations').doc(fromStationId).get();
    final toDoc =
        await _firestore.collection('stations').doc(toStationId).get();
    final fromName = fromDoc.data()?['name'] ?? fromStationId;
    final toName = toDoc.data()?['name'] ?? toStationId;

    final fromOrder = await _routeRepository.getStopOrder(fromStationId);
    final toOrder = await _routeRepository.getStopOrder(toStationId);
    if (fromOrder == -1 || toOrder == -1) return null;

    final numberOfStops = (toOrder - fromOrder).abs();
    if (numberOfStops == 0) return null;

    final price = Tariff.calculateMetroSahelPrice(numberOfStops);
    final durationMinutes = numberOfStops * 4;
    final routeName = '$fromName → $toName';

    final dayOfWeek = searchDateTime.weekday % 7;
    final tripsSnapshot = await _firestore
        .collection('trips')
        .where('routeId', isEqualTo: routeId)
        .where('daysOfWeek', arrayContains: dayOfWeek)
        .get();

    if (tripsSnapshot.docs.isEmpty) return null;

    final searchMinutes = searchDateTime.hour * 60 + searchDateTime.minute;
    final candidates = <Map<String, dynamic>>[];
    String? firstDepartureOfDay;
    int firstDepartureMinutes = 99999;

    for (final doc in tripsSnapshot.docs) {
      final data = doc.data();
      final depTimestamp = data['departureTime'] as Timestamp?;
      if (depTimestamp == null) continue;

      final depDate = depTimestamp.toDate();
      final tripMinutes = depDate.hour * 60 + depDate.minute;
      final timeStr =
          '${depDate.hour.toString().padLeft(2, '0')}:${depDate.minute.toString().padLeft(2, '0')}';

      if (tripMinutes < firstDepartureMinutes) {
        firstDepartureMinutes = tripMinutes;
        firstDepartureOfDay = timeStr;
      }
      if (tripMinutes >= searchMinutes) {
        candidates.add({...data, '_minutes': tripMinutes, '_timeStr': timeStr});
      }
    }

    if (candidates.isEmpty) {
      final dep = firstDepartureOfDay ?? '05:48';
      return _assembleResult(
        departureTime: dep,
        arrivalTime: 'TOMORROW',
        tripNumber: 0,
        routeName: routeName,
        fromStationId: fromStationId,
        toStationId: toStationId,
        fromStationName: fromName,
        toStationName: toName,
        durationMinutes: durationMinutes,
        price: price,
        numberOfStops: numberOfStops,
      );
    }

    candidates.sort(
        (a, b) => (a['_minutes'] as int).compareTo(b['_minutes'] as int));
    final next = candidates.first;
    final dep = next['_timeStr'] as String;
    final depMin = _parseMinutes(dep);
    final rawArr = depMin + durationMinutes;
    final arrStr =
        '${_minutesToTime(rawArr % 1440)}${rawArr >= 1440 ? ' (+1)' : ''}';

    return _assembleResult(
      departureTime: dep,
      arrivalTime: arrStr,
      tripNumber: next['tripNumber'] as int? ?? 0,
      routeName: routeName,
      fromStationId: fromStationId,
      toStationId: toStationId,
      fromStationName: fromName,
      toStationName: toName,
      durationMinutes: durationMinutes,
      price: price,
      numberOfStops: numberOfStops,
    );
  }

  // ── Generic offset-based trip finder (shared by all other line types) ─────

  // Temporary fields used only during SNCFT fare resolution (see note below).
  String _sncftFromId = '';
  String _sncftToId = '';

  Future<MetroSahelResult?> _findNextOffsetBasedTrip({
    required String fromStationId,
    required String toStationId,
    required DateTime searchDateTime,
    required _LineConfig config,
  }) async {
    // Capture IDs for the SNCFT fare closure (which needs the original IDs).
    _sncftFromId = fromStationId;
    _sncftToId = toStationId;

    final routeId =
        await config.resolveRouteId(fromStationId, toStationId);
    if (routeId == null) return null;

    // ── 1. Station names ────────────────────────────────────────────────────
    final fromDoc =
        await _firestore.collection('stations').doc(fromStationId).get();
    final toDoc =
        await _firestore.collection('stations').doc(toStationId).get();
    final fromName = (fromDoc.data()?['name'] as String?) ?? fromStationId;
    final toName = (toDoc.data()?['name'] as String?) ?? toStationId;

    // ── 2. Stop offsets & orders ────────────────────────────────────────────
    final routeStopsSnap = await _firestore
        .collection('route_stops')
        .where('routeId', isEqualTo: routeId)
        .get();

    _StopMeta? fromMeta;
    _StopMeta? toMeta;
    final stationOrderMap = <String, int>{}; // used for SNCFT partial-trips

    for (final doc in routeStopsSnap.docs) {
      final data = doc.data();
      final sid = data['stationId'] as String;
      final order = data['stopOrder'] as int;
      stationOrderMap[sid] = order;

      final offset = (data['estimatedArrivalTimeMinutes'] ?? 0) as int;
      final section = (data['section'] as int?) ??
          _sectionFromOrder(order);

      if (sid == fromStationId) {
        fromMeta = _StopMeta(offset: offset, order: order, section: section);
      }
      if (sid == toStationId) {
        toMeta = _StopMeta(offset: offset, order: order, section: section);
      }
    }

    // Also pick up sections from the station docs themselves (Banlieue Sud).
    final fromSection =
        (fromDoc.data()?['section'] as int?) ?? fromMeta?.section ?? 1;
    final toSection =
        (toDoc.data()?['section'] as int?) ?? toMeta?.section ?? 1;
    if (fromMeta != null) {
      fromMeta = _StopMeta(
          offset: fromMeta.offset, order: fromMeta.order, section: fromSection);
    }
    if (toMeta != null) {
      toMeta = _StopMeta(
          offset: toMeta.offset, order: toMeta.order, section: toSection);
    }

    if (fromMeta == null || toMeta == null) return null;

    final numberOfStops = (fromMeta.order - toMeta.order).abs();
    if (numberOfStops == 0) return null;

    final durationMinutes = (fromMeta.offset - toMeta.offset).abs();
    final price = config.calculateFare(fromMeta, toMeta);
    final routeName = '$fromName → $toName';

    // ── 3. Query trips for today's day-of-week ──────────────────────────────
    final dayOfWeek = searchDateTime.weekday % 7;
    final tripsSnapshot = await _firestore
        .collection('trips')
        .where('routeId', isEqualTo: routeId)
        .where('daysOfWeek', arrayContains: dayOfWeek)
        .get();

    if (tripsSnapshot.docs.isEmpty) return null;

    final searchMinutes = searchDateTime.hour * 60 + searchDateTime.minute;
    final candidates = <Map<String, dynamic>>[];
    int firstDepAtFrom = 99999;

    // ── 4. Filter candidates ────────────────────────────────────────────────
    for (final doc in tripsSnapshot.docs) {
      final data = doc.data();
      final depTimestamp = data['departureTime'] as Timestamp?;
      if (depTimestamp == null) continue;

      if (config.supportsPartialTrips) {
        // Skip trips that terminate before destination.
        final terminatesAt = data['terminatesAtStationId'] as String?;
        if (terminatesAt != null) {
          final terminateOrder = stationOrderMap[terminatesAt];
          if (terminateOrder != null && toMeta!.order > terminateOrder) {
            continue;
          }
        }
        // Skip trips whose origin is after our boarding stop.
        final originStId = data['originStationId'] as String?;
        if (originStId != null) {
          final originOrder = stationOrderMap[originStId];
          if (originOrder != null && fromMeta!.order < originOrder) continue;
        }
      }

      final depDate = depTimestamp.toDate();
      final originMinutes = depDate.hour * 60 + depDate.minute;
      final actualDep = config.supportsPartialTrips
          ? _resolveStationMinute(data, fromStationId, originMinutes, fromMeta!.offset)
          : originMinutes + fromMeta!.offset;

      if (actualDep < firstDepAtFrom) firstDepAtFrom = actualDep;

      if (actualDep >= searchMinutes) {
        candidates.add({
          ...data,
          '_actualDep': actualDep,
          '_originMin': originMinutes,
        });
      }
    }

    // ── 5. No trip today → return next-day first departure ─────────────────
    if (candidates.isEmpty) {
      final firstDep = firstDepAtFrom < 99999
          ? _minutesToTime(firstDepAtFrom)
          : config.fallbackFirstDeparture;
      final rawArr = _parseMinutes(firstDep) + durationMinutes;
      return _assembleResult(
        departureTime: firstDep,
        arrivalTime: 'TOMORROW',
        tripNumber: 0,
        tripNumberStr: config.supportsPartialTrips ? '–' : null,
        routeName: routeName,
        fromStationId: fromStationId,
        toStationId: toStationId,
        fromStationName: fromName,
        toStationName: toName,
        durationMinutes: durationMinutes,
        price: price,
        numberOfStops: numberOfStops,
        operatorName: config.operatorName,
        operatorPhone: config.operatorPhone,
        lineType: config.lineType,
      );
    }

    // ── 6. Sort and pick the next departure ─────────────────────────────────
    candidates.sort(
        (a, b) => (a['_actualDep'] as int).compareTo(b['_actualDep'] as int));

    final next = candidates.first;
    final actualDep = next['_actualDep'] as int;

    int rawActualArr;
    if (config.supportsPartialTrips) {
      final originMin = next['_originMin'] as int;
      rawActualArr = _resolveStationMinute(
          next, toStationId, originMin, toMeta!.offset);
    } else {
      rawActualArr = actualDep + durationMinutes;
    }

    final actualArr = rawActualArr % 1440;
    final crossesMidnight = rawActualArr >= 1440;
    final actualDuration = config.supportsPartialTrips
        ? (rawActualArr >= actualDep
            ? rawActualArr - actualDep
            : rawActualArr - actualDep + 1440)
        : durationMinutes;

    return _assembleResult(
      departureTime: _minutesToTime(actualDep),
      arrivalTime:
          '${_minutesToTime(actualArr)}${crossesMidnight ? ' (+1)' : ''}',
      tripNumber: config.supportsPartialTrips
          ? 0
          : (next['tripNumber'] as int? ?? 0),
      tripNumberStr: config.supportsPartialTrips
          ? (next['tripNumber'] as String? ?? '–')
          : null,
      routeName: routeName,
      fromStationId: fromStationId,
      toStationId: toStationId,
      fromStationName: fromName,
      toStationName: toName,
      durationMinutes: actualDuration,
      price: price,
      numberOfStops: numberOfStops,
      operatorName: config.operatorName,
      operatorPhone: config.operatorPhone,
      lineType: config.lineType,
    );
  }

  // ── Shared result assembler ───────────────────────────────────────────────

  MetroSahelResult _assembleResult({
    required String departureTime,
    required String arrivalTime,
    required int tripNumber,
    String? tripNumberStr,
    required String routeName,
    required String fromStationId,
    required String toStationId,
    required String fromStationName,
    required String toStationName,
    required int durationMinutes,
    required double price,
    required int numberOfStops,
    String operatorName = 'Métro du Sahel - SNCFT',
    String operatorPhone = '+216 73 447 425',
    String lineType = 'metro_sahel',
  }) {
    return MetroSahelResult(
      tripNumber: tripNumber,
      tripNumberStr: tripNumberStr,
      routeName: routeName,
      fromStationId: fromStationId,
      toStationId: toStationId,
      fromStationName: fromStationName,
      toStationName: toStationName,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      durationMinutes: durationMinutes,
      price: price,
      numberOfStops: numberOfStops,
      operatorName: operatorName,
      operatorPhone: operatorPhone,
      lineType: lineType,
    );
  }

  // ── SNCFT per-station time override ──────────────────────────────────────

  /// Returns the per-station scheduled minute if an override exists in the
  /// trip document, otherwise falls back to originMinutes + routeOffset.
  static int _resolveStationMinute(
    Map<String, dynamic> tripData,
    String stationId,
    int originMinutes,
    int routeOffset,
  ) {
    final overrides = tripData['stationTimeOverridesMinutes'];
    if (overrides is Map<String, dynamic>) {
      final raw = overrides[stationId];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
    }
    return originMinutes + routeOffset;
  }

  // ── Time utilities ────────────────────────────────────────────────────────

  int _parseMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _minutesToTime(int minutes) {
    final m = minutes % 1440;
    return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }

  // ── Fare calculators ──────────────────────────────────────────────────────

  /// Banlieue Sud: section-based fare.
  static double _bsFare(int sections) {
    if (sections <= 2) return 0.500;
    if (sections <= 4) return 1.000;
    if (sections <= 6) return 1.450;
    return 1.900;
  }

  /// Banlieue de Nabeul: stop-count-based fare.
  static double _bnFare(int numberOfStops) {
    if (numberOfStops <= 2) return 1.500;
    if (numberOfStops <= 4) return 2.500;
    if (numberOfStops <= 6) return 4.000;
    return 5.500;
  }

  /// Fallback section from stop order when the station doc has no section field.
  static int _sectionFromOrder(int order) {
    if (order <= 3) return 1;
    if (order <= 6) return 2;
    if (order <= 9) return 3;
    if (order <= 12) return 4;
    if (order <= 14) return 5;
    if (order <= 16) return 6;
    if (order <= 18) return 7;
    return 8;
  }



  /// SNCFT: known pair lookup with distance-band fallback.
  static double _sncftL5Fare(String fromId, String toId) {
    const fares = {
      'bs_tunis_ville|sncft_sfax': 20.000,
      'sncft_sfax|bs_tunis_ville': 20.000,
      'bs_tunis_ville|sncft_metlaoui': 10.000,
      'sncft_metlaoui|bs_tunis_ville': 10.000,
      'bs_tunis_ville|sncft_tozeur': 25.000,
      'sncft_tozeur|bs_tunis_ville': 25.000,
      'bs_tunis_ville|sncft_sousse_voyageurs': 9.000,
      'sncft_sousse_voyageurs|bs_tunis_ville': 9.000,
      'bs_tunis_ville|sncft_gabes': 18.000,
      'sncft_gabes|bs_tunis_ville': 18.000,
      'bs_tunis_ville|sncft_gafsa': 22.000,
      'sncft_gafsa|bs_tunis_ville': 22.000,
      'sncft_sfax|sncft_gabes': 7.000,
      'sncft_gabes|sncft_sfax': 7.000,
      'sncft_sfax|sncft_tozeur': 15.000,
      'sncft_tozeur|sncft_sfax': 15.000,
      'sncft_sousse_voyageurs|sncft_sfax': 12.000,
      'sncft_sfax|sncft_sousse_voyageurs': 12.000,
      // Grandes Lignes – Annaba
      'bs_tunis_ville|sncft_beja': 5.600,
      'sncft_beja|bs_tunis_ville': 5.600,
      'bs_tunis_ville|sncft_jendouba': 8.200,
      'sncft_jendouba|bs_tunis_ville': 8.200,
      'bs_tunis_ville|sncft_ghardimaou': 9.800,
      'sncft_ghardimaou|bs_tunis_ville': 9.800,
      'bs_tunis_ville|sncft_souk_ahras': 15.000,
      'sncft_souk_ahras|bs_tunis_ville': 15.000,
      // International route (2nd class, one-way): Tunis <-> Annaba.
      'bs_tunis_ville|sncft_annaba': 38.000,
      'sncft_annaba|bs_tunis_ville': 38.000,
      'sncft_beja|sncft_jendouba': 3.500,
      'sncft_jendouba|sncft_beja': 3.500,
      'sncft_beja|sncft_ghardimaou': 5.000,
      'sncft_ghardimaou|sncft_beja': 5.000,
      'sncft_jendouba|sncft_ghardimaou': 2.500,
      'sncft_ghardimaou|sncft_jendouba': 2.500,
      // Grandes Lignes – Bizerte
      'bs_tunis_ville|sncft_mateur': 4.500,
      'sncft_mateur|bs_tunis_ville': 4.500,
      'bs_tunis_ville|sncft_bizerte': 6.800,
      'sncft_bizerte|bs_tunis_ville': 6.800,
      // SNCFT Kef / Kalaa Khasba (approx. 2nd class)
      'bs_tunis_ville|sncft_kef_gaafour': 6.500,
      'sncft_kef_gaafour|bs_tunis_ville': 6.500,
      'bs_tunis_ville|sncft_kef_dahmani': 9.000,
      'sncft_kef_dahmani|bs_tunis_ville': 9.000,
      'bs_tunis_ville|sncft_kef_le_kef': 10.200,
      'sncft_kef_le_kef|bs_tunis_ville': 10.200,
      'bs_tunis_ville|sncft_kef_kalaa_khasba': 11.500,
      'sncft_kef_kalaa_khasba|bs_tunis_ville': 11.500,
      'sncft_kef_gaafour|sncft_kef_le_kef': 6.000,
      'sncft_kef_le_kef|sncft_kef_gaafour': 6.000,
      'sncft_kef_dahmani|sncft_kef_le_kef': 3.000,
      'sncft_kef_le_kef|sncft_kef_dahmani': 3.000,
    };
    return fares['$fromId|$toId'] ?? 5.000;
  }
}
