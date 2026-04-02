import 'user_model.dart';

class Profile {
  final String uid;
  final String email;
  final String? username;
  final String? avatarId;
  final String? firstName;
  final String? lastName;
  final String? city;

  Profile({
    required this.uid,
    required this.email,
    this.username,
    this.avatarId,
    this.firstName,
    this.lastName,
    this.city,
  });

  // Convert Profile to JSON for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'avatarId': avatarId,
      'firstName': firstName,
      'lastName': lastName,
      'city': city,
    };
  }

  // Create Profile from Firestore document
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'],
      avatarId: map['avatarId'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      city: map['city'],
    );
  }

  // Create Profile from User model
  factory Profile.fromUser(User user) {
    return Profile(
      uid: user.uid,
      email: user.email,
      username: user.username,
      avatarId: user.avatarId,
      firstName: user.firstName,
      lastName: user.lastName,
      city: user.city,
    );
  }

  // Copy with method for updates
  Profile copyWith({
    String? uid,
    String? email,
    String? username,
    String? avatarId,
    String? firstName,
    String? lastName,
    String? city,
  }) {
    return Profile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarId: avatarId ?? this.avatarId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
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
    return 'User';
  }
}
