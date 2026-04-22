import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import '../controllers/notification_controller.dart';
import '../controllers/journey_input_controller.dart';
import '../models/station_model.dart';
import '../services/station_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class JourneyInputScreen extends StatefulWidget {
  const JourneyInputScreen({
    super.key,
    this.stationRepository,
    this.initialStations,
  });

  final StationRepository? stationRepository;
  final List<Station>? initialStations;

  @override
  State<JourneyInputScreen> createState() => _JourneyInputScreenState();
}

class _JourneyInputScreenState extends State<JourneyInputScreen> {
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();
  final _departureFocus = FocusNode();
  final _arrivalFocus = FocusNode();

  late final StationRepository _stationRepo;
  late final JourneyInputController _journeyInputController;

  List<Station> _allStations = [];
  List<StationDistance> _nearestStations = [];
  Station? _selectedDeparture;
  Station? _selectedArrival;
  Position? _currentPosition;

  bool _isLoadingStations = true;
  bool _isSubmitting = false;
  bool _useCurrentLocation = false;
  bool _isLocatingCurrentPosition = false;
  String _manualDepartureBackup = '';

  String _currentLocationPrefix(AppLocalizations l10n) {
    return '${l10n.currentLocation}: ';
  }

  bool _isCurrentLocationText(String value, AppLocalizations l10n) {
    return value.startsWith(_currentLocationPrefix(l10n));
  }

  void _swapLocations() {
    final l10n = AppLocalizations.of(context)!;
    final departureText = _departureController.text;
    final arrivalText = _arrivalController.text;

    // Keep GPS departure pinned when current location is enabled.
    if (_useCurrentLocation && _isCurrentLocationText(departureText, l10n)) {
      _arrivalController.text = _manualDepartureBackup;
      _manualDepartureBackup = arrivalText;
      _selectedArrival = _selectedDeparture;
      setState(() {});
      return;
    }

    _departureController.text = arrivalText;
    _arrivalController.text = departureText;

    final previousDeparture = _selectedDeparture;
    _selectedDeparture = _selectedArrival;
    _selectedArrival = previousDeparture;

    if (!_useCurrentLocation) {
      _manualDepartureBackup = _departureController.text;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _stationRepo = widget.stationRepository ??
        StationRepository(FirebaseFirestore.instance);
    _journeyInputController = JourneyInputController(_stationRepo);

    // Show any preloaded stations immediately, then always refresh from Firestore
    // so newly seeded/updated station data appears in the UI.
    if (widget.initialStations != null) {
      _allStations = widget.initialStations!;
      _isLoadingStations = false;
    }
    _loadStations();
  }

  @override
  void dispose() {
    _departureController.dispose();
    _arrivalController.dispose();
    _departureFocus.dispose();
    _arrivalFocus.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    try {
      final stations = await _journeyInputController.fetchAllStations(
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _allStations = stations;
        _isLoadingStations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allStations = [];
        _isLoadingStations = false;
      });
    }
  }

  Future<void> _handleCurrentLocationToggle(bool enabled) async {
    final l10n = AppLocalizations.of(context)!;

    if (!enabled) {
      setState(() {
        _useCurrentLocation = false;
        _nearestStations = [];
        _currentPosition = null;
        if (_isCurrentLocationText(_departureController.text, l10n)) {
          _departureController.text = _manualDepartureBackup;
          _selectedDeparture = null;
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

      final nearestStations = await _journeyInputController.resolveNearestStations(position);
      if (nearestStations.isEmpty) {
        _showLocationError(l10n.noNearbyStationFromLocation);
        return;
      }

      setState(() {
        _currentPosition = position;
        _nearestStations = nearestStations;
        _selectedDeparture = nearestStations.first.station;
        _departureController.text = _currentLocationPrefix(l10n) + nearestStations.first.station.name;
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
      _nearestStations = [];
      _currentPosition = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildAutocompleteField({
    required bool isDeparture,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return RawAutocomplete<Station>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: (option) => option.name,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (isDeparture && _useCurrentLocation) {
          return const Iterable<Station>.empty();
        }
        final query = textEditingValue.text.trim();
        if (query.isEmpty) {
          return const Iterable<Station>.empty();
        }
        return _journeyInputController.suggestStationsLocally(query, _allStations);
      },
      onSelected: (Station selected) {
        setState(() {
          controller.text = selected.name;
          if (isDeparture) {
            _selectedDeparture = selected;
            if (!_useCurrentLocation) {
              _manualDepartureBackup = selected.name;
            }
          } else {
            _selectedArrival = selected;
          }
        });
      },
      fieldViewBuilder: (context, textEditingController, fieldFocusNode, onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: fieldFocusNode,
          enabled: !(isDeparture && _useCurrentLocation),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(prefixIcon),
            suffixIcon: textEditingController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      textEditingController.clear();
                      setState(() {
                        if (isDeparture) {
                          if (!_useCurrentLocation) {
                            _selectedDeparture = null;
                            _manualDepartureBackup = '';
                          }
                        } else {
                          _selectedArrival = null;
                        }
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              if (isDeparture) {
                if (!_useCurrentLocation) {
                  _manualDepartureBackup = value;
                  if (_selectedDeparture?.name != value) {
                    _selectedDeparture = null;
                  }
                }
              } else if (_selectedArrival?.name != value) {
                _selectedArrival = null;
              }
            });
          },
          textInputAction: isDeparture ? TextInputAction.next : TextInputAction.search,
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final optionsList = options.take(8).toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 72,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: optionsList.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final station = optionsList[index];
                  return ListTile(
                    dense: true,
                    title: Text(station.name),
                    subtitle: Text(station.cityId),
                    onTap: () => onSelected(station),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSearchPressed() async {
    final l10n = AppLocalizations.of(context)!;

    if (kDebugMode) {
      debugPrint(
        '[JourneyInput] submit departure="${_departureController.text}" '
        'arrival="${_arrivalController.text}" useCurrentLocation=$_useCurrentLocation',
      );
    }

    if (_departureController.text.trim().isEmpty || _arrivalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFields)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final resolution = await _journeyInputController.resolveSearch(
        departureText: _departureController.text,
        arrivalText: _arrivalController.text,
        useCurrentLocation: _useCurrentLocation,
        unableResolveCurrentLocationMessage: l10n.unableResolveCurrentLocation,
        noNearbyStationFromLocationMessage: l10n.noNearbyStationFromLocation,
        stationNotFoundBuilder: (query) => l10n.stationNotFound(query),
        stationNotFoundWithSuggestionsBuilder: (query, suggestions) =>
          l10n.stationNotFoundWithSuggestions(query, suggestions),
        currentPosition: _currentPosition,
        selectedDeparture: _selectedDeparture,
        selectedArrival: _selectedArrival,
        allStations: _allStations,
      );

      if (!mounted) return;

      if (!resolution.isReady) {
        if (kDebugMode) {
          debugPrint(
            '[JourneyInput] resolution_failed '
            'from=${resolution.fromStation?.id} to=${resolution.toStation?.id} '
            'error=${resolution.errorMessage}',
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resolution.errorMessage ?? l10n.journeySearchResolutionFailed,
            ),
          ),
        );
        return;
      }

      final from = resolution.fromStation!;
      final to = resolution.toStation!;

      if (kDebugMode) {
        debugPrint(
          '[JourneyInput] resolved fromId=${from.id} fromName=${from.name} '
          'toId=${to.id} toName=${to.name}',
        );
      }

      NotificationController.instance.addExampleJourneyNotification(
        from.name,
        to.name,
      );

      context.push(
        '/home/journey-results',
        extra: {
          'departure': from.name,
          'arrival': to.name,
          'fromStationId': from.id,
          'toStationId': to.id,
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: const Key('journey_input_screen'),
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
                          _buildAutocompleteField(
                            isDeparture: true,
                            controller: _departureController,
                            focusNode: _departureFocus,
                            hintText: l10n.departurePoint,
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _isLocatingCurrentPosition
                                  ? null
                                  : () => _handleCurrentLocationToggle(!_useCurrentLocation),
                              icon: const Icon(Icons.my_location),
                              label: Text(
                                _useCurrentLocation
                                    ? l10n.disableCurrentLocation
                                    : l10n.useCurrentLocationButton,
                              ),
                            ),
                          ),
                          if (_useCurrentLocation && _nearestStations.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _nearestStations.map((candidate) {
                                final selected = _selectedDeparture?.id == candidate.station.id;
                                return ChoiceChip(
                                  selected: selected,
                                  avatar: const Icon(Icons.location_pin, size: 16),
                                  label: Text(
                                    '${candidate.station.name} (${candidate.distanceKm.toStringAsFixed(1)} km)',
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedDeparture = candidate.station;
                                      _departureController.text = _currentLocationPrefix(l10n) +
                                          candidate.station.name;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
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
                          _buildAutocompleteField(
                            isDeparture: false,
                            controller: _arrivalController,
                            focusNode: _arrivalFocus,
                            hintText: l10n.arrivalPoint,
                            prefixIcon: Icons.location_off_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
                        onPressed: (_isLoadingStations || _isSubmitting)
                            ? null
                            : _onSearchPressed,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(l10n.searchJourney),
                      ),
                    ),
                    const SizedBox(height: 32),
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
