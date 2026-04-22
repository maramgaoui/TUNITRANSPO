import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'journey_search_state.dart';
import '../models/bus_service_model.dart';
import '../services/station_repository.dart';
import '../services/route_repository.dart';
import '../services/journey_repository.dart';
import '../services/bus_service_repository.dart';

class JourneySearchController extends ChangeNotifier {
  final StationRepository _stationRepository;
  final JourneyRepository _journeyRepository;
  final BusServiceRepository _busServiceRepository;

  JourneySearchState _state = const JourneySearchState();
  JourneySearchState get state => _state;

  JourneySearchController({
    StationRepository? stationRepository,
    JourneyRepository? journeyRepository,
    BusServiceRepository? busServiceRepository,
  })  : _stationRepository = stationRepository ??
            StationRepository(FirebaseFirestore.instance),
        _journeyRepository = journeyRepository ??
            JourneyRepository(
              FirebaseFirestore.instance,
              RouteRepository(FirebaseFirestore.instance),
            ),
        _busServiceRepository =
            busServiceRepository ?? BusServiceRepository();

  static const Set<String> _bnCanonicalStationIds = {
    'bn_tunis',
    'bn_borj_cedria',
    'bn_foundouk_jedid',
    'bn_khanguet',
    'bn_grombalia',
    'bn_turki',
    'bn_belli',
    'bn_bou_arkoub',
    'bn_bir_bou_regba',
    'bn_hammamet',
    'bn_omar_khayem',
    'bn_mrazga',
    'bn_nabeul',
  };

  static const Map<String, String> _bnLegacyIdMap = {
    'sncft_bir_bou_regba': 'bn_bir_bou_regba',
    'bs_bir_el_bey': 'bn_bir_bou_regba',
    'bs_boukornine': 'bn_grombalia',
    'bs_hammam_lif': 'bn_hammamet',
    'bs_hammam_echatt': 'bn_hammamet',
    'bs_ezzahra': 'bn_grombalia',
    'bs_tunis_ville': 'bn_tunis',
  };

  static const Set<String> _bnDeprecatedStationIds = {
    'sncft_grombalia',
  };

  /// Emits a new state and notifies listeners in one call.
  void _emit(JourneySearchState newState) {
    _state = newState;
    notifyListeners();
  }

  bool _isBnStationSet(String fromStationId, String toStationId) {
    return _bnCanonicalStationIds.contains(fromStationId) &&
        _bnCanonicalStationIds.contains(toStationId);
  }

  /// Maps a legacy station ID to its canonical BN equivalent, if any.
  String _normalizeBnLegacyStationId(String stationId) {
    return _bnLegacyIdMap[stationId] ?? stationId;
  }

  /// Remaps bn_tunis → bs_tunis_ville when the other station is a Banlieue Sud
  /// station (bs_ prefix), so the correct shared-hub ID is used.
  String _normalizeSharedTunisForBanlieueSud(
    String stationId,
    String otherStationId,
  ) {
    if (stationId == 'bn_tunis' && otherStationId.startsWith('bs_')) {
      return 'bs_tunis_ville';
    }
    return stationId;
  }

  Future<void> search({
    required String fromStationId,
    required String toStationId,
  }) async {
    // Reject deprecated station IDs immediately with a clear message.
    if (_bnDeprecatedStationIds.contains(fromStationId) ||
        _bnDeprecatedStationIds.contains(toStationId)) {
      _emit(_state.copyWith(
        isLoading: false,
        clearMetro: true,
        error:
            'Station BN ancienne détectée. Veuillez re-sélectionner les stations depuis la recherche (ex: Bir El Bey, Bou Kornine, Hammam Chott).',
      ));
      return;
    }

    // Step 1 — map legacy IDs to canonical BN IDs, independently for each.
    final rawFromNormalized = _normalizeBnLegacyStationId(fromStationId);
    final rawToNormalized = _normalizeBnLegacyStationId(toStationId);

    // Step 2 — remap bn_tunis → bs_tunis_ville when paired with a bs_ station.
    // Both calls use the raw-normalized values (symmetric, no ordering dependency).
    final normalizedFromStationId = _normalizeSharedTunisForBanlieueSud(
      rawFromNormalized,
      rawToNormalized,
    );
    final normalizedToStationId = _normalizeSharedTunisForBanlieueSud(
      rawToNormalized,
      rawFromNormalized,
    );

    if (kDebugMode) {
      debugPrint(
        '[JourneySearch] start from=$fromStationId to=$toStationId '
        'normalizedFrom=$normalizedFromStationId normalizedTo=$normalizedToStationId',
      );
    }

    _emit(_state.copyWith(
      isLoading: true,
      clearMetro: true,
      clearError: true,
      clearBus: true,
      clearBestBus: true,
    ));

    try {
      // Parallel Firestore reads — both station lookups run concurrently.
      final results = await Future.wait([
        _stationRepository.getStationById(normalizedFromStationId),
        _stationRepository.getStationById(normalizedToStationId),
      ]);
      final fromStation = results[0];
      final toStation = results[1];

      if (fromStation == null || toStation == null) {
        _emit(_state.copyWith(isLoading: false, error: 'Station introuvable.'));
        return;
      }

      if (kDebugMode) {
        debugPrint(
          '[JourneySearch] resolved from=${fromStation.id} to=${toStation.id}',
        );
      }

      // Capture search time once so all branches use the same reference time.
      final searchDateTime = DateTime.now();

      // ═══════════════════════════════════════════════════════════════════════
      // BRANCH ORDER IS SIGNIFICANT — DO NOT REORDER WITHOUT CAREFUL REVIEW.
      // A station may belong to multiple operator types (e.g. bs_tunis_ville
      // serves both Banlieue Sud and SNCFT mainline). The first branch that
      // returns a non-null result wins. Banlieue Nabeul is checked first as a
      // priority override for its overlapping station IDs.
      // ═══════════════════════════════════════════════════════════════════════

      // Banlieue Nabeul — priority path for overlapping station ID sets.
      if (_isBnStationSet(fromStation.id, toStation.id)) {
        if (kDebugMode) {
          debugPrint('[JourneySearch] branch=banlieue_nabeul (priority)');
        }
        final bnResult = await _journeyRepository.findNextBanlieueNabeulTrip(
          fromStationId: fromStation.id,
          toStationId: toStation.id,
          searchDateTime: searchDateTime,
        );
        if (bnResult != null) {
          _emit(_state.copyWith(isLoading: false, metroSahelResult: bnResult));
          return;
        }
      }

      // Métro du Sahel.
      if (_stationRepository.isMetroSahelStation(fromStation) &&
          _stationRepository.isMetroSahelStation(toStation)) {
        final metroResult = await _journeyRepository.findNextMetroSahelTrip(
          fromStationId: fromStation.id,
          toStationId: toStation.id,
          searchDateTime: searchDateTime,
        );
        if (metroResult != null) {
          _emit(_state.copyWith(isLoading: false, metroSahelResult: metroResult));
          return;
        }
      }

      // Banlieue Sud.
      if (_stationRepository.isBanlieueSudStation(fromStation) &&
          _stationRepository.isBanlieueSudStation(toStation)) {
        final bsResult = await _journeyRepository.findNextBanlieueSudTrip(
          fromStationId: fromStation.id,
          toStationId: toStation.id,
          searchDateTime: searchDateTime,
        );
        if (bsResult != null) {
          _emit(_state.copyWith(isLoading: false, metroSahelResult: bsResult));
          return;
        }
      }

      // Banlieue Ligne D.
      if (_stationRepository.isBanlieueDStation(fromStation) &&
          _stationRepository.isBanlieueDStation(toStation)) {
        final bdResult = await _journeyRepository.findNextBanlieueDTrip(
          fromStationId: fromStation.id,
          toStationId: toStation.id,
          searchDateTime: searchDateTime,
        );
        if (bdResult != null) {
          _emit(_state.copyWith(isLoading: false, metroSahelResult: bdResult));
          return;
        }
      }

      // Banlieue Ligne E.
      if (_stationRepository.isBanlieueEStation(fromStation) &&
          _stationRepository.isBanlieueEStation(toStation)) {
        final beResult = await _journeyRepository.findNextBanlieueETrip(
          fromStationId: fromStation.id,
          toStationId: toStation.id,
          searchDateTime: searchDateTime,
        );
        if (beResult != null) {
          _emit(_state.copyWith(isLoading: false, metroSahelResult: beResult));
          return;
        }
      }

      // SNCFT Grandes Lignes (L5, Kef, Bizerte, Annaba…).
      if (_stationRepository.isSncftMainlineStation(fromStation) &&
          _stationRepository.isSncftMainlineStation(toStation)) {
        final sncftResult = await _journeyRepository.findNextSncftL5Trip(
          fromStationId: fromStation.id,
          toStationId: toStation.id,
          searchDateTime: searchDateTime,
        );
        if (sncftResult != null) {
          _emit(_state.copyWith(isLoading: false, metroSahelResult: sncftResult));
          return;
        }
      }

      // ─── TRANSTU bus — departure must be a TRANSTU hub. ──────────────────
      if (_stationRepository.isTranstuStation(fromStation)) {
        if (kDebugMode) {
          debugPrint('[JourneySearch] branch=transtu hub=${fromStation.id}');
        }

        final busServices =
            await _busServiceRepository.findServicesConnectingStations(
          fromStationId: fromStation.id,
          toStationId: toStation.id,
        );

        if (busServices.isNotEmpty) {
          // Find the soonest departure across all matching services.
          // bestMinutes is -1 (invalid) until bestService is first assigned;
          // the bestService == null guard ensures it is never compared while invalid.
          BusService? bestService;
          String? bestTime;
          int bestMinutes = -1;

          for (final svc in busServices) {
            final nextDep = svc.nextDepartureFromHub(now: searchDateTime);
            if (nextDep == null) continue; // service ended for today

            final parts = nextDep.split(':');
            if (parts.length != 2) continue;

            final h = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            if (h == null || m == null) {
              if (kDebugMode) {
                debugPrint(
                  '[JourneySearch] Invalid time format: $nextDep '
                  'for service ${svc.id}',
                );
              }
              continue;
            }

            final depMins = h * 60 + m;
            if (bestService == null || depMins < bestMinutes) {
              bestMinutes = depMins;
              bestService = svc;
              bestTime = nextDep;
            }
          }

          if (bestService != null) {
            _emit(_state.copyWith(
              isLoading: false,
              clearBus: true,
              bestBusService: bestService,
              bestBusDepartureTime: bestTime,
              busHubName:
                  '${fromStation.localizedName('fr')} → ${toStation.localizedName('fr')}',
            ));
            return;
          }

          // All services ended for today — show the earliest departure tomorrow.
          final sorted = List<BusService>.from(busServices)
            ..sort((BusService a, BusService b) =>
                (a.parseTimePublic(a.firstDepartureFromHub) ?? 9999).compareTo(
                    b.parseTimePublic(b.firstDepartureFromHub) ?? 9999));

          _emit(_state.copyWith(
            isLoading: false,
            clearBus: true,
            bestBusService: sorted.first,
            bestBusDepartureTime: sorted.first.firstDepartureFromHub,
            busHubName:
                '${fromStation.localizedName('fr')} → ${toStation.localizedName('fr')}',
            error: 'Service terminé pour ce soir. Prochain départ demain.',
          ));
          return;
        }

        // Hub found but no connecting lines to the destination.
        if (kDebugMode) {
          debugPrint(
            '[JourneySearch] No connecting lines found from '
            '${fromStation.name} to ${toStation.name}',
          );
        }
        _emit(_state.copyWith(
          isLoading: false,
          clearMetro: true,
          error: 'Aucune ligne ne relie ${fromStation.name} à ${toStation.name}.',
        ));
        return;
      }

      // No branch matched — stations exist but share no common line.
      if (kDebugMode) {
        debugPrint(
          '[JourneySearch] no branch matched for from=$fromStationId '
          'to=$toStationId normalizedFrom=$normalizedFromStationId '
          'normalizedTo=$normalizedToStationId',
        );
      }
      _emit(_state.copyWith(
        isLoading: false,
        clearMetro: true,
        error: 'Ces stations n\'appartiennent pas à la même ligne.',
      ));
    } catch (e) {
      // Map exceptions to user-friendly French messages.
      // Raw exception text is only visible in debug logs, never shown in the UI.
      final userMessage = switch (e) {
        final FirebaseException e => switch (e.code) {
            'unavailable' || 'network-request-failed' || 'failed' =>
              'Connexion impossible. Vérifiez votre connexion réseau.',
            'permission-denied' =>
              'Accès non autorisé. Veuillez réessayer plus tard.',
            'not-found' => 'Données introuvables. Veuillez réessayer.',
            _ => 'Une erreur est survenue. Veuillez réessayer.',
          },
        _ => 'Une erreur inattendue est survenue. Veuillez réessayer.',
      };

      if (kDebugMode) debugPrint('[JourneySearch] error=$e');
      _emit(_state.copyWith(isLoading: false, error: userMessage));
    }
  }
}