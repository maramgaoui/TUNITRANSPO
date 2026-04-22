import 'package:cloud_firestore/cloud_firestore.dart';

class BusService {
  final String id;
  final String routeId;
  final String? hubStationId;
  final String lineNumber;
  final String directionAr;
  final String? firstDepartureFromHub;
  final String? firstDepartureFromSuburb;
  final String? lastDepartureFromHub;
  final String? lastDepartureFromSuburb;
  final int? peakFrequencyMinutes;
  final List<int> operatingDays;
  final String season;
  final String? zone;
  final double? price;
  final String? destinationNameFr;

  const BusService({
    required this.id,
    required this.routeId,
    this.hubStationId,
    required this.lineNumber,
    required this.directionAr,
    this.firstDepartureFromHub,
    this.firstDepartureFromSuburb,
    this.lastDepartureFromHub,
    this.lastDepartureFromSuburb,
    this.peakFrequencyMinutes,
    required this.operatingDays,
    required this.season,
    this.zone,
    this.price,
    this.destinationNameFr,
  });

  factory BusService.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return BusService(
      id: doc.id,
      routeId: d['routeId'] ?? '',
      hubStationId: d['hubStationId'],
      lineNumber: d['lineNumber'] ?? '',
      directionAr: d['directionAr'] ?? '',
      firstDepartureFromHub: d['firstDepartureFromHub'],
      firstDepartureFromSuburb: d['firstDepartureFromSuburb'],
      lastDepartureFromHub: d['lastDepartureFromHub'],
      lastDepartureFromSuburb: d['lastDepartureFromSuburb'],
      peakFrequencyMinutes: d['peakFrequencyMinutes'],
      operatingDays: List<int>.from(d['operatingDays'] ?? [0, 1, 2, 3, 4, 5, 6]),
      season: d['season'] ?? '',
      zone: d['zone'],
      // Fix: TRANSTU urban fare is 0.500 DT. If price is missing in Firestore,
      // default to 0.5 for urbaine zone, else leave null.
      price: (d['price'] as num?)?.toDouble() ??
          ((d['zone'] == 'urbaine') ? 0.5 : null),
      destinationNameFr: d['destinationNameFr'],
    );
  }

  /// Returns a human-readable frequency string.
  String get frequencyLabel {
    if (peakFrequencyMinutes == null) return '';
    if (peakFrequencyMinutes! < 10) return 'Très fréquent';
    if (peakFrequencyMinutes! <= 60) {
      return 'Toutes les $peakFrequencyMinutes min';
    }
    return 'Toutes les ${peakFrequencyMinutes! ~/ 60}h';
  }

  /// Returns the zone-based price label, e.g. '0.500 DT'.
  /// Falls back to the official TRANSTU urban fare if price is unset.
  String get priceLabel {
    final effectivePrice = price ?? _defaultPriceForZone(zone);
    if (effectivePrice == null) return '';
    return '${effectivePrice.toStringAsFixed(3)} DT';
  }

  /// Returns a human-readable zone label.
  String get zoneLabel {
    switch (zone) {
      case 'urbaine':
        return 'Urbaine';
      case 'suburbaine':
        return 'Suburbaine';
      case 'longue':
        return 'Longue distance';
      default:
        return '';
    }
  }

  /// True if 24-hour service (last departure after midnight).
  bool get is24h {
    final last = lastDepartureFromHub ?? lastDepartureFromSuburb;
    if (last == null) return false;
    final h = int.tryParse(last.split(':')[0]) ?? 0;
    return h < 4 && lastDepartureFromHub != null;
  }

  /// Returns the next departure time from the hub as "HH:MM", or null if
  /// service has ended for today.
  ///
  /// Computation is based on [firstDepartureFromHub], [lastDepartureFromHub],
  /// and [peakFrequencyMinutes]. Pass [now] to override the current time
  /// (useful for testing).
  String? nextDepartureFromHub({DateTime? now}) {
    final t = now ?? DateTime.now();
    final first = _parseTime(firstDepartureFromHub);
    final last = _parseTime(lastDepartureFromHub);
    final freq = peakFrequencyMinutes;

    // If we have no schedule data, just return the raw first departure string.
    if (first == null || freq == null) return firstDepartureFromHub;

    final nowMinutes = t.hour * 60 + t.minute;

    // Service has already ended for today.
    if (last != null && nowMinutes > last) return null;

    // Walk forward from first departure in freq-minute steps until >= now.
    var dep = first;
    while (dep < nowMinutes) {
      dep += freq;
    }

    // Past the last departure.
    if (last != null && dep > last) return null;

    return '${(dep ~/ 60).toString().padLeft(2, '0')}:${(dep % 60).toString().padLeft(2, '0')}';
  }

  /// Parses "HH:MM" into total minutes from midnight. Returns null on failure.
  int? _parseTime(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return null;
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// Public wrapper so the controller can use it without duplicating logic.
  int? parseTimePublic(String? timeStr) => _parseTime(timeStr);

  /// Official TRANSTU fares by zone (2024 tariff grid).
  static double? _defaultPriceForZone(String? zone) {
    switch (zone) {
      case 'urbaine':
        return 0.5;   // 0.500 DT
      case 'suburbaine':
        return 0.8;   // 0.800 DT
      case 'longue':
        return 1.5;   // 1.500 DT (approximate average)
      default:
        return null;
    }
  }
}
