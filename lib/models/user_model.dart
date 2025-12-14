import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// User Model
/// 
/// Represents a user profile with account information, stats, and preferences.
class UserModel {
  final String id;
  final String displayName;
  final String? username;
  final String? bio;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final bool isVerified;
  final DateTime? joinedDate;
  
  // Stats
  final int propertiesCount;
  final int favoritesCount;
  final int lookingForPostsCount;
  final int likesReceived;
  final int commentsReceived;
  
  // Optional social features
  final int? followersCount;
  final int? followingCount;
  
  // Admin role
  final String? role; // 'admin', 'user', etc.

  UserModel({
    required this.id,
    required this.displayName,
    this.username,
    this.bio,
    required this.email,
    this.phone,
    this.profileImageUrl,
    this.isVerified = false,
    this.joinedDate,
    this.propertiesCount = 0,
    this.favoritesCount = 0,
    this.lookingForPostsCount = 0,
    this.likesReceived = 0,
    this.commentsReceived = 0,
    this.followersCount,
    this.followingCount,
    this.role,
  });
  
  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Creates a copy of this user with updated fields
  UserModel copyWith({
    String? id,
    String? displayName,
    String? username,
    String? bio,
    String? email,
    String? phone,
    String? profileImageUrl,
    bool? isVerified,
    DateTime? joinedDate,
    int? propertiesCount,
    int? favoritesCount,
    int? lookingForPostsCount,
    int? likesReceived,
    int? commentsReceived,
    int? followersCount,
    int? followingCount,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      joinedDate: joinedDate ?? this.joinedDate,
      propertiesCount: propertiesCount ?? this.propertiesCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      lookingForPostsCount: lookingForPostsCount ?? this.lookingForPostsCount,
      likesReceived: likesReceived ?? this.likesReceived,
      commentsReceived: commentsReceived ?? this.commentsReceived,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      role: role ?? this.role,
    );
  }

  /// Create UserModel from Firestore data
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    // Build display name from fname and lname
    String displayName = '';
    if (data['fname'] != null || data['lname'] != null) {
      final fname = data['fname'] as String? ?? '';
      final lname = data['lname'] as String? ?? '';
      displayName = '$fname $lname'.trim();
    }
    if (displayName.isEmpty && data['displayName'] != null) {
      displayName = data['displayName'] as String;
    }
    if (displayName.isEmpty && data['email'] != null) {
      displayName = (data['email'] as String).split('@')[0];
    }
    if (displayName.isEmpty) {
      displayName = 'User';
    }

    // Parse joined date
    DateTime? joinedDate;
    if (data['createdAt'] != null) {
      final timestamp = data['createdAt'];
      if (timestamp is Timestamp) {
        joinedDate = timestamp.toDate();
      } else if (timestamp is DateTime) {
        joinedDate = timestamp;
      }
    }

    // Parse username - handle both null and empty string cases
    String? username;
    if (data['username'] != null) {
      final usernameValue = data['username'];
      if (usernameValue is String && usernameValue.trim().isNotEmpty) {
        username = usernameValue.trim();
      }
    }
    
    // Debug: Log username parsing
    if (kDebugMode) {
      debugPrint('🔍 [UserModel] Parsing username from Firestore data: ${data['username']} -> $username');
    }

    return UserModel(
      id: id,
      displayName: displayName,
      username: username,
      bio: data['bio'] as String?,
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
      joinedDate: joinedDate,
      propertiesCount: (data['propertiesCount'] as num?)?.toInt() ?? 0,
      favoritesCount: (data['favoritesCount'] as num?)?.toInt() ?? 0,
      lookingForPostsCount: (data['lookingForPostsCount'] as num?)?.toInt() ?? 0,
      likesReceived: (data['likesReceived'] as num?)?.toInt() ?? 0,
      commentsReceived: (data['commentsReceived'] as num?)?.toInt() ?? 0,
      followersCount: (data['followersCount'] as num?)?.toInt(),
      followingCount: (data['followingCount'] as num?)?.toInt(),
      role: data['role'] as String?,
    );
  }

  /// Get mock user data for testing
  static UserModel getMockUser() {
    return UserModel(
      id: '1',
      displayName: 'John Doe',
      username: 'johndoe',
      bio: 'Property owner and real estate enthusiast. Always happy to help!',
      email: 'john.doe@example.com',
      phone: '+63 912 345 6789',
      profileImageUrl: null, // Will use default avatar
      isVerified: true,
      joinedDate: DateTime.now().subtract(const Duration(days: 365)),
      propertiesCount: 5,
      favoritesCount: 12,
      likesReceived: 48,
      commentsReceived: 23,
      followersCount: 120,
      followingCount: 85,
    );
  }
}

