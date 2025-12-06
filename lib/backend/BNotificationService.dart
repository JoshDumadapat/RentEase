// ignore_for_file: file_names
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
  Future<List<Map<String, dynamic>>> getNotificationsByUser(String userId) async {
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
}

