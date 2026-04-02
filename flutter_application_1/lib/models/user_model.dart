class User {
  final String uid;
  final String email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? avatarId;
  final String? city;

  User({
    required this.uid,
    required this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.avatarId,
    this.city,
  });

  // Convert User to JSON for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'avatarId': avatarId,
      'city': city,
    };
  }

  // Create User from Firestore document
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      avatarId: map['avatarId'],
      city: map['city'],
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
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarId: avatarId ?? this.avatarId,
      city: city ?? this.city,
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
