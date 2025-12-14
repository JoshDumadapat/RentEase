import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String listingId;
  final String reviewerName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.listingId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create ReviewModel from Firestore document
  factory ReviewModel.fromMap(Map<String, dynamic> data) {
    // Parse createdAt
    // Handle server timestamps that might be null temporarily
    DateTime createdAt;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is DateTime) {
        createdAt = data['createdAt'] as DateTime;
      } else {
        // Fallback to current time if invalid
        createdAt = DateTime.now();
      }
    } else {
      // If createdAt is null (server timestamp not yet resolved), use current time
      // This happens temporarily when a document is first created
      createdAt = DateTime.now();
    }

    // Parse updatedAt
    DateTime? updatedAt;
    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['updatedAt'] is DateTime) {
        updatedAt = data['updatedAt'] as DateTime;
      }
    }

    return ReviewModel(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      listingId: data['listingId'] as String? ?? '',
      reviewerName: data['reviewerName'] as String? ?? 'Anonymous',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert ReviewModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'listingId': listingId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
