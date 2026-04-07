import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/favorites_controller.dart';
import '../models/journey_model.dart';
import '../constants/mock_data.dart';
import '../widgets/app_header.dart';
import '../widgets/journey_card.dart';

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
      await context.push('/home/journey-details', extra: journey);
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
            AppHeader(
              title: 'Résultats',
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
              bottom: Container(
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
                      '${journeys.length} options trouvées',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
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
