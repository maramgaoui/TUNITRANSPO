import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/widgets/time_text.dart';
import '../models/journey_model.dart';
import '../services/active_journey_service.dart';
import '../theme/app_theme.dart';

class ActiveJourneyScreen extends StatelessWidget {
  final Journey journey;

  const ActiveJourneyScreen({super.key, required this.journey});

  Future<void> _openMaps(BuildContext context) async {
    final origin = Uri.encodeComponent('${journey.departureStation}, Tunis, Tunisia');
    final destination = Uri.encodeComponent('${journey.arrivalStation}, Tunis, Tunisia');
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$origin'
      '&destination=$destination'
      '&travelmode=transit',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRatingSheet(BuildContext context, Journey journey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RatingSheet(journey: journey),
    );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasTransfer = journey.transferStation != null &&
        journey.transferStation!.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryTeal, AppTheme.lightTeal],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/home/journey-input'),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Trajet en cours',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.circle,
                                color: Colors.greenAccent, size: 8),
                            const SizedBox(width: 4),
                            const Text(
                              'En route',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(_iconFor(journey.iconKey),
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${journey.departureStation} → ${journey.arrivalStation}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Open maps button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _openMaps(context),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text(
                          'Voir le trajet sur la carte',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Journey info card
                    _InfoCard(
                      children: [
                        _InfoRow(
                          icon: Icons.schedule,
                          label: 'Départ',
                          value: journey.departureTime,
                          forceLtrValue: true,
                        ),
                        if (journey.arrivalTime != null &&
                            journey.arrivalTime!.isNotEmpty)
                          _InfoRow(
                            icon: Icons.flag_outlined,
                            label: 'Arrivée prévue',
                            value: journey.arrivalTime!,
                            forceLtrValue: true,
                          ),
                        _InfoRow(
                          icon: Icons.timer_outlined,
                          label: l10n.totalDuration,
                          value: journey.duration,
                        ),
                        _InfoRow(
                          icon: Icons.payments_outlined,
                          label: 'Prix',
                          value: journey.price,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Route steps
                    Text(
                      l10n.journeySteps,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RouteSteps(journey: journey, hasTransfer: hasTransfer),
                    const SizedBox(height: 20),

                    // End journey button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Terminer le trajet'),
                              content: const Text(
                                  'Voulez-vous terminer ce trajet ?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child: const Text('Continuer'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                  child: const Text('Terminer'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          await ActiveJourneyService.instance
                              .clearActiveJourney();
                          if (!context.mounted) return;
                          context.go('/home/journey-input');
                        },
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text(
                          'Terminer le trajet',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Evaluate button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryTeal,
                          side: const BorderSide(color: AppTheme.primaryTeal),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            _showRatingSheet(context, journey),
                        icon: const Icon(Icons.star_rate_outlined),
                        label: const Text(
                          'Évaluer le trajet',
                          style: TextStyle(fontSize: 15),
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
}

class _RatingSheet extends StatefulWidget {
  final Journey journey;
  const _RatingSheet({required this.journey});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _transportRating = 0;
  int _experienceRating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Widget _starRow(String label, int current, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final filled = i < current;
            return GestureDetector(
              onTap: () => onChanged(i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? Colors.amber : AppTheme.mediumGrey,
                  size: 36,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.mediumGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text(
              'Évaluer le trajet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.journey.departureStation} → ${widget.journey.arrivalStation}',
              style: const TextStyle(fontSize: 13, color: AppTheme.darkGrey),
            ),
            const Divider(height: 24),

            // Transport rating
            _starRow(
              'Qualité du moyen de transport',
              _transportRating,
              (v) => setState(() => _transportRating = v),
            ),
            const SizedBox(height: 20),

            // Experience rating
            _starRow(
              'Expérience globale du trajet',
              _experienceRating,
              (v) => setState(() => _experienceRating = v),
            ),
            const SizedBox(height: 20),

            // Comment
            const Text(
              'Commentaire (optionnel)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Partagez votre expérience...',
                hintStyle: const TextStyle(color: AppTheme.mediumGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.lightGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.lightGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppTheme.primaryTeal, width: 2),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (_transportRating == 0 || _experienceRating == 0)
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Merci pour votre évaluation ! ⭐'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                child: const Text(
                  'Soumettre l\'évaluation',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.lightGrey),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool forceLtrValue;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.forceLtrValue = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryTeal),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.darkGrey),
          ),
          const Spacer(),
          forceLtrValue
                ? TimeText(
                  value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark),
                )
              : Text(
                  value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark),
                ),
        ],
      ),
    );
  }
}

class _RouteSteps extends StatelessWidget {
  final Journey journey;
  final bool hasTransfer;
  const _RouteSteps({required this.journey, required this.hasTransfer});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StepTile(
          icon: Icons.my_location,
          iconColor: AppTheme.primaryTeal,
          title: journey.departureStation,
          subtitle: journey.departureTime,
          forceLtrSubtitle: true,
          isFirst: true,
        ),
        _StepConnector(
          label:
              '${journey.type}  ·  Ligne ${journey.line}  ·  ${journey.operator}',
        ),
        if (hasTransfer) ...[
          _StepTile(
            icon: Icons.sync_alt,
            iconColor: Colors.orange,
            title: journey.transferStation!,
            subtitle: journey.transferTime != null
                ? 'Correspondance à ${journey.transferTime}'
                : 'Correspondance',
          ),
          _StepConnector(label: 'Correspondance'),
        ],
        _StepTile(
          icon: Icons.location_on,
          iconColor: Colors.red,
          title: journey.arrivalStation,
          subtitle: journey.arrivalTime ?? '',
          forceLtrSubtitle: true,
          isLast: true,
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool forceLtrSubtitle;
  final bool isFirst;
  final bool isLast;

  const _StepTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.forceLtrSubtitle = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            if (!isFirst)
              const SizedBox.shrink(), // spacing handled by connector
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              if (subtitle.isNotEmpty)
                forceLtrSubtitle
                    ? TimeText(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.darkGrey),
                      )
                    : Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.darkGrey),
                      ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  final String label;
  const _StepConnector({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 17),
          Container(
            width: 2,
            height: 40,
            color: AppTheme.lightGrey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.darkGrey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
