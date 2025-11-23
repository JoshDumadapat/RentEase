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
  final int likesReceived;
  final int commentsReceived;
  
  // Optional social features
  final int? followersCount;
  final int? followingCount;

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
    this.likesReceived = 0,
    this.commentsReceived = 0,
    this.followersCount,
    this.followingCount,
  });

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
    int? likesReceived,
    int? commentsReceived,
    int? followersCount,
    int? followingCount,
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
      likesReceived: likesReceived ?? this.likesReceived,
      commentsReceived: commentsReceived ?? this.commentsReceived,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
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

