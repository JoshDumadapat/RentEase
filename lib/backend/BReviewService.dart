// ignore_for_file: file_names
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/backend/BListingService.dart';
import 'package:rentease_app/backend/BNotificationService.dart';
import 'package:rentease_app/backend/BUserService.dart';

/// Backend service for review operations in Firestore
/// Handles all review-related database operations for listings
class BReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BListingService _listingService = BListingService();
  final BNotificationService _notificationService = BNotificationService();
  final BUserService _userService = BUserService();
  static const String _collectionName = 'reviews';

  /// Create a new review for a listing
  Future<String> createReview({
    required String userId,
    required String listingId,
    required String reviewerName,
    required int rating,
    required String comment,
  }) async {
    try {
      // Validate rating (1-5)
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      final reviewData = <String, dynamic>{
        'userId': userId,
        'listingId': listingId,
        'reviewerName': reviewerName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      debugPrint('📝 [BReviewService] Creating review with data: $reviewData');
      final docRef = await _firestore.collection(_collectionName).add(reviewData);
      debugPrint('✅ [BReviewService] Review created successfully: ${docRef.id}');

      // Update listing's average rating and review count
      await _updateListingRating(listingId);
      debugPrint('✅ [BReviewService] Listing rating updated');

      // Create notification for the listing owner
      try {
        final listing = await _listingService.getListing(listingId);
        if (listing != null) {
          final listingOwnerId = listing['userId'] as String?;
          if (listingOwnerId != null && listingOwnerId != userId) {
            // Get reviewer's avatar URL
            final reviewerData = await _userService.getUserData(userId);
            final reviewerAvatarUrl = reviewerData?['profileImageUrl'] as String?;

            await _notificationService.notifyReviewOnListing(
              listingOwnerId: listingOwnerId,
              reviewerId: userId,
              reviewerName: reviewerName,
              reviewerAvatarUrl: reviewerAvatarUrl,
              reviewComment: comment,
              rating: rating,
              listingId: listingId,
              listingTitle: listing['title'] as String?,
            );
            debugPrint('✅ [BReviewService] Notification created for listing owner');
          }
        }
      } catch (e) {
        // Log error but don't throw - notification failure shouldn't break review creation
        debugPrint('⚠️ [BReviewService] Error creating notification: $e');
      }

      return docRef.id;
    } catch (e) {
      debugPrint('❌ [BReviewService] Error creating review: $e');
      rethrow;
    }
  }

  /// Get review by ID
  Future<Map<String, dynamic>?> getReview(String reviewId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(reviewId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      debugPrint('❌ [BReviewService] Error getting review: $e');
      return null;
    }
  }

  /// Get all reviews for a listing
  Future<List<Map<String, dynamic>>> getReviewsByListing(String listingId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('listingId', isEqualTo: listingId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ [BReviewService] Error getting reviews by listing: $e');
      return [];
    }
  }

  /// Get reviews by user ID
  Future<List<Map<String, dynamic>>> getReviewsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ [BReviewService] Error getting reviews by user: $e');
      return [];
    }
  }

  /// Check if user has already reviewed a listing
  Future<bool> hasUserReviewed(String userId, String listingId) async {
    try {
      // Query by userId first (indexed by default), then filter by listingId in memory
      // This avoids needing a composite index
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();
      
      // Filter by listingId in memory
      final matchingReviews = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['listingId'] == listingId;
      });
      
      return matchingReviews.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [BReviewService] Error checking if user reviewed: $e');
      // Return false on error to allow the review to proceed
      // This prevents blocking users if there's a temporary error
      return false;
    }
  }

  /// Update review
  Future<void> updateReview(String reviewId, {int? rating, String? comment}) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (rating != null) {
        if (rating < 1 || rating > 5) {
          throw Exception('Rating must be between 1 and 5');
        }
        updateData['rating'] = rating;
      }

      if (comment != null) {
        updateData['comment'] = comment;
      }

      // Get listing ID before updating
      final review = await getReview(reviewId);
      final listingId = review?['listingId'] as String?;

      await _firestore.collection(_collectionName).doc(reviewId).update(updateData);

      // Update listing's average rating if rating changed
      if (rating != null && listingId != null) {
        await _updateListingRating(listingId);
      }

      debugPrint('✅ [BReviewService] Review updated: $reviewId');
    } catch (e) {
      debugPrint('❌ [BReviewService] Error updating review: $e');
      rethrow;
    }
  }

  /// Delete review
  Future<void> deleteReview(String reviewId) async {
    try {
      // Get listing ID before deleting
      final review = await getReview(reviewId);
      final listingId = review?['listingId'] as String?;

      await _firestore.collection(_collectionName).doc(reviewId).delete();

      // Update listing's average rating
      if (listingId != null) {
        await _updateListingRating(listingId);
      }

      debugPrint('✅ [BReviewService] Review deleted: $reviewId');
    } catch (e) {
      debugPrint('❌ [BReviewService] Error deleting review: $e');
      rethrow;
    }
  }

  /// Calculate and update listing's average rating
  Future<void> _updateListingRating(String listingId) async {
    try {
      final reviews = await getReviewsByListing(listingId);

      if (reviews.isEmpty) {
        // No reviews, set to 0
        await _listingService.updateRating(listingId, 0.0, 0);
        return;
      }

      // Calculate average rating
      double totalRating = 0;
      for (final review in reviews) {
        final rating = review['rating'] as int? ?? 0;
        totalRating += rating;
      }

      final averageRating = totalRating / reviews.length;
      final reviewCount = reviews.length;

      // Update listing
      await _listingService.updateRating(listingId, averageRating, reviewCount);

      debugPrint('✅ [BReviewService] Updated listing rating: $listingId -> $averageRating ($reviewCount reviews)');
    } catch (e) {
      debugPrint('❌ [BReviewService] Error updating listing rating: $e');
      rethrow;
    }
  }

  /// Get average rating for a listing
  Future<double> getAverageRating(String listingId) async {
    try {
      debugPrint('📊 [BReviewService] Getting average rating for listing: $listingId');
      
      // Try to get reviews - if getReviewsByListing fails (due to index), use direct query
      List<Map<String, dynamic>> reviews;
      try {
        reviews = await getReviewsByListing(listingId);
        debugPrint('📊 [BReviewService] Got ${reviews.length} reviews via getReviewsByListing');
      } catch (e) {
        debugPrint('⚠️ [BReviewService] getReviewsByListing failed (likely index error), using direct query: $e');
        // Fallback: Query directly without orderBy
        final snapshot = await _firestore
            .collection(_collectionName)
            .where('listingId', isEqualTo: listingId)
            .get();
        reviews = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
        debugPrint('📊 [BReviewService] Got ${reviews.length} reviews via direct query');
      }
      
      if (reviews.isEmpty) {
        debugPrint('📊 [BReviewService] No reviews found, returning 0.0');
        return 0.0;
      }

      double totalRating = 0;
      int validRatings = 0;
      
      for (final review in reviews) {
        final rating = review['rating'] as int?;
        if (rating != null && rating > 0) {
          totalRating += rating;
          validRatings++;
          debugPrint('📊 [BReviewService] Review ${review['id']}: rating=$rating');
        } else {
          debugPrint('⚠️ [BReviewService] Review ${review['id']} has invalid rating: $rating');
        }
      }

      if (validRatings == 0) {
        debugPrint('⚠️ [BReviewService] No valid ratings found, returning 0.0');
        return 0.0;
      }

      final averageRating = totalRating / validRatings;
      debugPrint('✅ [BReviewService] Calculated average rating: $averageRating (from $validRatings valid reviews out of ${reviews.length} total)');
      return averageRating;
    } catch (e, stackTrace) {
      debugPrint('❌ [BReviewService] Error getting average rating: $e');
      debugPrint('❌ [BReviewService] Stack trace: $stackTrace');
      return 0.0;
    }
  }

  /// Get review count for a listing (fast query without orderBy)
  Future<int> getReviewCount(String listingId) async {
    try {
      // Query without orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('listingId', isEqualTo: listingId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ [BReviewService] Error getting review count: $e');
      return 0;
    }
  }

  /// Get review document reference
  DocumentReference getReviewDocument(String reviewId) {
    return _firestore.collection(_collectionName).doc(reviewId);
  }
}

