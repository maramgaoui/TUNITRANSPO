import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tuni_transport/widgets/time_text.dart';
import '../models/metro_sahel_result.dart';

class MetroSahelCard extends StatelessWidget {
  final MetroSahelResult result;

  const MetroSahelCard({super.key, required this.result});

  bool get _noTrainToday => result.arrivalTime == 'TOMORROW';

  Future<void> _callOperator() async {
    final uri = Uri(scheme: 'tel', path: result.operatorPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A6B), Color(0xFF2E6DA4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A6B).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.train, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.operatorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!_noTrainToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Train ${result.tripNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Route
            Text(
              '${result.fromStationName} → ${result.toStationName}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),

            if (_noTrainToday) ...[
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Aucun train disponible ce soir.\nPremier train demain à '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: TimeText(
                              result.departureTime,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Times row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Départ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                        ),
                      ),
                      TimeText(
                        result.departureTime,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arrivée',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                        ),
                      ),
                      TimeText(
                        result.arrivalTime,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Chips row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip(
                    icon: Icons.access_time,
                    label: '${result.durationMinutes} min',
                  ),
                  _chip(
                    icon: Icons.payments_outlined,
                    label:
                        '${result.price.toStringAsFixed(3)} ${MetroSahelResult.currency}',
                    color: const Color(0xFFFF8C00),
                  ),
                  _chip(
                    icon: Icons.place_outlined,
                    label: '${result.numberOfStops} arrêts',
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),

            // Footer — phone
            GestureDetector(
              onTap: _callOperator,
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    result.operatorPhone,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white54,
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

  Widget _chip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (color ?? Colors.white).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
