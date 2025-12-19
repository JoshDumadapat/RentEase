// ignore_for_file: file_names
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/backend/BLookingForPostService.dart';
import 'package:rentease_app/backend/BNotificationService.dart';
import 'package:rentease_app/backend/BUserService.dart';

/// Like service for posts
class BLikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BLookingForPostService _lookingForPostService = BLookingForPostService();
  final BNotificationService _notificationService = BNotificationService();
  final BUserService _userService = BUserService();
  static const String _collectionName = 'lookingForLikes';

  /// Add a like to a looking-for post
  Future<void> addLike({
    required String userId,
    required String postId,
  }) async {
    try {
      // Check if already liked
      final existing = await isLiked(userId, postId);
      if (existing) {
        // debugPrint('⚠️ [BLikeService] Post already liked');
        return;
      }

      // Create like document
      await _firestore.collection(_collectionName).add({
        'userId': userId,
        'postId': postId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment like count on post
      await _lookingForPostService.incrementLikeCount(postId);

      // Create notification for the post owner
      try {
        final post = await _lookingForPostService.getLookingForPost(postId);
        if (post != null) {
          final postOwnerId = post['userId'] as String?;
          if (postOwnerId != null && postOwnerId != userId) {
            // Get liker's data
            final likerData = await _userService.getUserData(userId);
            final likerName = likerData?['username'] as String? ??
                likerData?['displayName'] as String? ??
                (likerData?['fname'] != null && likerData?['lname'] != null
                    ? '${likerData!['fname']} ${likerData['lname']}'.trim()
                    : null) ??
                likerData?['fname'] as String? ??
                likerData?['lname'] as String? ??
                'Someone';
            final likerAvatarUrl = likerData?['profileImageUrl'] as String?;

            await _notificationService.notifyLikeOnLookingForPost(
              postOwnerId: postOwnerId,
              likerId: userId,
              likerName: likerName,
              likerAvatarUrl: likerAvatarUrl,
              postId: postId,
              postDescription: post['description'] as String?,
            );
            // debugPrint('✅ [BLikeService] Notification created for post owner');
          }
        }
      } catch (e) {
        // Log error but don't throw - notification failure shouldn't break like creation
        // debugPrint('⚠️ [BLikeService] Error creating notification: $e');
      }

      // debugPrint('✅ [BLikeService] Like added: $userId -> $postId');
    } catch (e) {
      // debugPrint('❌ [BLikeService] Error adding like: $e');
      rethrow;
    }
  }

  /// Remove a like from a looking-for post
  Future<void> removeLike({
    required String userId,
    required String postId,
  }) async {
    try {
      // Find like document
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('postId', isEqualTo: postId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // debugPrint('⚠️ [BLikeService] Like not found');
        return;
      }

      // Delete like document
      await snapshot.docs.first.reference.delete();

      // Decrement like count on post
      await _lookingForPostService.decrementLikeCount(postId);

      // debugPrint('✅ [BLikeService] Like removed: $userId -> $postId');
    } catch (e) {
      // debugPrint('❌ [BLikeService] Error removing like: $e');
      rethrow;
    }
  }

  /// Toggle like status
  Future<bool> toggleLike({
    required String userId,
    required String postId,
  }) async {
    try {
      final isLikedPost = await isLiked(userId, postId);
      if (isLikedPost) {
        await removeLike(userId: userId, postId: postId);
        return false;
      } else {
        await addLike(userId: userId, postId: postId);
        return true;
      }
    } catch (e) {
      // debugPrint('❌ [BLikeService] Error toggling like: $e');
      rethrow;
    }
  }

  /// Check if post is liked by user
  Future<bool> isLiked(String userId, String postId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('postId', isEqualTo: postId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // debugPrint('❌ [BLikeService] Error checking like: $e');
      return false;
    }
  }

  /// Get all liked post IDs for a user
  Future<List<String>> getLikedPostIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['postId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();
    } catch (e) {
      // debugPrint('❌ [BLikeService] Error getting liked post IDs: $e');
      return [];
    }
  }

  /// Get like count for a post
  Future<int> getLikeCount(String postId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('postId', isEqualTo: postId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      // debugPrint('❌ [BLikeService] Error getting like count: $e');
      return 0;
    }
  }
}

