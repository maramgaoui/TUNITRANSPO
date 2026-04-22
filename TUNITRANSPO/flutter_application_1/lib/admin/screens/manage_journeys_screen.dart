import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/theme/app_theme.dart';
import 'package:tuni_transport/widgets/ltr_time_text.dart';

class ManageJourneysScreen extends StatefulWidget {
  const ManageJourneysScreen({super.key});

  @override
  State<ManageJourneysScreen> createState() => _ManageJourneysScreenState();
}

class _ManageJourneysScreenState extends State<ManageJourneysScreen> {
  final CollectionReference<Map<String, dynamic>> _journeysRef =
      FirebaseFirestore.instance.collection('journeys');

  Future<void> _showJourneyForm(
    BuildContext context, [
    QueryDocumentSnapshot<Map<String, dynamic>>? journeyDoc,
  ]) async {
    final l10n = AppLocalizations.of(context)!;
    final data = journeyDoc?.data() ?? <String, dynamic>{};
    final isEdit = journeyDoc != null;
    final departureCtrl =
        TextEditingController(text: (data['departure'] ?? '').toString());
    final arrivalCtrl =
        TextEditingController(text: (data['arrival'] ?? '').toString());
    final typeCtrl = TextEditingController(text: (data['type'] ?? '').toString());
    final timeCtrl =
        TextEditingController(text: (data['departureTime'] ?? '').toString());

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
                isEdit ? l10n.editJourneyTitle : l10n.addJourneyTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: departureCtrl,
                decoration: InputDecoration(
                  labelText: l10n.departurePoint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: arrivalCtrl,
                decoration: InputDecoration(
                  labelText: l10n.arrivalPoint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: typeCtrl,
                decoration: InputDecoration(
                  labelText: l10n.journeyTypeField,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                decoration: InputDecoration(
                  labelText: l10n.departureTime,
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
                    final departure = departureCtrl.text.trim();
                    final arrival = arrivalCtrl.text.trim();
                    final type = typeCtrl.text.trim();
                    final departureTime = timeCtrl.text.trim();

                    if (departure.isEmpty ||
                        arrival.isEmpty ||
                        type.isEmpty ||
                        departureTime.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.fillAllFields)),
                      );
                      return;
                    }

                    final payload = {
                      'departure': departure,
                      'arrival': arrival,
                      'type': type,
                      'departureTime': departureTime,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    try {
                      if (isEdit) {
                        await _journeysRef.doc(journeyDoc.id).update(payload);
                      } else {
                        await _journeysRef.add({
                          ...payload,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }
                      if (!context.mounted) return;
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/admin/manage-journeys');
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? l10n.journeyUpdatedSuccess
                                : l10n.journeyAddedSuccess,
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
        title: Text(l10n.manageJourneys),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _journeysRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(l10n.journeysLoadError));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route, size: 64, color: AppTheme.lightGrey),
                  const SizedBox(height: 16),
                  Text(l10n.noJourneysFound),
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
              final departure = (data['departure'] ?? '').toString();
              final arrival = (data['arrival'] ?? '').toString();
              final type = (data['type'] ?? '').toString();
              final departureTime = (data['departureTime'] ?? '').toString();

              return Card(
                child: ListTile(
                  title: Text('$departure → $arrival'),
                  subtitle: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(text: '$type • '),
                        LtrTimeText.asSpan(
                          departureTime,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _showJourneyForm(context, doc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () async {
                            await _journeysRef.doc(doc.id).delete();
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
        onPressed: () => _showJourneyForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
