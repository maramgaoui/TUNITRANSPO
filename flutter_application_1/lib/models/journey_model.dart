class Journey {
  final String type;
  final String iconKey;
  final String departure;
  final String arrival;
  final String departureStation;
  final String arrivalStation;
  final String? transferStation;
  final String? transferTime;
  final String duration;
  final String price;
  final int transfers;
  final bool isOptimal;
  final String operator;
  final String line;

  Journey({
    required this.type,
    required this.iconKey,
    required this.departure,
    required this.arrival,
    required this.departureStation,
    required this.arrivalStation,
    this.transferStation,
    this.transferTime,
    required this.duration,
    required this.price,
    required this.transfers,
    required this.isOptimal,
    required this.operator,
    required this.line,
  });
}
