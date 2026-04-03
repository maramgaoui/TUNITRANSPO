class Journey {
  final String id;
  final String departureStation;
  final String arrivalStation;
  final String departureTime;
  final String price;
  final bool isFavorite;

  // Additional metadata used by current UI screens.
  final String type;
  final String iconKey;
  final String? arrivalTime;
  final String? transferStation;
  final String? transferTime;
  final String duration;
  final int transfers;
  final bool isOptimal;
  final String operator;
  final String line;

  Journey({
    required this.id,
    required this.departureStation,
    required this.arrivalStation,
    required this.departureTime,
    required this.price,
    this.isFavorite = false,
    required this.type,
    required this.iconKey,
    this.arrivalTime,
    this.transferStation,
    this.transferTime,
    required this.duration,
    required this.transfers,
    required this.isOptimal,
    required this.operator,
    required this.line,
  });

  // Backward-compatible aliases used by existing screens.
  String get departure => departureTime;
  String get arrival => arrivalTime ?? '';

  Journey copyWith({
    String? id,
    String? departureStation,
    String? arrivalStation,
    String? departureTime,
    String? price,
    bool? isFavorite,
    String? type,
    String? iconKey,
    String? arrivalTime,
    String? transferStation,
    String? transferTime,
    String? duration,
    int? transfers,
    bool? isOptimal,
    String? operator,
    String? line,
  }) {
    return Journey(
      id: id ?? this.id,
      departureStation: departureStation ?? this.departureStation,
      arrivalStation: arrivalStation ?? this.arrivalStation,
      departureTime: departureTime ?? this.departureTime,
      price: price ?? this.price,
      isFavorite: isFavorite ?? this.isFavorite,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      transferStation: transferStation ?? this.transferStation,
      transferTime: transferTime ?? this.transferTime,
      duration: duration ?? this.duration,
      transfers: transfers ?? this.transfers,
      isOptimal: isOptimal ?? this.isOptimal,
      operator: operator ?? this.operator,
      line: line ?? this.line,
    );
  }

  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      id: (json['id'] ?? '').toString(),
      departureStation: (json['departureStation'] ?? '').toString(),
      arrivalStation: (json['arrivalStation'] ?? '').toString(),
      departureTime: (json['departureTime'] ?? json['departure'] ?? '').toString(),
      price: (json['price'] ?? '').toString(),
      isFavorite: (json['isFavorite'] ?? false) == true,
      type: (json['type'] ?? 'Trajet').toString(),
      iconKey: (json['iconKey'] ?? 'bus').toString(),
      arrivalTime: json['arrivalTime']?.toString() ?? json['arrival']?.toString(),
      transferStation: json['transferStation']?.toString(),
      transferTime: json['transferTime']?.toString(),
      duration: (json['duration'] ?? '').toString(),
      transfers: (json['transfers'] ?? 0) is int
          ? (json['transfers'] ?? 0) as int
          : int.tryParse((json['transfers'] ?? '0').toString()) ?? 0,
      isOptimal: (json['isOptimal'] ?? false) == true,
      operator: (json['operator'] ?? '').toString(),
      line: (json['line'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'departureStation': departureStation,
      'arrivalStation': arrivalStation,
      'departureTime': departureTime,
      'price': price,
      'isFavorite': isFavorite,
      'type': type,
      'iconKey': iconKey,
      'arrivalTime': arrivalTime,
      'transferStation': transferStation,
      'transferTime': transferTime,
      'duration': duration,
      'transfers': transfers,
      'isOptimal': isOptimal,
      'operator': operator,
      'line': line,
    };
  }
}
