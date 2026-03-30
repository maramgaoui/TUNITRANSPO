import 'user_model.dart';

class Profile {
  final String uid;
  final String email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? country;
  final String? bio;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.uid,
    required this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.phoneNumber,
    this.address,
    this.city,
    this.country,
    this.bio,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert Profile to JSON for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'country': country,
      'bio': bio,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create Profile from Firestore document
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      city: map['city'],
      country: map['country'],
      bio: map['bio'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  // Create Profile from User model
  factory Profile.fromUser(User user) {
    return Profile(
      uid: user.uid,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  // Copy with method for updates
  Profile copyWith({
    String? uid,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? phoneNumber,
    String? address,
    String? city,
    String? country,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      bio: bio ?? this.bio,
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
    return 'User';
  }
}
