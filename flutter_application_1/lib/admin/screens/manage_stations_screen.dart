import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/theme/app_theme.dart';

class ManageStationsScreen extends StatefulWidget {
  const ManageStationsScreen({super.key});

  @override
  State<ManageStationsScreen> createState() => _ManageStationsScreenState();
}

class _ManageStationsScreenState extends State<ManageStationsScreen> {
  final List<_Station> stations = [
    _Station(
      id: '1',
      name: 'Tunis Gare',
      type: 'Metro',
      city: 'Tunis',
    ),
    _Station(
      id: '2',
      name: 'La Marsa',
      type: 'Metro',
      city: 'La Marsa',
    ),
    _Station(
      id: '3',
      name: 'Sfax Gare',
      type: 'Train',
      city: 'Sfax',
    ),
    _Station(
      id: '4',
      name: 'Gare routière',
      type: 'Bus',
      city: 'Tunis',
    ),
  ];

  void _showStationForm(BuildContext context, [_Station? station]) {
    final isEdit = station != null;
    final nameCtrl = TextEditingController(text: station?.name ?? '');
    final typeCtrl = TextEditingController(text: station?.type ?? '');
    final cityCtrl = TextEditingController(text: station?.city ?? '');

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
                isEdit ? 'Modifier la station' : 'Ajouter une station',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nom de la station',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: typeCtrl,
                decoration: InputDecoration(
                  labelText: 'Type (Metro, Bus, Train)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityCtrl,
                decoration: InputDecoration(
                  labelText: 'Ville',
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
                      station.name = nameCtrl.text;
                      station.type = typeCtrl.text;
                      station.city = cityCtrl.text;
                    } else {
                      stations.add(
                        _Station(
                          id: DateTime.now().toString(),
                          name: nameCtrl.text,
                          type: typeCtrl.text,
                          city: cityCtrl.text,
                        ),
                      );
                    }
                    setState(() {});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Station modifiée avec succès'
                              : 'Station ajoutée avec succès',
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
        title: Text(l10n.manageStations),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: stations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.train_outlined,
                      size: 64, color: AppTheme.lightGrey),
                  const SizedBox(height: 16),
                  const Text('Aucune station'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stations.length,
              itemBuilder: (_, i) {
                final s = stations[i];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      s.type == 'Metro'
                          ? Icons.directions_subway
                          : s.type == 'Train'
                              ? Icons.train
                              : Icons.directions_bus,
                      color: AppTheme.primaryTeal,
                    ),
                    title: Text(s.name),
                    subtitle: Text('${s.type} • ${s.city}'),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () =>
                                _showStationForm(context, s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 18, color: Colors.red),
                            onPressed: () {
                              setState(() => stations.removeAt(i));
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
        onPressed: () => _showStationForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Station {
  final String id;
  String name;
  String type;
  String city;

  _Station({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
  });
}
