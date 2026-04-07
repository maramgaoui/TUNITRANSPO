import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import '../controllers/favorites_controller.dart';
import '../services/active_journey_service.dart';
import '../theme/app_theme.dart';
import '../models/journey_model.dart';

class JourneyDetailsScreen extends StatefulWidget {
  final Journey journey;

  const JourneyDetailsScreen({
    super.key,
    required this.journey,
  });

  @override
  State<JourneyDetailsScreen> createState() => _JourneyDetailsScreenState();
}

class _JourneyDetailsScreenState extends State<JourneyDetailsScreen> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Map approximate coordinates for Tunisian stations
  LatLng _getStationCoordinates(String stationName) {
    final name = stationName.toLowerCase();
    if (name.contains('marsa')) return const LatLng(36.8224, 10.3141);
    if (name.contains('sfax')) return const LatLng(34.7405, 10.7603);
    if (name.contains('sousse')) return const LatLng(35.8256, 10.6369);
    if (name.contains('gafsa')) return const LatLng(34.4258, 8.7731);
    if (name.contains('bizerte')) return const LatLng(37.2744, 9.8739);
    if (name.contains('tozeur')) return const LatLng(33.9197, 8.1353);
    if (name.contains('kairouan')) return const LatLng(35.6781, 10.0986);
    return const LatLng(36.8065, 10.1962); // Default: Tunis center
  }

  IconData _iconFor(String iconKey) {
    switch (iconKey) {
      case 'bus':
        return Icons.directions_bus;
      case 'metro':
        return Icons.directions_subway;
      case 'taxi':
        return Icons.local_taxi;
      case 'train':
        return Icons.train;
      default:
        return Icons.directions_transit;
    }
  }

  Future<void> _shareJourney() async {
    final transfersText = widget.journey.transfers == 0
        ? 'Direct'
        : '${widget.journey.transfers} correspondance${widget.journey.transfers > 1 ? 's' : ''}';

    final shareText = StringBuffer()
      ..writeln('Trajet ${widget.journey.departureStation} -> ${widget.journey.arrivalStation}')
      ..writeln('Depart: ${widget.journey.departureTime}')
      ..writeln('Arrivee: ${widget.journey.arrivalTime ?? widget.journey.arrival}')
      ..writeln('Duree: ${widget.journey.duration}')
      ..writeln('Prix: ${widget.journey.price} TND')
      ..writeln('Type: ${widget.journey.type}')
      ..writeln('Transferts: $transfersText')
      ..writeln('Operateur: ${widget.journey.operator}')
      ..writeln('Ligne: ${widget.journey.line}');

    try {
      await Share.share(shareText.toString());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de partager ce trajet pour le moment.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryTeal,
                    AppTheme.lightTeal,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
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
                              widget.journey.operator,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
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
            // Map area
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  // Real map with departure and arrival markers
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _getStationCoordinates(
                          widget.journey.departureStation,
                        ),
                        initialZoom: 10.0,
                        maxZoom: 18,
                        minZoom: 5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.tunitransport',
                          maxNativeZoom: 19,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _getStationCoordinates(
                                widget.journey.departureStation,
                              ),
                              width: 80,
                              height: 80,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Départ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Marker(
                              point: _getStationCoordinates(
                                widget.journey.arrivalStation,
                              ),
                              width: 80,
                              height: 80,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                      Icons.stop,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Arrivée',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
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
                  // Route info preview
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            _iconFor(widget.journey.iconKey),
                            color: AppTheme.primaryTeal,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.journey.type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${widget.journey.duration} • ${widget.journey.price} TND',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.mediumGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details section
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Route steps
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Étapes du trajet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildRouteStep(
                            time: widget.journey.departure,
                            station: widget.journey.departureStation,
                            isFirst: true,
                            isLast: widget.journey.transfers == 0,
                          ),
                          if (widget.journey.transfers > 0)
                            _buildRouteStep(
                              time: widget.journey.transferTime ?? widget.journey.departure,
                              station: widget.journey.transferStation ?? widget.journey.line,
                              isFirst: false,
                              isLast: false,
                              type: 'Correspondance',
                            ),
                          if (widget.journey.transfers > 0)
                            _buildRouteStep(
                              time: widget.journey.arrival,
                              station: widget.journey.arrivalStation,
                              isFirst: false,
                              isLast: true,
                              type: 'Destination',
                            ),
                          if (widget.journey.transfers == 0)
                            _buildRouteStep(
                              time: widget.journey.arrival,
                              station: widget.journey.arrivalStation,
                              isFirst: false,
                              isLast: true,
                              type: 'Destination',
                            ),
                        ],
                      ),
                    ),
                    // Information cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildInfoCard(
                            icon: Icons.access_time,
                            title: l10n.totalDuration,
                            value: widget.journey.duration,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.attach_money,
                            title: l10n.fare,
                            value: '${widget.journey.price} TND',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.train,
                            title: l10n.journeyType,
                            value: widget.journey.type,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.pin_drop,
                            title: l10n.transfers,
                            value: widget.journey.transfers == 0
                                ? 'Direct'
                                : '${widget.journey.transfers} correspondance${widget.journey.transfers > 1 ? 's' : ''}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Commencer le trajet'),
                                content: Text(
                                  'Voulez-vous commencer le trajet "${widget.journey.departureStation} → ${widget.journey.arrivalStation}" ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Annuler'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Confirmer'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            await ActiveJourneyService.instance
                                .setActiveJourney(widget.journey);
                            if (!context.mounted) return;
                            context.go('/home/active-journey',
                                extra: widget.journey);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Commencer le trajet'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ListenableBuilder(
                          listenable: FavoritesController.instance,
                          builder: (context, _) {
                            final isFav = FavoritesController.instance
                                .isFavorite(widget.journey.id);
                            return OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  await FavoritesController.instance
                                      .toggleFavorite(widget.journey);
                                  if (!context.mounted) return;
                                  final nowFav = FavoritesController.instance
                                      .isFavorite(widget.journey.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(nowFav
                                          ? 'Ajouté aux favoris! ♥'
                                          : 'Retiré des favoris'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Erreur lors de la mise à jour des favoris'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(isFav
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                                color: isFav ? Colors.red : null,
                              ),
                              label: Text(
                                  isFav ? 'Retirer des favoris' : 'Ajouter au favoris'),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _shareJourney,
                          icon: const Icon(Icons.share),
                          label: const Text('Partager'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            if (isFirst)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightTeal,
                    width: 4,
                  ),
                ),
              )
            else if (isLast)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightTeal,
                    width: 4,
                  ),
                ),
              )
            else
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.lightTeal,
                  shape: BoxShape.circle,
                ),
              ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
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
              Text(
                time,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                station,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (type != null)
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.mediumGrey,
                  ),
                ),
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumGrey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
