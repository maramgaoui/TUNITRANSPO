import 'package:cloud_firestore/cloud_firestore.dart';

class RouteRepository {
  final FirebaseFirestore _firestore;

  // ── In-memory route_stops cache (H-4 fix) ──────────────────────────────
  final Map<String, List<Map<String, dynamic>>> _routeStopsCache = {};
  static const Duration _routeCacheTtl = Duration(minutes: 15);
  DateTime? _routeCacheTimestamp;

  void invalidateCache() {
    _routeStopsCache.clear();
    _routeCacheTimestamp = null;
  }

  RouteRepository(this._firestore);

  /// Fetches and caches route_stops for a given [referenceRouteId].
  Future<List<Map<String, dynamic>>> _getRouteStops(String referenceRouteId) async {
    final now = DateTime.now();
    if (_routeCacheTimestamp != null &&
        now.difference(_routeCacheTimestamp!) < _routeCacheTtl &&
        _routeStopsCache.containsKey(referenceRouteId)) {
      return _routeStopsCache[referenceRouteId]!;
    }

    final snapshot = await _firestore
        .collection('route_stops')
        .where('routeId', isEqualTo: referenceRouteId)
        .get();

    final docs = snapshot.docs.map((d) => d.data()).toList();
    _routeStopsCache[referenceRouteId] = docs;
    _routeCacheTimestamp = now;
    return docs;
  }

  /// Generic direction resolver: looks up stop orders on [referenceRouteId],
  /// returns [forwardRouteId] or [reverseRouteId] based on travel direction.
  Future<String?> _findDirectionalRouteId({
    required String fromStationId,
    required String toStationId,
    required String referenceRouteId,
    required String forwardRouteId,
    required String reverseRouteId,
  }) async {
    final docs = await _getRouteStops(referenceRouteId);

    int fromOrder = -1;
    int toOrder = -1;

    for (final data in docs) {
      if (data['stationId'] == fromStationId) {
        fromOrder = data['stopOrder'] as int;
      }
      if (data['stationId'] == toStationId) {
        toOrder = data['stopOrder'] as int;
      }
    }

    if (fromOrder == -1 || toOrder == -1) return null;
    if (fromOrder < toOrder) return forwardRouteId;
    if (fromOrder > toOrder) return reverseRouteId;
    return null; // same station
  }

  // ── Public line-specific route finders ──────────────────────────────────

  Future<String?> findMetroSahelRouteId(
    String fromStationId,
    String toStationId,
  ) =>
      _findDirectionalRouteId(
        fromStationId: fromStationId,
        toStationId: toStationId,
        referenceRouteId: 'route_ms_504',
        forwardRouteId: 'route_ms_504',
        reverseRouteId: 'route_ms_503',
      );

  /// Returns the stopOrder of a station on route_ms_504 (1-22).
  /// Returns -1 if not found.
  Future<int> getStopOrder(String stationId) async {
    final docs = await _getRouteStops('route_ms_504');
    for (final data in docs) {
      if (data['stationId'] == stationId) {
        return data['stopOrder'] as int;
      }
    }
    return -1;
  }

  Future<String?> findBanlieueSudRouteId(
    String fromStationId,
    String toStationId,
  ) =>
      _findDirectionalRouteId(
        fromStationId: fromStationId,
        toStationId: toStationId,
        referenceRouteId: 'route_bs_south',
        forwardRouteId: 'route_bs_south',
        reverseRouteId: 'route_bs_north',
      );

  /// Returns the stopOrder and estimatedArrivalTimeMinutes for a
  /// station on route_bs_south. Returns null if not found.
  Future<Map<String, int>?> getBSStopInfo(String stationId) async {
    final docs = await _getRouteStops('route_bs_south');
    for (final data in docs) {
      if (data['stationId'] == stationId) {
        return {
          'stopOrder': data['stopOrder'] as int,
          'minutes': (data['estimatedArrivalTimeMinutes'] ?? 0) as int,
        };
      }
    }
    return null;
  }

  Future<String?> findBanlieueERouteId(
    String fromStationId,
    String toStationId,
  ) =>
      _findDirectionalRouteId(
        fromStationId: fromStationId,
        toStationId: toStationId,
        referenceRouteId: 'route_line_e_forward',
        forwardRouteId: 'route_line_e_forward',
        reverseRouteId: 'route_line_e_reverse',
      );

  Future<String?> findBanlieueDRouteId(
    String fromStationId,
    String toStationId,
  ) =>
      _findDirectionalRouteId(
        fromStationId: fromStationId,
        toStationId: toStationId,
        referenceRouteId: 'route_rd_line_d_forward',
        forwardRouteId: 'route_rd_line_d_forward',
        reverseRouteId: 'route_rd_line_d_reverse',
      );

  Future<String?> findSncftL5RouteId(
    String fromStationId,
    String toStationId,
  ) =>
      _findDirectionalRouteId(
        fromStationId: fromStationId,
        toStationId: toStationId,
        referenceRouteId: 'route_sncft_l5_forward',
        forwardRouteId: 'route_sncft_l5_forward',
        reverseRouteId: 'route_sncft_l5_reverse',
      );

  Future<String?> findSncftRedeyefRouteId(
    String fromStationId,
    String toStationId,
  ) =>
      _findDirectionalRouteId(
        fromStationId: fromStationId,
        toStationId: toStationId,
        referenceRouteId: 'route_sncft_redeyef_forward',
        forwardRouteId: 'route_sncft_redeyef_forward',
        reverseRouteId: 'route_sncft_redeyef_reverse',
      );

  Future<String?> findSncftKefRouteId(
    String fromStationId,
    String toStationId,
  ) =>
      _findDirectionalRouteId(
        fromStationId: fromStationId,
        toStationId: toStationId,
        referenceRouteId: 'route_sncft_kef_forward',
        forwardRouteId: 'route_sncft_kef_forward',
        reverseRouteId: 'route_sncft_kef_reverse',
      );

  Future<String?> findBanlieueNabeulRouteId(
    String fromStationId,
    String toStationId,
  ) =>
      _findDirectionalRouteId(
        fromStationId: fromStationId,
        toStationId: toStationId,
        referenceRouteId: 'route_bn_forward',
        forwardRouteId: 'route_bn_forward',
        reverseRouteId: 'route_bn_reverse',
      );

  Future<String?> findSncftGlAnnabaRouteId(
    String fromStationId,
    String toStationId,
  ) =>
      _findDirectionalRouteId(
        fromStationId: fromStationId,
        toStationId: toStationId,
        referenceRouteId: 'route_sncft_gl_annaba_forward',
        forwardRouteId: 'route_sncft_gl_annaba_forward',
        reverseRouteId: 'route_sncft_gl_annaba_reverse',
      );

  Future<String?> findSncftGlBizerteRouteId(
    String fromStationId,
    String toStationId,
  ) =>
      _findDirectionalRouteId(
        fromStationId: fromStationId,
        toStationId: toStationId,
        referenceRouteId: 'route_sncft_gl_bizerte_forward',
        forwardRouteId: 'route_sncft_gl_bizerte_forward',
        reverseRouteId: 'route_sncft_gl_bizerte_reverse',
      );
}
