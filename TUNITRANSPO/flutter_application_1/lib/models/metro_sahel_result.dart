import '../models/journey_model.dart';

class MetroSahelResult {
  final int tripNumber;
  final String routeName;
  final String fromStationId;
  final String toStationId;
  final String fromStationName;
  final String toStationName;
  final String departureTime;
  final String arrivalTime;
  final int durationMinutes;
  final double price;
  final int numberOfStops;

  final String operatorName;
  final String operatorPhone;
  final String lineType;
  /// String trip number for operators that use alphanumeric trip numbers (e.g. SNCFT "5-13/57").
  /// When set, this is shown in the UI instead of [tripNumber].
  final String? tripNumberStr;

  static const String currency = 'TND';

  const MetroSahelResult({
    required this.tripNumber,
    required this.routeName,
    required this.fromStationId,
    required this.toStationId,
    required this.fromStationName,
    required this.toStationName,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationMinutes,
    required this.price,
    required this.numberOfStops,
    this.operatorName = 'Métro du Sahel - SNCFT',
    this.operatorPhone = '+216 73 447 425',
    this.lineType = 'metro_sahel',
    this.tripNumberStr,
  });

  bool get noTrainToday => arrivalTime == 'TOMORROW';

  /// Convert to Journey for favorites / active-journey compatibility.
  Journey toJourney() {
    return Journey(
      id: '${lineType}_$tripNumber',
      departureStation: fromStationName,
      arrivalStation: toStationName,
      departureTime: departureTime,
      arrivalTime: noTrainToday ? null : arrivalTime,
      price: price.toStringAsFixed(3),
      type: operatorName,
      iconKey: 'train',
      duration: '${durationMinutes} min',
      transfers: 0,
      isOptimal: true,
      operator: operatorName,
      line: tripNumberStr != null ? 'Train $tripNumberStr' : 'Train $tripNumber',
    );
  }
}
