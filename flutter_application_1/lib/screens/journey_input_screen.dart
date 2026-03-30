import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/mock_data.dart';
import 'journey_results_screen.dart';

class JourneyInputScreen extends StatefulWidget {
  const JourneyInputScreen({super.key});

  @override
  State<JourneyInputScreen> createState() => _JourneyInputScreenState();
}

class _JourneyInputScreenState extends State<JourneyInputScreen> {
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();
  bool _useCurrentLocation = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _departureController.dispose();
    _arrivalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // App Logo
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Planifier votre trajet',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Trouvez les meilleures options',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Journey input card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Departure field
                          TextField(
                            controller: _departureController,
                            decoration: InputDecoration(
                              hintText: 'Point de départ',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              suffixIcon: _departureController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        _departureController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          // Swap button
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.lightTeal.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.swap_vert_rounded),
                              color: AppTheme.primaryTeal,
                              onPressed: () {
                                final temp = _departureController.text;
                                _departureController.text =
                                    _arrivalController.text;
                                _arrivalController.text = temp;
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Arrival field
                          TextField(
                            controller: _arrivalController,
                            decoration: InputDecoration(
                              hintText: 'Point d\'arrivée',
                              prefixIcon: const Icon(Icons.location_off_outlined),
                              suffixIcon: _arrivalController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        _arrivalController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Current location option
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.lightTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_searching,
                            color: AppTheme.primaryTeal,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Localisation actuelle',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Utiliser ma position GPS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.mediumGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: _useCurrentLocation,
                            onChanged: (value) {
                              setState(() =>
                                  _useCurrentLocation = value ?? false);
                            },
                            activeColor: AppTheme.primaryTeal,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Search button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_departureController.text.isNotEmpty &&
                              _arrivalController.text.isNotEmpty) {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation,
                                        secondaryAnimation) =>
                                    JourneyResultsScreen(
                                      departure: _departureController.text,
                                      arrival: _arrivalController.text,
                                    ),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  );
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 600),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Veuillez remplir tous les champs'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Rechercher un trajet'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Recent searches
                    const Text(
                      'Trajets récents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: MockData.recentSearches.length,
                      itemBuilder: (context, index) {
                        final search = MockData.recentSearches[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.lightGrey,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  color: AppTheme.mediumGrey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        search['route']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        search['time']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.mediumGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  color: AppTheme.primaryTeal,
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
