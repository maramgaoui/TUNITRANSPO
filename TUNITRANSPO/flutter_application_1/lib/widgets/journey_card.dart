import 'package:flutter/material.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/widgets/time_text.dart';

import '../controllers/favorites_controller.dart';
import '../models/journey_model.dart';
import '../theme/app_theme.dart';

class JourneyCard extends StatelessWidget {
  final Journey journey;
  final VoidCallback? onTap;
  final bool showFavoriteButton;

  const JourneyCard({
    super.key,
    required this.journey,
    this.onTap,
    this.showFavoriteButton = true,
  });

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
    return AnimatedBuilder(
      animation: FavoritesController.instance,
      builder: (context, _) {
        final isFavorite = FavoritesController.instance.isFavorite(journey.id);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: journey.isOptimal
                ? Border.all(color: AppTheme.primaryTeal, width: 2)
                : Border.all(color: AppTheme.lightGrey),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                          _iconFor(journey.iconKey),
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
                              '${journey.departureStation} → ${journey.arrivalStation}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              journey.type,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showFavoriteButton)
                        IconButton(
                          tooltip: AppLocalizations.of(context)!.favorites,
                          onPressed: () async {
                            // Important: this writes to Firestore via controller.
                            try {
                              await FavoritesController.instance.toggleFavorite(
                                journey,
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!
                                        .favoriteUpdateFailed,
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : AppTheme.mediumGrey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TimeText(
                        journey.departureTime,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${journey.price} TND',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
