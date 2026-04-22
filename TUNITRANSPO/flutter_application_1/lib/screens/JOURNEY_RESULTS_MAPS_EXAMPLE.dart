import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import '../controllers/journey_search_controller.dart';
import '../models/bus_service_model.dart';
import '../models/journey_model.dart';
import '../models/station_model.dart';
import '../widgets/app_header.dart';
import '../widgets/metro_sahel_card.dart';
import '../widgets/bus_service_card.dart';
import '../widgets/journey_map_preview_widget.dart'; // ADD THIS
import '../screens/route_map_screen.dart'; // ADD THIS

// USAGE EXAMPLE: How to integrate maps into journey results

class JourneyResultsScreenWithMapsExample extends StatefulWidget {
  final String departure;
  final String arrival;
  final String? fromStationId;
  final String? toStationId;
  final bool preloadFavorites;

  const JourneyResultsScreenWithMapsExample({
    super.key,
    required this.departure,
    required this.arrival,
    this.fromStationId,
    this.toStationId,
    this.preloadFavorites = true,
  });

  @override
  State<JourneyResultsScreenWithMapsExample> createState() =>
      _JourneyResultsScreenWithMapsExampleState();
}

class _JourneyResultsScreenWithMapsExampleState
    extends State<JourneyResultsScreenWithMapsExample> {
  final JourneySearchController _searchController = JourneySearchController();
  bool _showMapView = false; // Toggle between list and map view

  // Example station data (in real app, fetch from repository)
  Station? fromStation;
  Station? toStation;
  List<Station> intermediateStations = [];

  @override
  void initState() {
    super.initState();
    if (widget.fromStationId != null && widget.toStationId != null) {
      _searchController.search(
        fromStationId: widget.fromStationId!,
        toStationId: widget.toStationId!,
      );
    }
    _searchController.addListener(_onSearchStateChanged);
  }

  void _onSearchStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Example: Convert BusService to Journey
  Journey _busServiceToJourney(
    BusService service, {
    String? hubName,
    String? nextDeparture,
  }) {
    final parts = (hubName ?? '').split(' → ');
    return Journey(
      id: service.id,
      departureStation:
          parts.isNotEmpty ? parts.first : (service.hubStationId ?? ''),
      arrivalStation: parts.length > 1
          ? parts.last
          : (service.destinationNameFr ?? service.directionAr),
      departureTime: nextDeparture ?? service.firstDepartureFromHub ?? '--:--',
      arrivalTime: service.lastDepartureFromHub,
      price: (service.price ?? 0.5).toStringAsFixed(3),
      type: 'Bus TRANSTU',
      iconKey: 'bus',
      duration: service.peakFrequencyMinutes != null
          ? 'Fréquence: ${service.peakFrequencyMinutes} min'
          : '',
      transfers: 0,
      isOptimal: true,
      operator: 'TRANSTU',
      line: 'Ligne ${service.lineNumber}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final metroResult = _searchController.state.metroSahelResult;
    final busServices = _searchController.state.busServices;
    final busHubName = _searchController.state.busHubName;
    final bestBus = _searchController.state.bestBusService;
    final bestTime = _searchController.state.bestBusDepartureTime;
    final isLoading = _searchController.state.isLoading;
    final error = _searchController.state.error;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: AppLocalizations.of(context)!.results,
            ),
            // EXAMPLE: Toggle button between list and map view
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _showMapView = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            !_showMapView ? Colors.blue : Colors.grey,
                      ),
                      child: const Text('List View'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _showMapView = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _showMapView ? Colors.blue : Colors.grey,
                      ),
                      child: const Text('Map View'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildResultsContent(context, isLoading, error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsContent(
      BuildContext context, bool isLoading, String? error) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && error.isNotEmpty) {
      return Center(
        child: Text(
          error,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    // EXAMPLE: Show map view if toggled
    if (_showMapView) {
      return _buildMapView();
    }

    // Default: Show list view
    return _buildListView(context);
  }

  /// EXAMPLE: Build map view showing the route
  Widget _buildMapView() {
    if (widget.fromStationId == null || widget.toStationId == null) {
      return const Center(child: Text('Station information not available'));
    }

    return RouteMapScreen(
      stationIds: [widget.fromStationId!, widget.toStationId!],
      routeTitle: '${widget.departure} → ${widget.arrival}',
    );
  }

  /// Build traditional list view
  Widget _buildListView(BuildContext context) {
    final metroResult = _searchController.state.metroSahelResult;
    final busServices = _searchController.state.busServices;
    final bestBus = _searchController.state.bestBusService;
    final bestTime = _searchController.state.bestBusDepartureTime;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (metroResult != null)
          Column(
            children: [
              MetroSahelCard(result: metroResult),
              const SizedBox(height: 16),
            ],
          ),
        if (bestBus != null)
          Column(
            children: [
              const Text(
                'Quick Option',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // EXAMPLE: Add map preview to bus service card
              BusServiceCard(
                service: bestBus,
              ),
              // EXAMPLE: Show map preview for the route
              if (fromStation != null && toStation != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: JourneyMapPreviewWidget(
                    fromStation: fromStation,
                    toStation: toStation,
                    intermediateStations: intermediateStations,
                    height: 200,
                    onMapTapped: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RouteMapScreen(
                            stationIds: [
                              fromStation!.id,
                              toStation!.id,
                            ],
                            routeTitle: bestBus.destinationNameFr ??
                                bestBus.directionAr,
                            lineNumber: bestBus.lineNumber,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        if (busServices != null && busServices.isNotEmpty)
          Column(
            children: [
              const Text(
                'All Options',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...busServices.map((service) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BusServiceCard(
                    service: service,
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE: How to add map preview to a bus service card
// ─────────────────────────────────────────────────────────────────────────

class BusServiceCardWithMap extends StatelessWidget {
  final BusService service;
  final String? nextDeparture;
  final VoidCallback? onTap;
  final Station? fromStation;
  final Station? toStation;

  const BusServiceCardWithMap({
    super.key,
    required this.service,
    this.nextDeparture,
    this.onTap,
    this.fromStation,
    this.toStation,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Original bus service card
          GestureDetector(
            onTap: onTap,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ligne ${service.lineNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(service.directionAr),
                    if (nextDeparture != null)
                      Text('Next: $nextDeparture'),
                  ],
                ),
              ),
            ),
          ),
          // EXAMPLE: Add map preview below
          if (fromStation != null && toStation != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: JourneyMapPreviewWidget(
                fromStation: fromStation,
                toStation: toStation,
                height: 180,
                onMapTapped: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RouteMapScreen(
                        stationIds: [
                          fromStation!.id,
                          toStation!.id,
                        ],
                        lineNumber: service.lineNumber,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE: Simple map access button
// ─────────────────────────────────────────────────────────────────────────

class MapAccessButton extends StatelessWidget {
  final String title;
  final List<String> stationIds;

  const MapAccessButton({
    super.key,
    required this.title,
    required this.stationIds,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.map),
      label: const Text('View on Map'),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteMapScreen(
              stationIds: stationIds,
              routeTitle: title,
            ),
          ),
        );
      },
    );
  }
}
