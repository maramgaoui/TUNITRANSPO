class User {
  final String uid;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    required this.uid,
    required this.email,
    this.firstName,
    this.lastName,
    this.photoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert User to JSON for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create User from Firestore document
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'],
      lastName: map['lastName'],
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  // Copy with method for updates
  User copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
