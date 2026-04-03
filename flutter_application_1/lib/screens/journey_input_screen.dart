import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import '../controllers/notification_controller.dart';
import '../theme/app_theme.dart';
import '../constants/mock_data.dart';
import '../widgets/app_header.dart';

class JourneyInputScreen extends StatefulWidget {
  const JourneyInputScreen({super.key});

  @override
  State<JourneyInputScreen> createState() => _JourneyInputScreenState();
}

class _JourneyInputScreenState extends State<JourneyInputScreen> {
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();
  bool _useCurrentLocation = false;
  bool _isLocatingCurrentPosition = false;
  String _manualDepartureBackup = '';

  bool _isCurrentLocationText(String value) {
    return value.startsWith('Position actuelle') || value.startsWith('Current location') || value.startsWith('الموقع الحالي');
  }

  void _swapLocations() {
    final departureText = _departureController.text;
    final arrivalText = _arrivalController.text;

    // Keep GPS departure pinned when current location is enabled.
    if (_useCurrentLocation && _isCurrentLocationText(departureText)) {
      _arrivalController.text = _manualDepartureBackup;
      _manualDepartureBackup = arrivalText;
      setState(() {});
      return;
    }

    _departureController.text = arrivalText;
    _arrivalController.text = departureText;

    if (!_useCurrentLocation) {
      _manualDepartureBackup = _departureController.text;
    }

    setState(() {});
  }

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

  Future<void> _handleCurrentLocationToggle(bool enabled) async {
    final l10n = AppLocalizations.of(context)!;

    if (!enabled) {
      setState(() {
        _useCurrentLocation = false;
        if (_departureController.text.startsWith('Position actuelle')) {
          _departureController.text = _manualDepartureBackup;
        }
      });
      return;
    }

    _manualDepartureBackup = _departureController.text;
    setState(() {
      _useCurrentLocation = true;
      _isLocatingCurrentPosition = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError(l10n.locationServiceDisabled);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showLocationError(l10n.locationPermissionDenied);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;

      setState(() {
        _departureController.text =
            '${l10n.currentLocation} (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})';
      });
    } catch (e) {
      _showLocationError(l10n.unableGetGps);
    } finally {
      if (mounted) {
        setState(() {
          _isLocatingCurrentPosition = false;
        });
      }
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;

    setState(() {
      _useCurrentLocation = false;
      _isLocatingCurrentPosition = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              AppHeader(
                title: l10n.planJourney,
                subtitle: l10n.findBestOptions,
                leading: Container(
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
                              hintText: l10n.departurePoint,
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              suffixIcon: _departureController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        _departureController.clear();
                                        if (!_useCurrentLocation) {
                                          _manualDepartureBackup = '';
                                        }
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              if (!_useCurrentLocation) {
                                _manualDepartureBackup = value;
                              }
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
                              onPressed: _swapLocations,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Arrival field
                          TextField(
                            controller: _arrivalController,
                            decoration: InputDecoration(
                              hintText: l10n.arrivalPoint,
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
                                Text(
                                  l10n.currentLocation,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  l10n.useMyGpsPosition,
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
                            onChanged: _isLocatingCurrentPosition
                                ? null
                                : (value) => _handleCurrentLocationToggle(
                                      value ?? false,
                                    ),
                            activeColor: AppTheme.primaryTeal,
                          ),
                        ],
                      ),
                    ),
                    if (_isLocatingCurrentPosition) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.fetchingLocation,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mediumGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),
                    // Search button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_departureController.text.isNotEmpty &&
                              _arrivalController.text.isNotEmpty) {
                            NotificationController.instance.addExampleJourneyNotification(
                              _departureController.text,
                              _arrivalController.text,
                            );

                            context.push(
                              '/home/journey-results',
                              extra: {
                                'departure': _departureController.text,
                                'arrival': _arrivalController.text,
                              },
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    l10n.fillAllFields),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.search),
                        label: Text(l10n.searchJourney),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Recent searches
                    Text(
                      l10n.recentJourneys,
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
