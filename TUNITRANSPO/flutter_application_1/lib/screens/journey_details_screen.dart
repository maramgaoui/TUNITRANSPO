import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/widgets/time_text.dart';
import '../controllers/favorites_controller.dart';
import '../services/active_journey_service.dart';
import '../theme/app_theme.dart';
import '../models/journey_model.dart';
import '../models/metro_sahel_result.dart';

class JourneyDetailsScreen extends StatefulWidget {
  final Journey? journey;
  final MetroSahelResult? metroResult;

  const JourneyDetailsScreen({
    super.key,
    this.journey,
    this.metroResult,
  }) : assert(journey != null || metroResult != null);

  @override
  State<JourneyDetailsScreen> createState() => _JourneyDetailsScreenState();
}

class _JourneyDetailsScreenState extends State<JourneyDetailsScreen> {
  late MapController _mapController;
  late Journey _journey;
  List<_StopInfo> _intermediateStops = [];
  bool _stopsLoading = true;

  /// True when this details screen is showing a TRANSTU bus journey.
  bool get _isTranstuBus =>
      widget.journey != null && widget.journey!.type == 'Bus TRANSTU';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _journey = widget.journey ?? widget.metroResult!.toJourney();
    if (widget.metroResult != null) {
      _loadIntermediateStops();
    } else {
      // Bus or generic journey: no route_stops to load.
      _stopsLoading = false;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadIntermediateStops() async {
    try {
      final metro = widget.metroResult!;
      final db = FirebaseFirestore.instance;

      String routeId;
      if (metro.lineType == 'banlieue_sud') {
        routeId = metro.tripNumber.isEven ? 'route_bs_north' : 'route_bs_south';
      } else if (metro.lineType == 'banlieue_d') {
        routeId = metro.tripNumber.isEven
            ? 'route_rd_line_d_reverse'
            : 'route_rd_line_d_forward';
      } else if (metro.lineType == 'banlieue_e') {
        routeId = metro.tripNumber.isEven
            ? 'route_line_e_reverse'
            : 'route_line_e_forward';
      } else if (metro.lineType == 'banlieue_nabeul') {
        routeId = metro.tripNumber.isEven
            ? 'route_bn_reverse'
            : 'route_bn_forward';
      } else if (metro.lineType == 'sncft_mainline') {
        final resolvedRouteId = await _resolveSncftMainlineRouteId(metro);
        if (resolvedRouteId == null) {
          setState(() => _stopsLoading = false);
          return;
        }
        routeId = resolvedRouteId;
      } else {
        routeId =
            metro.tripNumber.isEven ? 'route_ms_504' : 'route_ms_503';
      }

      final routeStops = await db
          .collection('route_stops')
          .where('routeId', isEqualTo: routeId)
          .get();

      int fromOrder = -1;
      int toOrder = -1;
      final orderToStationId = <int, String>{};
      final orderToMinutes = <int, int>{};

      for (final doc in routeStops.docs) {
        final data = doc.data();
        final stationId = data['stationId'] as String;
        final order = data['stopOrder'] as int;
        orderToStationId[order] = stationId;
        orderToMinutes[order] =
            (data['estimatedArrivalTimeMinutes'] ?? 0) as int;
        if (stationId == metro.fromStationId) fromOrder = order;
        if (stationId == metro.toStationId) toOrder = order;
      }

      if (fromOrder == -1 || toOrder == -1) {
        setState(() => _stopsLoading = false);
        return;
      }

      final start = fromOrder < toOrder ? fromOrder : toOrder;
      final end = fromOrder < toOrder ? toOrder : fromOrder;
      final orderedKeys = <int>[];
      for (int i = start; i <= end; i++) {
        if (orderToStationId.containsKey(i)) orderedKeys.add(i);
      }
      if (fromOrder > toOrder) {
        orderedKeys.sort((a, b) => b.compareTo(a));
      }

      final stationFutures = orderedKeys.map((o) =>
          db.collection('stations').doc(orderToStationId[o]!).get());
      final stationDocs = await Future.wait(stationFutures);

      final stops = <_StopInfo>[];
      final depMinutes = _parseMinutes(metro.departureTime);
      final baseOffset = orderToMinutes[fromOrder] ?? 0;

      for (int i = 0; i < orderedKeys.length; i++) {
        final data = stationDocs[i].data();
        if (data == null) continue;

        final offset = (orderToMinutes[orderedKeys[i]] ?? 0) - baseOffset;
        final arrMinutes = depMinutes + offset;
        final timeStr =
            '${(arrMinutes ~/ 60).toString().padLeft(2, '0')}:${(arrMinutes % 60).toString().padLeft(2, '0')}';

        stops.add(_StopInfo(
          name: data['name'] ?? orderToStationId[orderedKeys[i]]!,
          time: timeStr,
          lat: (data['latitude'] ?? 0.0).toDouble(),
          lng: (data['longitude'] ?? 0.0).toDouble(),
        ));
      }

      if (mounted) {
        setState(() {
          _intermediateStops = stops;
          _stopsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _stopsLoading = false);
    }
  }

  int _parseMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  LatLng _getCoordinates() {
    if (_intermediateStops.isNotEmpty) {
      final first = _intermediateStops.first;
      final last = _intermediateStops.last;
      return LatLng((first.lat + last.lat) / 2, (first.lng + last.lng) / 2);
    }
    final name = _journey.departureStation.toLowerCase();
    if (name.contains('mahdia')) return const LatLng(35.5047, 11.0622);
    if (name.contains('monastir')) return const LatLng(35.7441, 10.8081);
    if (name.contains('sousse')) return const LatLng(35.8256, 10.6369);
    return const LatLng(35.66, 10.85);
  }

  double _getZoom() {
    if (_intermediateStops.length <= 3) return 13.0;
    if (_intermediateStops.length <= 8) return 11.0;
    return 10.0;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    if (_intermediateStops.isEmpty) return markers;

    markers.add(Marker(
      point:
          LatLng(_intermediateStops.first.lat, _intermediateStops.first.lng),
      width: 80,
      height: 80,
      child: _markerWidget(Colors.green, Icons.play_arrow, 'Départ'),
    ));

    for (int i = 1; i < _intermediateStops.length - 1; i++) {
      final stop = _intermediateStops[i];
      markers.add(Marker(
        point: LatLng(stop.lat, stop.lng),
        width: 14,
        height: 14,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFF8C00),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ));
    }

    markers.add(Marker(
      point:
          LatLng(_intermediateStops.last.lat, _intermediateStops.last.lng),
      width: 80,
      height: 80,
      child: _markerWidget(Colors.red, Icons.stop, 'Arrivée'),
    ));

    return markers;
  }

  Widget _markerWidget(Color color, IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  List<Polyline> _buildPolylines() {
    if (_intermediateStops.length < 2) return [];
    return [
      Polyline(
        points:
            _intermediateStops.map((s) => LatLng(s.lat, s.lng)).toList(),
        color: const Color(0xFF1A3A6B),
        strokeWidth: 3.0,
      ),
    ];
  }

  Future<void> _shareJourney() async {
    final metro = widget.metroResult;
    final shareText = StringBuffer();

    if (metro != null) {
      shareText
        ..writeln('🚆 ${metro.operatorName}')
        ..writeln('${metro.fromStationName} → ${metro.toStationName}')
        ..writeln('Train N°${metro.tripNumberStr ?? metro.tripNumber}')
        ..writeln('Départ: ${metro.departureTime}')
        ..writeln(
            'Arrivée: ${metro.noTrainToday ? "Demain" : metro.arrivalTime}')
        ..writeln('Durée: ${metro.durationMinutes} min')
        ..writeln('Prix: ${metro.price.toStringAsFixed(3)} TND')
        ..writeln('Arrêts: ${metro.numberOfStops}')
        ..writeln('☎️ ${metro.operatorPhone}');
    } else {
      final j = _journey;
      shareText
        ..writeln('🚌 Bus TRANSTU – ${j.line}')
        ..writeln('${j.departureStation} → ${j.arrivalStation}')
        ..writeln('Premier départ: ${j.departureTime}')
        ..writeln(
            j.duration.isNotEmpty ? j.duration : '')
        ..writeln('Prix: ${j.price} TND');
    }

    try {
      await Share.share(shareText.toString());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de partager ce trajet.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _callOperator() async {
    final metroResult = widget.metroResult;
    if (metroResult == null) return;
    final uri = Uri(scheme: 'tel', path: metroResult.operatorPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<String?> _resolveSncftMainlineRouteId(MetroSahelResult metro) async {
    final db = FirebaseFirestore.instance;
    const candidateRoutes = [
      'route_sncft_l5_forward',
      'route_sncft_l5_reverse',
      'route_sncft_redeyef_forward',
      'route_sncft_redeyef_reverse',
      'route_sncft_kef_forward',
      'route_sncft_kef_reverse',
      'route_sncft_gl_annaba_forward',
      'route_sncft_gl_annaba_reverse',
      'route_sncft_gl_bizerte_forward',
      'route_sncft_gl_bizerte_reverse',
    ];

    String? fallbackRouteId;
    for (final candidateRouteId in candidateRoutes) {
      final routeStops = await db
          .collection('route_stops')
          .where('routeId', isEqualTo: candidateRouteId)
          .get();

      int? fromOrder;
      int? toOrder;
      for (final doc in routeStops.docs) {
        final data = doc.data();
        final sid = data['stationId'] as String;
        final order = data['stopOrder'] as int;
        if (sid == metro.fromStationId) fromOrder = order;
        if (sid == metro.toStationId) toOrder = order;
      }

      if (fromOrder != null && toOrder != null) {
        if (fromOrder < toOrder) return candidateRouteId;
        fallbackRouteId ??= candidateRouteId;
      }
    }
    return fallbackRouteId;
  }

  // ── Bus details panel ─────────────────────────────────────────────────────

  Widget _buildBusDetailsPanel() {
    final j = _journey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations de la ligne',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.directions_bus,
            title: 'Ligne',
            value: j.line,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.my_location,
            title: 'Hub de départ',
            value: j.departureStation,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.place_outlined,
            title: 'Destination',
            value: j.arrivalStation,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.access_time,
            title: 'Premier départ',
            value: j.departureTime,
          ),
          const SizedBox(height: 12),
          if ((j.arrivalTime ?? '').isNotEmpty)
            _buildInfoCard(
              icon: Icons.access_time_filled,
              title: 'Dernier départ',
              value: j.arrivalTime!,
            ),
          const SizedBox(height: 12),
          if (j.duration.isNotEmpty)
            _buildInfoCard(
              icon: Icons.schedule,
              title: 'Fréquence',
              value: j.duration,
            ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.payments_outlined,
            title: 'Tarif estimé',
            value: '${j.price} TND',
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Les bus TRANSTU opèrent à fréquence régulière. '
                    'Le premier et le dernier départ sont indiqués depuis le hub.',
                    style:
                        TextStyle(fontSize: 13, color: Color(0xFF1B5E20)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metro = widget.metroResult;
    final isMetro = metro != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isTranstuBus
                      ? [const Color(0xFF00695C), const Color(0xFF00897B)]
                      : isMetro
                          ? [
                              const Color(0xFF1A3A6B),
                              const Color(0xFF2E6DA4),
                            ]
                          : [AppTheme.primaryTeal, AppTheme.lightTeal],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home/journey-input');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.journeyDetails,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              isMetro
                                  ? metro.operatorName
                                  : _journey.operator,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMetro && !metro.noTrainToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C00),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'N°${metro.tripNumberStr ?? metro.tripNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (_isTranstuBus)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_bus,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'TRANSTU',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Map (train only — hidden for TRANSTU bus)
                    if (!_isTranstuBus)
                      SizedBox(
                        height: 250,
                        child: _stopsLoading
                            ? const Center(
                                child: CircularProgressIndicator())
                            : ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(20),
                                ),
                                child: FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _getCoordinates(),
                                    initialZoom: _getZoom(),
                                    maxZoom: 18,
                                    minZoom: 5,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.tunitransport',
                                      maxNativeZoom: 19,
                                    ),
                                    PolylineLayer(
                                        polylines: _buildPolylines()),
                                    MarkerLayer(markers: _buildMarkers()),
                                  ],
                                ),
                              ),
                      ),

                    const SizedBox(height: 16),

                    // Times banner (Metro / train)
                    if (isMetro && !metro.noTrainToday)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1A3A6B),
                                Color(0xFF2E6DA4)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              _timeBadge('Départ', metro.departureTime),
                              const Spacer(),
                              Column(
                                children: [
                                  const Icon(Icons.arrow_forward,
                                      color: Colors.white54, size: 18),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${metro.durationMinutes} min',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              _timeBadge('Arrivée', metro.arrivalTime),
                            ],
                          ),
                        ),
                      ),

                    if (isMetro && metro.noTrainToday)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.amber.shade200),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.amber, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                          text:
                                              'Aucun train disponible ce soir.\nPremier train demain à '),
                                      WidgetSpan(
                                        alignment:
                                            PlaceholderAlignment.middle,
                                        child: TimeText(
                                          metro.departureTime,
                                          style: TextStyle(
                                            color: Colors.amber.shade900,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                      color: Colors.amber.shade900,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ── Route steps OR bus panel ──────────────────────────
                    if (_isTranstuBus)
                      _buildBusDetailsPanel()
                    else
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Étapes du trajet',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),
                            if (_intermediateStops.isNotEmpty)
                              ..._buildStopsList()
                            else ...[
                              _buildRouteStep(
                                time: _journey.departure,
                                station: _journey.departureStation,
                                isFirst: true,
                                isLast: false,
                              ),
                              _buildRouteStep(
                                time: _journey.arrival,
                                station: _journey.arrivalStation,
                                isFirst: false,
                                isLast: true,
                                type: 'Destination',
                              ),
                            ],
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Info cards (train / generic journey only)
                    if (!_isTranstuBus)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildInfoCard(
                              icon: Icons.access_time,
                              title: l10n.totalDuration,
                              value: isMetro
                                  ? '${metro.durationMinutes} min'
                                  : _journey.duration,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              icon: Icons.payments_outlined,
                              title: l10n.fare,
                              value: isMetro
                                  ? '${metro.price.toStringAsFixed(3)} TND'
                                  : '${_journey.price} TND',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              icon: Icons.train,
                              title: l10n.journeyType,
                              value: isMetro
                                  ? 'Métro du Sahel'
                                  : _journey.type,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              icon: Icons.place_outlined,
                              title: 'Arrêts',
                              value: isMetro
                                  ? '${metro.numberOfStops} arrêts (Direct)'
                                  : _journey.transfers == 0
                                      ? 'Direct'
                                      : '${_journey.transfers} correspondance(s)',
                            ),
                            if (isMetro) ...[
                              const SizedBox(height: 12),
                              _buildInfoCard(
                                icon: Icons.route,
                                title: 'Ligne',
                                value: metro.routeName,
                              ),
                            ],
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ── Action buttons ────────────────────────────────────
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          if (!isMetro || !metro.noTrainToday)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final confirmed =
                                      await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text(
                                          'Commencer le trajet'),
                                      content: Text(
                                        'Voulez-vous commencer le trajet '
                                        '"${_journey.departureStation} → '
                                        '${_journey.arrivalStation}" ?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx)
                                                  .pop(false),
                                          child:
                                              const Text('Annuler'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx)
                                                  .pop(true),
                                          child:
                                              const Text('Confirmer'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;
                                  await ActiveJourneyService.instance
                                      .setActiveJourney(_journey);
                                  if (!context.mounted) return;
                                  context.go('/home/active-journey',
                                      extra: _journey);
                                },
                                icon: const Icon(Icons.check_circle),
                                label:
                                    const Text('Commencer le trajet'),
                              ),
                            ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: ListenableBuilder(
                              listenable: FavoritesController.instance,
                              builder: (context, _) {
                                final isFav = FavoritesController
                                    .instance
                                    .isFavorite(_journey.id);
                                return OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await FavoritesController
                                          .instance
                                          .toggleFavorite(_journey);
                                      if (!context.mounted) return;
                                      final nowFav =
                                          FavoritesController.instance
                                              .isFavorite(_journey.id);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(nowFav
                                              ? 'Ajouté aux favoris! ♥'
                                              : 'Retiré des favoris'),
                                          duration: const Duration(
                                              seconds: 2),
                                        ),
                                      );
                                    } catch (_) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Erreur lors de la mise à jour des favoris'),
                                          backgroundColor: Colors.red,
                                          duration:
                                              Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    isFav
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color:
                                        isFav ? Colors.red : null,
                                  ),
                                  label: Text(isFav
                                      ? 'Retirer des favoris'
                                      : 'Ajouter aux favoris'),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _shareJourney,
                              icon: const Icon(Icons.share),
                              label: const Text('Partager'),
                            ),
                          ),

                          if (isMetro) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _callOperator,
                                icon: const Icon(Icons.phone),
                                label: Text(
                                    'Appeler ${metro.operatorPhone}'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBadge(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11)),
        TimeText(
          time,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28),
        ),
      ],
    );
  }

  List<Widget> _buildStopsList() {
    final widgets = <Widget>[];
    for (int i = 0; i < _intermediateStops.length; i++) {
      final stop = _intermediateStops[i];
      final isFirst = i == 0;
      final isLast = i == _intermediateStops.length - 1;
      widgets.add(_buildRouteStep(
        time: stop.time,
        station: stop.name,
        isFirst: isFirst,
        isLast: isLast,
        type: isFirst ? 'Départ' : isLast ? 'Destination' : null,
      ));
    }
    return widgets;
  }

  Widget _buildRouteStep({
    required String time,
    required String station,
    required bool isFirst,
    required bool isLast,
    String? type,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (isFirst || isLast)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isFirst ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isFirst
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                    width: 4,
                  ),
                ),
              )
            else
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.orange.shade100, width: 2),
                ),
              ),
            if (!isLast)
              Container(
                width: 2,
                height: isFirst || isLast ? 40 : 28,
                color: AppTheme.lightTeal,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              TimeText(
                time,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(station,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              if (type != null)
                Text(type,
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.mediumGrey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightTeal.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: AppTheme.primaryTeal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.mediumGrey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StopInfo {
  final String name;
  final String time;
  final double lat;
  final double lng;

  const _StopInfo({
    required this.name,
    required this.time,
    required this.lat,
    required this.lng,
  });
}
