import 'package:flutter/material.dart';
import '../controllers/favorites_controller.dart';
import '../theme/app_theme.dart';
import '../models/journey_model.dart';
import '../constants/mock_data.dart';
import '../widgets/journey_card.dart';
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
  final List<Journey> journeys = MockData.mockJourneys;
  bool _isNavigatingToDetails = false;

  @override
  void initState() {
    super.initState();
    FavoritesController.instance.loadFavorites();
  }

  Future<void> _openJourneyDetails(BuildContext context, Journey journey) async {
    if (_isNavigatingToDetails) return;

    setState(() => _isNavigatingToDetails = true);

    try {
      await Navigator.of(context).push(
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
    } finally {
      if (mounted) {
        setState(() => _isNavigatingToDetails = false);
      }
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
    return JourneyCard(
      journey: journey,
      onTap: () => _openJourneyDetails(context, journey),
    );
  }
}
