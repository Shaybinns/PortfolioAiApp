import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String bizichatUserId;
  final String name;           // Added for display purposes
  final String? photoUrl;      // Added for profile pictures
  final DateTime createdAt;    // Added to track user account creation
  final Map<String, dynamic>? preferences; // Added for user settings

  AppUser({
    required this.id,
    required this.email,
    this.bizichatUserId = '',
    this.name = '',           // Default to empty string
    this.photoUrl,            // Optional
    DateTime? createdAt,      // Optional with default
    this.preferences,         // Optional
  }) : createdAt = createdAt ?? DateTime.now();

  // Create a User from a Firestore document
  factory AppUser.fromMap(Map<String, dynamic> map, String docId) {
    return AppUser(
      id: docId,
      email: map['email'] ?? '',
      bizichatUserId: map['bizichatUserId'] ?? '',
      name: map['name'] ?? map['email']?.toString().split('@').first ?? '', // Use email prefix as name if not provided
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] is Timestamp) 
          ? (map['createdAt'] as Timestamp).toDate() 
          : (map['createdAt'] ?? DateTime.now()),
      preferences: map['preferences'] as Map<String, dynamic>?,
    );
  }

  // Create a new AppUser during registration
  factory AppUser.initial(String id, String email, {String name = ''}) {
    return AppUser(
      id: id,
      email: email,
      name: name.isNotEmpty ? name : email.split('@').first, // Use email prefix if name not provided
      createdAt: DateTime.now(),
      preferences: {},
    );
  }

  // Convert a User object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'bizichatUserId': bizichatUserId,
      'name': name,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'preferences': preferences ?? {},
    };
  }

  // Set or update the Bizichat user ID
  AppUser withBizichatUserId(String id) {
    return copyWith(bizichatUserId: id);
  }

  // Create a copy of AppUser with modifications
  AppUser copyWith({
    String? id,
    String? email,
    String? bizichatUserId,
    String? name,
    String? photoUrl,
    DateTime? createdAt,
    Map<String, dynamic>? preferences,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      bizichatUserId: bizichatUserId ?? this.bizichatUserId,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      preferences: preferences ?? this.preferences,
    );
  }
}