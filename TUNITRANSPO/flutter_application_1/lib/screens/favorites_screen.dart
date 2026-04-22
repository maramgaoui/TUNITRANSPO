import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import '../controllers/favorites_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/journey_card.dart';

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
    // Singleton controller caches per-user favorites; load only once.
    _controller.ensureFavoritesLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: l10n.favorites,
            subtitle: l10n.savedJourneys,
            leading: const Icon(Icons.favorite, color: Colors.white, size: 28),
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
                          context.push('/home/journey-details', extra: journey);
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
