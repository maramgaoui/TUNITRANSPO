import 'package:equatable/equatable.dart';
import '../models/bus_service_model.dart';
import '../models/metro_sahel_result.dart';

class JourneySearchState extends Equatable {
  final bool isLoading;
  final String? error;
  final MetroSahelResult? metroSahelResult;
  final List<BusService>? busServices;   // full timetable list (hub → hub)
  final BusService? bestBusService;      // single "next bus" result
  final String? bestBusDepartureTime;    // computed next departure "HH:MM"
  final String? busHubName;              // display name for best bus result

  const JourneySearchState({
    this.isLoading = false,
    this.error,
    this.metroSahelResult,
    this.busServices,
    this.bestBusService,
    this.bestBusDepartureTime,
    this.busHubName,
  });

  // ── Convenience getters for UI state checks ──────────────────────────────

  /// True when at least one result (train or bus) is available to display.
  bool get hasResult => metroSahelResult != null || bestBusService != null;

  /// True when not loading, no error, and no result — initial/reset state.
  bool get isEmpty => !isLoading && error == null && !hasResult;

  /// True when an error message is present.
  bool get hasError => error != null;

  // ── Equatable ─────────────────────────────────────────────────────────────

  /// Equatable uses DeepCollectionEquality for List fields in props,
  /// so busServices is compared by content, not by reference.
  @override
  List<Object?> get props => [
        isLoading,
        error,
        metroSahelResult,
        busServices,
        bestBusService,
        bestBusDepartureTime,
        busHubName,
      ];

  /// Enables readable toString() output for debugPrint and Flutter DevTools.
  @override
  bool get stringify => true;

  // ── copyWith ──────────────────────────────────────────────────────────────

  /// The clearX flags exist because null is a valid target value for nullable
  /// fields — without them there is no way to distinguish "set to null" from
  /// "keep existing value" through a nullable parameter alone.
  ///
  /// Grouping:
  ///   clearError    → clears error only
  ///   clearMetro    → clears metroSahelResult only
  ///   clearBus      → clears busServices only
  ///   clearBestBus  → clears bestBusService + bestBusDepartureTime + busHubName
  JourneySearchState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    MetroSahelResult? metroSahelResult,
    bool clearMetro = false,
    List<BusService>? busServices,
    bool clearBus = false,
    BusService? bestBusService,
    String? bestBusDepartureTime,
    bool clearBestBus = false,
    String? busHubName,
  }) {
    return JourneySearchState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      metroSahelResult:
          clearMetro ? null : (metroSahelResult ?? this.metroSahelResult),
      busServices: clearBus ? null : (busServices ?? this.busServices),
      bestBusService:
          clearBestBus ? null : (bestBusService ?? this.bestBusService),
      bestBusDepartureTime: clearBestBus
          ? null
          : (bestBusDepartureTime ?? this.bestBusDepartureTime),
      busHubName: clearBestBus ? null : (busHubName ?? this.busHubName),
    );
  }
}