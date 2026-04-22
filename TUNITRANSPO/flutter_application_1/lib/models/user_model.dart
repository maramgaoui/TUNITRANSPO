class User {
  final String uid;
  final String email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? avatarId;
  final String? city;
  final String status;
  final DateTime? banUntil;

  User({
    required this.uid,
    required this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.avatarId,
    this.city,
    this.status = 'active',
    this.banUntil,
  });

  // Convert User to JSON for Firestore
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'email': email,
    };
    if (username != null) map['username'] = username;
    if (firstName != null) map['firstName'] = firstName;
    if (lastName != null) map['lastName'] = lastName;
    if (avatarId != null) map['avatarId'] = avatarId;
    if (city != null) map['city'] = city;
    map['status'] = status;
    if (banUntil != null) map['banUntil'] = banUntil!.toIso8601String();
    return map;
  }

  // Create User from Firestore document
  factory User.fromMap(Map<String, dynamic> map) {
    DateTime? parsedBanUntil;
    final banRaw = map['banUntil'];
    if (banRaw is DateTime) {
      parsedBanUntil = banRaw;
    } else if (banRaw is String && banRaw.isNotEmpty) {
      parsedBanUntil = DateTime.tryParse(banRaw);
    }
    // Firestore Timestamp support (imported as dynamic from cloud_firestore)
    if (banRaw != null && parsedBanUntil == null) {
      try {
        parsedBanUntil = (banRaw as dynamic).toDate() as DateTime;
      } catch (_) {}
    }

    return User(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      avatarId: map['avatarId'],
      city: map['city'],
      status: (map['status'] ?? 'active').toString(),
      banUntil: parsedBanUntil,
    );
  }

  // Copy with method for updates
  User copyWith({
    String? uid,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? avatarId,
    String? city,
    String? status,
    DateTime? banUntil,
    bool clearBanUntil = false,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarId: avatarId ?? this.avatarId,
      city: city ?? this.city,
      status: status ?? this.status,
      banUntil: clearBanUntil ? null : (banUntil ?? this.banUntil),
    );
  }

  // Get full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return email;
  }

  @override
  String toString() =>
      'User(uid: $uid, email: $email, name: $fullName)';
}
