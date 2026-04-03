import 'package:flutter/material.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import '../controllers/favorites_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/journey_card.dart';
import 'journey_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  FavoritesController get _controller => FavoritesController.instance;

  @override
  void initState() {
    super.initState();
    // Load favorites from Firestore each time screen is initialized.
    _controller.loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
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
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.favorites,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        l10n.savedJourneys,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final favorites = _controller.favorites;

                if (favorites.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noFavoriteJourneysYet,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.mediumGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final journey = favorites[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: JourneyCard(
                        journey: journey,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => JourneyDetailsScreen(journey: journey),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
