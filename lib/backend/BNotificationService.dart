// ignore_for_file: file_names
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Backend service for notification operations in Firestore
/// Handles all notification-related database operations
class BNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'notifications';

  /// Create a new notification
  Future<String> createNotification({
    required String userId,
    required String type,
    required String actorName,
    String? actorAvatarUrl,
    String? reactionEmoji,
    String? commentText,
    String? postTitle,
    String? postId,
    String? postType, // 'listing' or 'lookingFor'
    List<String>? otherActors,
    int? reactionCount,
  }) async {
    try {
      final notificationData = <String, dynamic>{
        'userId': userId,
        'type': type,
        'actorName': actorName,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (actorAvatarUrl != null) 'actorAvatarUrl': actorAvatarUrl,
        if (reactionEmoji != null) 'reactionEmoji': reactionEmoji,
        if (commentText != null) 'commentText': commentText,
        if (postTitle != null) 'postTitle': postTitle,
        if (postId != null) 'postId': postId,
        if (postType != null) 'postType': postType,
        if (otherActors != null) 'otherActors': otherActors,
        if (reactionCount != null) 'reactionCount': reactionCount,
      };

      final docRef = await _firestore.collection(_collectionName).add(notificationData);
      return docRef.id;
    } catch (e) {
      // Error:'Error creating notification: $e');
      rethrow;
    }
  }

  /// Get notifications by user ID
  /// NOTE: Query without orderBy to avoid Firestore composite index requirement
  /// Sorting is done in memory instead
  Future<List<Map<String, dynamic>>> getNotificationsByUser(String userId) async {
    try {
      // Query WITHOUT orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();
      
      // Sort by createdAt descending in memory (newest first)
      final notifications = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      notifications.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate); // Descending order
      });
      
      return notifications;
    } catch (e) {
      // Error:'Error getting notifications by user: $e');
      return [];
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      // Error:'Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collectionName).doc(notificationId).update({
        'read': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error:'Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark notification as unread
  Future<void> markAsUnread(String notificationId) async {
    try {
      await _firestore.collection(_collectionName).doc(notificationId).update({
        'read': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error:'Error marking notification as unread: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'read': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      // Error:'Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collectionName).doc(notificationId).delete();
    } catch (e) {
      // Error:'Error deleting notification: $e');
      rethrow;
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      // Error:'Error deleting all notifications: $e');
      rethrow;
    }
  }

  /// Get notification document reference
  DocumentReference getNotificationDocument(String notificationId) {
    return _firestore.collection(_collectionName).doc(notificationId);
  }

  /// Get notifications by user ID as a real-time stream
  /// Returns a stream that emits updated lists of notifications whenever notifications change
  /// NOTE: This query does NOT use orderBy to avoid Firestore composite index requirement
  Stream<List<Map<String, dynamic>>> getNotificationsByUserStream(String userId) {
    // Query WITHOUT orderBy to avoid composite index requirement
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      // Get all notifications and sort in memory (to avoid composite index requirement)
      final notifications = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      // Sort by createdAt descending (newest first) - in memory, not in query
      notifications.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate); // Descending order
      });
      
      return notifications;
    });
  }

  /// Create a notification for a comment on a listing
  /// Notifies the listing owner when someone comments on their listing
  Future<void> notifyCommentOnListing({
    required String listingOwnerId,
    required String commenterId,
    required String commenterName,
    String? commenterAvatarUrl,
    required String commentText,
    required String listingId,
    String? listingTitle,
  }) async {
    try {
      // Don't notify if user is commenting on their own listing
      if (listingOwnerId == commenterId) {
        return;
      }

      await createNotification(
        userId: listingOwnerId,
        type: 'comment',
        actorName: commenterName,
        actorAvatarUrl: commenterAvatarUrl,
        commentText: commentText,
        postTitle: listingTitle,
        postId: listingId,
        postType: 'listing',
      );
    } catch (e) {
      // Log error but don't throw - notification failure shouldn't break comment creation
      debugPrint('❌ [BNotificationService] Error creating comment notification: $e');
    }
  }

  /// Create a notification for a comment on a looking-for post
  /// Notifies the post owner when someone comments on their post
  Future<void> notifyCommentOnLookingForPost({
    required String postOwnerId,
    required String commenterId,
    required String commenterName,
    String? commenterAvatarUrl,
    required String commentText,
    required String postId,
    String? postDescription,
  }) async {
    try {
      // Don't notify if user is commenting on their own post
      if (postOwnerId == commenterId) {
        return;
      }

      // Use first 50 characters of description as title
      final postTitle = postDescription != null && postDescription.length > 50
          ? '${postDescription.substring(0, 50)}...'
          : postDescription;

      await createNotification(
        userId: postOwnerId,
        type: 'comment',
        actorName: commenterName,
        actorAvatarUrl: commenterAvatarUrl,
        commentText: commentText,
        postTitle: postTitle,
        postId: postId,
        postType: 'lookingFor',
      );
    } catch (e) {
      // Log error but don't throw - notification failure shouldn't break comment creation
      debugPrint('❌ [BNotificationService] Error creating comment notification: $e');
    }
  }

  /// Create a notification for a review on a listing
  /// Notifies the listing owner when someone reviews their listing
  Future<void> notifyReviewOnListing({
    required String listingOwnerId,
    required String reviewerId,
    required String reviewerName,
    String? reviewerAvatarUrl,
    required String reviewComment,
    required int rating,
    required String listingId,
    String? listingTitle,
  }) async {
    try {
      // Don't notify if user is reviewing their own listing
      if (listingOwnerId == reviewerId) {
        return;
      }

      await createNotification(
        userId: listingOwnerId,
        type: 'review',
        actorName: reviewerName,
        actorAvatarUrl: reviewerAvatarUrl,
        commentText: reviewComment,
        postTitle: listingTitle,
        postId: listingId,
        postType: 'listing',
      );
    } catch (e) {
      // Log error but don't throw - notification failure shouldn't break review creation
      debugPrint('❌ [BNotificationService] Error creating review notification: $e');
    }
  }

  /// Create a notification for a favorite on a listing
  /// Notifies the listing owner when someone favorites their listing
  Future<void> notifyFavoriteOnListing({
    required String listingOwnerId,
    required String favoriterId,
    required String favoriterName,
    String? favoriterAvatarUrl,
    required String listingId,
    String? listingTitle,
  }) async {
    try {
      // Don't notify if user is favoriting their own listing
      if (listingOwnerId == favoriterId) {
        return;
      }

      await createNotification(
        userId: listingOwnerId,
        type: 'reaction',
        actorName: favoriterName,
        actorAvatarUrl: favoriterAvatarUrl,
        reactionEmoji: '❤️',
        postTitle: listingTitle,
        postId: listingId,
        postType: 'listing',
      );
    } catch (e) {
      // Log error but don't throw - notification failure shouldn't break favorite creation
      debugPrint('❌ [BNotificationService] Error creating favorite notification: $e');
    }
  }

  /// Create a notification for a like on a looking-for post
  /// Notifies the post owner when someone likes their post
  Future<void> notifyLikeOnLookingForPost({
    required String postOwnerId,
    required String likerId,
    required String likerName,
    String? likerAvatarUrl,
    required String postId,
    String? postDescription,
  }) async {
    try {
      // Don't notify if user is liking their own post
      if (postOwnerId == likerId) {
        return;
      }

      // Use first 50 characters of description as title
      final postTitle = postDescription != null && postDescription.length > 50
          ? '${postDescription.substring(0, 50)}...'
          : postDescription;

      await createNotification(
        userId: postOwnerId,
        type: 'reaction',
        actorName: likerName,
        actorAvatarUrl: likerAvatarUrl,
        reactionEmoji: '❤️',
        postTitle: postTitle,
        postId: postId,
        postType: 'lookingFor',
      );
    } catch (e) {
      // Log error but don't throw - notification failure shouldn't break like creation
      debugPrint('❌ [BNotificationService] Error creating like notification: $e');
    }
  }
}

