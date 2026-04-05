import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/theme/app_theme.dart';

class ManageJourneysScreen extends StatefulWidget {
  const ManageJourneysScreen({super.key});

  @override
  State<ManageJourneysScreen> createState() => _ManageJourneysScreenState();
}

class _ManageJourneysScreenState extends State<ManageJourneysScreen> {
  final List<_Journey> journeys = [
    _Journey(
      id: '1',
      departure: 'Tunis Gare',
      arrival: 'La Marsa',
      type: 'Metro',
      departureTime: '08:00',
    ),
    _Journey(
      id: '2',
      departure: 'La Marsa',
      arrival: 'Tunis Gare',
      type: 'Metro',
      departureTime: '09:30',
    ),
    _Journey(
      id: '3',
      departure: 'Sfax',
      arrival: 'Tunis',
      type: 'Train',
      departureTime: '10:15',
    ),
  ];

  void _showJourneyForm(BuildContext context, [_Journey? journey]) {
    final isEdit = journey != null;
    final departureCtrl =
        TextEditingController(text: journey?.departure ?? '');
    final arrivalCtrl = TextEditingController(text: journey?.arrival ?? '');
    final typeCtrl = TextEditingController(text: journey?.type ?? '');
    final timeCtrl = TextEditingController(text: journey?.departureTime ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Modifier le trajet' : 'Ajouter un trajet',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: departureCtrl,
                decoration: InputDecoration(
                  labelText: 'Départ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: arrivalCtrl,
                decoration: InputDecoration(
                  labelText: 'Arrivée',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: typeCtrl,
                decoration: InputDecoration(
                  labelText: 'Type (Bus, Metro, Train)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                decoration: InputDecoration(
                  labelText: 'Heure de départ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (isEdit) {
                      journey!.departure = departureCtrl.text;
                      journey.arrival = arrivalCtrl.text;
                      journey.type = typeCtrl.text;
                      journey.departureTime = timeCtrl.text;
                    } else {
                      journeys.add(
                        _Journey(
                          id: DateTime.now().toString(),
                          departure: departureCtrl.text,
                          arrival: arrivalCtrl.text,
                          type: typeCtrl.text,
                          departureTime: timeCtrl.text,
                        ),
                      );
                    }
                    setState(() {});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Trajet modifié avec succès'
                              : 'Trajet ajouté avec succès',
                        ),
                      ),
                    );
                  },
                  child: Text(isEdit ? 'Modifier' : 'Ajouter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageJourneys),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: journeys.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route, size: 64, color: AppTheme.lightGrey),
                  const SizedBox(height: 16),
                  const Text('Aucun trajet'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: journeys.length,
              itemBuilder: (_, i) {
                final j = journeys[i];
                return Card(
                  child: ListTile(
                    title: Text('${j.departure} → ${j.arrival}'),
                    subtitle:
                        Text('${j.type} • ${j.departureTime}'),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () =>
                                _showJourneyForm(context, j),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 18, color: Colors.red),
                            onPressed: () {
                              setState(() => journeys.removeAt(i));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryTeal,
        onPressed: () => _showJourneyForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Journey {
  final String id;
  String departure;
  String arrival;
  String type;
  String departureTime;

  _Journey({
    required this.id,
    required this.departure,
    required this.arrival,
    required this.type,
    required this.departureTime,
  });
}
