import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/theme/app_theme.dart';

class ManageStationsScreen extends StatefulWidget {
  const ManageStationsScreen({super.key});

  @override
  State<ManageStationsScreen> createState() => _ManageStationsScreenState();
}

class _ManageStationsScreenState extends State<ManageStationsScreen> {
  final CollectionReference<Map<String, dynamic>> _stationsRef =
      FirebaseFirestore.instance.collection('stations');

  Future<void> _showStationForm(
    BuildContext context, [
    QueryDocumentSnapshot<Map<String, dynamic>>? stationDoc,
  ]) async {
    final l10n = AppLocalizations.of(context)!;
    final data = stationDoc?.data() ?? <String, dynamic>{};
    final isEdit = stationDoc != null;
    final nameCtrl = TextEditingController(text: (data['name'] ?? '').toString());
    final typeCtrl = TextEditingController(text: (data['type'] ?? '').toString());
    final cityCtrl = TextEditingController(text: (data['city'] ?? '').toString());

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
                isEdit ? l10n.editStationTitle : l10n.addStationTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.stationName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: typeCtrl,
                decoration: InputDecoration(
                  labelText: l10n.stationType,
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
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final type = typeCtrl.text.trim();
                    final city = cityCtrl.text.trim();

                    if (name.isEmpty || type.isEmpty || city.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.fillAllFields)),
                      );
                      return;
                    }

                    final payload = {
                      'name': name,
                      'type': type,
                      'city': city,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    try {
                      if (isEdit) {
                        await _stationsRef.doc(stationDoc.id).update(payload);
                      } else {
                        await _stationsRef.add({
                          ...payload,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }
                      if (!context.mounted) return;
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/admin/manage-stations');
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? l10n.stationUpdatedSuccess
                                : l10n.stationAddedSuccess,
                          ),
                        ),
                      );
                    } on FirebaseException catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message ?? l10n.firestoreUpdateError)),
                      );
                    }
                  },
                  child: Text(isEdit ? l10n.edit : l10n.add),
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stationsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(l10n.stationsLoadError));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.train_outlined, size: 64, color: AppTheme.lightGrey),
                  const SizedBox(height: 16),
                  Text(l10n.noStationsFound),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data();
              final type = (data['type'] ?? '').toString();
              final name = (data['name'] ?? '').toString();
              final city = (data['city'] ?? '').toString();

              return Card(
                child: ListTile(
                  leading: Icon(
                    type == 'Metro'
                        ? Icons.directions_subway
                        : type == 'Train'
                            ? Icons.train
                            : Icons.directions_bus,
                    color: AppTheme.primaryTeal,
                  ),
                  title: Text(name),
                  subtitle: Text('$type • $city'),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _showStationForm(context, doc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () async {
                            await _stationsRef.doc(doc.id).delete();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
