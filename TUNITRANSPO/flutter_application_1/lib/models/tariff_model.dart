import 'package:cloud_firestore/cloud_firestore.dart';

class Tariff {
  final String id;
  final String operatorId;
  final String fromStationId;
  final String toStationId;
  final double price; // in TND
  final String currency;
  final String? tariffClass; // economy, comfort, vip
  final DateTime validFrom;
  final DateTime? validTo;
  final String? notes;
  final List<SpecialDiscount> specialDiscounts;
  final DateTime createdAt;

  const Tariff({
    required this.id,
    required this.operatorId,
    required this.fromStationId,
    required this.toStationId,
    required this.price,
    this.currency = 'TND',
    this.tariffClass,
    required this.validFrom,
    this.validTo,
    this.notes,
    required this.specialDiscounts,
    required this.createdAt,
  });

  /// Convert from Firestore document
  factory Tariff.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Tariff(
      id: doc.id,
      operatorId: data['operatorId'] ?? '',
      fromStationId: data['fromStationId'] ?? '',
      toStationId: data['toStationId'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'TND',
      tariffClass: data['tariffClass'],
      validFrom: (data['validFrom'] as Timestamp).toDate(),
      validTo: (data['validTo'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      specialDiscounts: (data['specialDiscounts'] as List?)
              ?.map((d) => SpecialDiscount.fromMap(Map<String, dynamic>.from(d)))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() => {
        'operatorId': operatorId,
        'fromStationId': fromStationId,
        'toStationId': toStationId,
        'price': price,
        'currency': currency,
        'tariffClass': tariffClass,
        'validFrom': Timestamp.fromDate(validFrom),
        'validTo': validTo != null ? Timestamp.fromDate(validTo!) : null,
        'notes': notes,
        'specialDiscounts': specialDiscounts.map((d) => d.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Metro Sahel pricing formula:
  /// Base: 0.550 TND for 1-3 stops
  /// Every additional 3 stops: +0.250 TND
  /// Formula: price(n) = 0.550 + floor((n-1) / 3) * 0.250
  static double calculateMetroSahelPrice(int numberOfStops) {
    if (numberOfStops <= 0) return 0.0;
    final basePrice = 0.550;
    final incrementPrice = 0.250;
    final additionalIncrements = ((numberOfStops - 1) / 3).floor();
    return basePrice + (additionalIncrements * incrementPrice);
  }

  /// Calculate final price with discounts
  double calculateFinalPrice({
    int quantity = 1,
    bool isStudent = false,
    bool isSenior = false,
  }) {
    double finalPrice = price * quantity;

    for (final discount in specialDiscounts) {
      if (discount.appliesToQuantity(quantity) &&
          ((discount.condition == 'student' && isStudent) ||
              (discount.condition == 'senior' && isSenior) ||
              (discount.condition == 'group' && quantity > 1) ||
              discount.condition == 'return')) {
        final discountAmount = finalPrice * (discount.discountPercentage / 100);
        finalPrice -= discountAmount;
      }
    }

    return double.parse(finalPrice.toStringAsFixed(3)); // 3 decimal places
  }

  /// Check if tariff is valid on a given date
  bool isValidOn(DateTime date) {
    return date.isAfter(validFrom.subtract(const Duration(days: 1))) &&
        (validTo == null || date.isBefore(validTo!.add(const Duration(days: 1))));
  }

  /// Format price for display
  String get formattedPrice => '${price.toStringAsFixed(3)} $currency';

  /// Copy with some fields modified
  Tariff copyWith({
    String? id,
    String? operatorId,
    String? fromStationId,
    String? toStationId,
    double? price,
    String? currency,
    String? tariffClass,
    DateTime? validFrom,
    DateTime? validTo,
    String? notes,
    List<SpecialDiscount>? specialDiscounts,
    DateTime? createdAt,
  }) {
    return Tariff(
      id: id ?? this.id,
      operatorId: operatorId ?? this.operatorId,
      fromStationId: fromStationId ?? this.fromStationId,
      toStationId: toStationId ?? this.toStationId,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      tariffClass: tariffClass ?? this.tariffClass,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      notes: notes ?? this.notes,
      specialDiscounts: specialDiscounts ?? this.specialDiscounts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Tariff($fromStationId → $toStationId: ${formattedPrice})';
}

class SpecialDiscount {
  final String condition; // student, senior, group, return
  final double discountPercentage;
  final int? minQuantity;
  final DateTime? validFrom;
  final DateTime? validTo;

  const SpecialDiscount({
    required this.condition,
    required this.discountPercentage,
    this.minQuantity,
    this.validFrom,
    this.validTo,
  });

  factory SpecialDiscount.fromMap(Map<String, dynamic> map) {
    return SpecialDiscount(
      condition: map['condition'] ?? '',
      discountPercentage: (map['discountPercentage'] ?? 0.0).toDouble(),
      minQuantity: map['minQuantity'],
      validFrom: (map['validFrom'] as Timestamp?)?.toDate(),
      validTo: (map['validTo'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'condition': condition,
        'discountPercentage': discountPercentage,
        'minQuantity': minQuantity,
        'validFrom': validFrom != null ? Timestamp.fromDate(validFrom!) : null,
        'validTo': validTo != null ? Timestamp.fromDate(validTo!) : null,
      };

  bool appliesToQuantity(int quantity) {
    return minQuantity == null || quantity >= minQuantity!;
  }
}
