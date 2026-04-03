import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
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
                            const Text(
                              'Détails du trajet',
                              style: TextStyle(
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
                  // Placeholder for interactive map
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.lightTeal.withValues(alpha: 0.3),
                          AppTheme.primaryTeal.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 64,
                            color: AppTheme.primaryTeal,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Carte interactive',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Itinéraire intégré',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mediumGrey,
                            ),
                          ),
                        ],
                      ),
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
                            title: 'Durée totale',
                            value: widget.journey.duration,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.attach_money,
                            title: 'Tarif',
                            value: '${widget.journey.price} TND',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.train,
                            title: 'Type de trajet',
                            value: widget.journey.type,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.pin_drop,
                            title: 'Correspondances',
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Trajet commencé! ✓'),
                                duration: Duration(seconds: 2),
                              ),
                            );
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
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ajouté aux favoris! ♥'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.favorite_border),
                          label: const Text('Ajouter au favoris'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {},
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
