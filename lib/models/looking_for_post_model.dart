import 'package:cloud_firestore/cloud_firestore.dart';

class LookingForPostModel {
  final String id;
  final String? userId; // User ID who created the post
  final String username;
  final String description;
  final String location;
  final String budget;
  final String date;
  final String propertyType;
  final DateTime? moveInDate;
  final DateTime postedDate;
  final bool isVerified;
  final int likeCount;
  final int commentCount;

  LookingForPostModel({
    required this.id,
    this.userId,
    required this.username,
    required this.description,
    required this.location,
    required this.budget,
    required this.date,
    required this.propertyType,
    this.moveInDate,
    required this.postedDate,
    this.isVerified = false,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(postedDate);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Create LookingForPostModel from Firestore data
  factory LookingForPostModel.fromMap(Map<String, dynamic> data) {
    // Parse postedDate/createdAt
    DateTime postedDate;
    if (data['postedDate'] != null) {
      if (data['postedDate'] is Timestamp) {
        postedDate = (data['postedDate'] as Timestamp).toDate();
      } else if (data['postedDate'] is DateTime) {
        postedDate = data['postedDate'] as DateTime;
      } else {
        postedDate = DateTime.now();
      }
    } else if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        postedDate = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is DateTime) {
        postedDate = data['createdAt'] as DateTime;
      } else {
        postedDate = DateTime.now();
      }
    } else {
      postedDate = DateTime.now();
    }

    // Parse moveInDate
    DateTime? moveInDate;
    if (data['moveInDate'] != null) {
      if (data['moveInDate'] is Timestamp) {
        moveInDate = (data['moveInDate'] as Timestamp).toDate();
      } else if (data['moveInDate'] is DateTime) {
        moveInDate = data['moveInDate'] as DateTime;
      }
    }

    // Format date string from postedDate
    final dateStr = '${postedDate.month}/${postedDate.day}';

    return LookingForPostModel(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String?,
      username: data['username'] as String? ?? 'Unknown',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      budget: data['budget'] as String? ?? '',
      date: dateStr,
      propertyType: data['propertyType'] as String? ?? 'Apartment',
      moveInDate: moveInDate,
      postedDate: postedDate,
      isVerified: data['isVerified'] as bool? ?? false,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
    );
  }

  static List<LookingForPostModel> getMockLookingForPosts() {
    final now = DateTime.now();
    return [
      LookingForPostModel(
        id: '1',
        username: 'Rica',
        description: 'Looking for a 2-bedroom apartment near SM Seaside. Preferably furnished with good ventilation and natural light. Must be pet-friendly!',
        location: 'Cebu City',
        budget: '₱10,000-₱12,000',
        date: 'Nov 25',
        propertyType: 'Apartment',
        moveInDate: DateTime(2024, 11, 25),
        postedDate: now.subtract(const Duration(hours: 2)),
        isVerified: true,
        likeCount: 24,
        commentCount: 8,
      ),
      LookingForPostModel(
        id: '2',
        username: 'Mark',
        description: 'Looking for a studio condo in IT Park. Close to work and public transport. Budget is flexible for the right place.',
        location: 'Cebu City',
        budget: '₱7,000-₱9,000',
        date: 'Nov 24',
        propertyType: 'Condo',
        moveInDate: DateTime(2024, 11, 24),
        postedDate: now.subtract(const Duration(hours: 5)),
        isVerified: false,
        likeCount: 12,
        commentCount: 3,
      ),
      LookingForPostModel(
        id: '3',
        username: 'Sarah',
        description: 'Need a room near university campus, preferably with WiFi and study area. Quiet environment preferred for studying.',
        location: 'Manila',
        budget: '₱3,000-₱5,000',
        date: 'Nov 23',
        propertyType: 'Rooms',
        moveInDate: DateTime(2024, 12, 1),
        postedDate: now.subtract(const Duration(days: 1)),
        isVerified: true,
        likeCount: 18,
        commentCount: 5,
      ),
      LookingForPostModel(
        id: '4',
        username: 'James',
        description: 'Looking for a 3-bedroom house with parking space for family. Must have a yard for kids to play. Long-term lease preferred.',
        location: 'Quezon City',
        budget: '₱15,000-₱20,000',
        date: 'Nov 22',
        propertyType: 'House Rentals',
        moveInDate: DateTime(2024, 12, 15),
        postedDate: now.subtract(const Duration(days: 2)),
        isVerified: false,
        likeCount: 31,
        commentCount: 12,
      ),
    ];
  }
}

