import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import '../controllers/journey_search_controller.dart';
import '../models/bus_service_model.dart';
import '../models/journey_model.dart';
import '../widgets/app_header.dart';
import '../widgets/metro_sahel_card.dart';
import '../widgets/bus_service_card.dart';

class JourneyResultsScreen extends StatefulWidget {
  final String departure;
  final String arrival;
  final String? fromStationId;
  final String? toStationId;
  final bool preloadFavorites;

  const JourneyResultsScreen({
    super.key,
    required this.departure,
    required this.arrival,
    this.fromStationId,
    this.toStationId,
    this.preloadFavorites = true,
  });

  @override
  State<JourneyResultsScreen> createState() => _JourneyResultsScreenState();
}

class _JourneyResultsScreenState extends State<JourneyResultsScreen> {
  final JourneySearchController _searchController = JourneySearchController();

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

  /// Converts a [BusService] to a [Journey] for the details screen.
  Journey _busServiceToJourney(
    BusService service, {
    String? hubName,
    String? nextDeparture,
  }) {
    final parts = (hubName ?? '').split(' → ');
    return Journey(
      id: service.id,
      departureStation: parts.isNotEmpty ? parts.first : (service.hubStationId ?? ''),
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
              subtitle: '${widget.departure} → ${widget.arrival}',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home/journey-input');
                  }
                },
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : metroResult != null
                      // ── Train result ──────────────────────────────────────
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _sectionLabel(
                                '🚆 Prochain ${metroResult.operatorName}'),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => context.push(
                                '/home/journey-details',
                                extra: metroResult,
                              ),
                              child: MetroSahelCard(result: metroResult),
                            ),
                          ],
                        )
                      : bestBus != null
                          // ── Best next bus ─────────────────────────────────
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                _sectionLabel('🚌 Prochain bus TRANSTU'),
                                const SizedBox(height: 12),
                                if (error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      error,
                                      style: const TextStyle(
                                          color: Colors.orange, fontSize: 13),
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: () {
                                    final journey = _busServiceToJourney(
                                      bestBus,
                                      hubName: busHubName,
                                      nextDeparture: bestTime,
                                    );
                                    context.push('/home/journey-details',
                                        extra: journey);
                                  },
                                  child: _BestBusCard(
                                    service: bestBus,
                                    nextDeparture: bestTime,
                                    routeLabel: busHubName ?? '',
                                  ),
                                ),
                              ],
                            )
                          : busServices != null && busServices.isNotEmpty
                              // ── Full timetable list (hub → hub) ───────────
                              ? ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: busServices.length + 1,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return _sectionLabel(
                                        '🚌 Bus TRANSTU – ${busHubName ?? ""}',
                                      );
                                    }
                                    final service = busServices[index - 1];
                                    return GestureDetector(
                                      onTap: () {
                                        final journey = _busServiceToJourney(
                                          service,
                                          hubName: busHubName,
                                        );
                                        context.push('/home/journey-details',
                                            extra: journey);
                                      },
                                      child: BusServiceCard(service: service),
                                    );
                                  },
                                )
                              // ── No results / error ────────────────────────
                              : Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Text(
                                      error ??
                                          'Aucun trajet trouvé pour cette recherche.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Color(0xFF1A3A6B),
      ),
    );
  }
}

// ── _BestBusCard ──────────────────────────────────────────────────────────────

class _BestBusCard extends StatelessWidget {
  final BusService service;
  final String? nextDeparture;
  final String routeLabel;

  const _BestBusCard({
    required this.service,
    required this.nextDeparture,
    required this.routeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00695C).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line badge + direction
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_bus,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Ligne ${service.lineNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  routeLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Next departure banner
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time,
                    color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Prochain départ',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  nextDeparture ?? '--:--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
          ),
          if (service.frequencyLabel.isNotEmpty ||
              service.priceLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (service.frequencyLabel.isNotEmpty) ...[
                  const Icon(Icons.schedule, color: Colors.white54, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    service.frequencyLabel,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
                const Spacer(),
                if (service.priceLabel.isNotEmpty)
                  Text(
                    service.priceLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ],
          // Tap hint
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Text(
                'Appuyez pour les détails',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
