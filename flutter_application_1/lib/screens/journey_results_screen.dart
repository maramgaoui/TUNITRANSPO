import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'journey_details_screen.dart';

class JourneyResultsScreen extends StatefulWidget {
  final String departure;
  final String arrival;

  const JourneyResultsScreen({
    super.key,
    required this.departure,
    required this.arrival,
  });

  @override
  State<JourneyResultsScreen> createState() => _JourneyResultsScreenState();
}

class _JourneyResultsScreenState extends State<JourneyResultsScreen> {
  final List<Journey> journeys = [
    Journey(
      type: 'Bus',
      icon: Icons.directions_bus,
      departure: '14:30',
      arrival: '16:45',
      duration: '2h 15m',
      price: '4.500',
      transfers: 1,
      isOptimal: true,
      operator: 'SNTRI',
      line: 'Ligne 7',
    ),
    Journey(
      type: 'Métro',
      icon: Icons.directions_subway,
      departure: '14:50',
      arrival: '17:20',
      duration: '2h 30m',
      price: '3.750',
      transfers: 2,
      isOptimal: false,
      operator: 'SMTC',
      line: 'M1 → M4',
    ),
    Journey(
      type: 'Taxi',
      icon: Icons.local_taxi,
      departure: '14:35',
      arrival: '15:50',
      duration: '1h 15m',
      price: '15.000',
      transfers: 0,
      isOptimal: false,
      operator: 'Uber',
      line: 'Direct',
    ),
    Journey(
      type: 'Combiné',
      icon: Icons.train,
      departure: '15:00',
      arrival: '16:30',
      duration: '1h 30m',
      price: '6.250',
      transfers: 1,
      isOptimal: false,
      operator: 'SNTRI + SMTC',
      line: 'Bus L5 → TGM',
    ),
  ];

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
                              'Résultats',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${widget.departure} → ${widget.arrival}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Route summary
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '4 options trouvées',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Results list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: journeys.length,
                itemBuilder: (context, index) {
                  final journey = journeys[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildJourneyCard(journey, context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyCard(Journey journey, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                JourneyDetailsScreen(journey: journey),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: journey.isOptimal
              ? Border.all(color: AppTheme.primaryTeal, width: 2)
              : Border.all(color: AppTheme.lightGrey),
          boxShadow: journey.isOptimal
              ? [
                  BoxShadow(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            if (journey.isOptimal)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Optimal',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.lightTeal.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          journey.icon,
                          color: AppTheme.primaryTeal,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              journey.type,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              journey.operator,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${journey.price} TND',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                          Text(
                            journey.line,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.mediumGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.paleWhite,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTimeInfo(
                          time: journey.departure,
                          label: 'Départ',
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                journey.duration,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.mediumGrey,
                                ),
                              ),
                              if (journey.transfers > 0)
                                Text(
                                  '${journey.transfers} correspondance${journey.transfers > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: journey.transfers > 1
                                        ? Colors.orange
                                        : AppTheme.mediumGrey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _buildTimeInfo(
                          time: journey.arrival,
                          label: 'Arrivée',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    JourneyDetailsScreen(journey: journey),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 600),
                          ),
                        );
                      },
                      child: const Text('Voir détails'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo({required String time, required String label}) {
    return Column(
      children: [
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.mediumGrey,
          ),
        ),
      ],
    );
  }
}

class Journey {
  final String type;
  final IconData icon;
  final String departure;
  final String arrival;
  final String duration;
  final String price;
  final int transfers;
  final bool isOptimal;
  final String operator;
  final String line;

  Journey({
    required this.type,
    required this.icon,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.price,
    required this.transfers,
    required this.isOptimal,
    required this.operator,
    required this.line,
  });
}
