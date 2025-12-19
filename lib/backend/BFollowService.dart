import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rentease_app/backend/BNotificationService.dart';
import 'package:rentease_app/backend/BUserService.dart';

/// Follow service
class BFollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BNotificationService _notificationService = BNotificationService();
  final BUserService _userService = BUserService();
  
  static const String _followersCollection = 'followers';
  static const String _followingCollection = 'following';

  /// Check if current user is following a target user
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;
      
      if (currentUserId == targetUserId) return false; // Can't follow yourself
      
      final doc = await _firestore
          .collection(_followersCollection)
          .doc(targetUserId)
          .collection('userFollowers')
          .doc(currentUserId)
          .get();
      
      return doc.exists;
    } catch (e) {
      // debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  /// Follow a user
  Future<void> followUser(String targetUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      if (currentUserId == targetUserId) {
        throw Exception('Cannot follow yourself');
      }

      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();

      // Add to target user's followers collection
      final followerRef = _firestore
          .collection(_followersCollection)
          .doc(targetUserId)
          .collection('userFollowers')
          .doc(currentUserId);
      
      batch.set(followerRef, {
        'followerId': currentUserId,
        'followedAt': timestamp,
      });

      // Add to current user's following collection
      final followingRef = _firestore
          .collection(_followingCollection)
          .doc(currentUserId)
          .collection('userFollowing')
          .doc(targetUserId);
      
      batch.set(followingRef, {
        'followingId': targetUserId,
        'followedAt': timestamp,
      });

      // Update follower count in users collection
      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      batch.update(targetUserRef, {
        'followersCount': FieldValue.increment(1),
      });

      // Update following count in users collection
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'followingCount': FieldValue.increment(1),
      });

      await batch.commit();

      // Create notification for the followed user
      try {
        // Get follower's data for notification
        final followerData = await _userService.getUserData(currentUserId);
        final followerName = followerData?['username'] as String? ??
            followerData?['displayName'] as String? ??
            (followerData?['fname'] != null && followerData?['lname'] != null
                ? '${followerData!['fname']} ${followerData['lname']}'.trim()
                : null) ??
            followerData?['fname'] as String? ??
            followerData?['lname'] as String? ??
            'Someone';
        final followerAvatarUrl = followerData?['profileImageUrl'] as String?;

        await _notificationService.notifyFollow(
          followedUserId: targetUserId,
          followerId: currentUserId,
          followerName: followerName,
          followerAvatarUrl: followerAvatarUrl,
        );
        // debugPrint('✅ [BFollowService] Notification created for followed user');
      } catch (e) {
        // Log error but don't throw - notification failure shouldn't break follow creation
        // debugPrint('⚠️ [BFollowService] Error creating follow notification: $e');
      }
    } catch (e) {
      // debugPrint('Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      if (currentUserId == targetUserId) {
        throw Exception('Cannot unfollow yourself');
      }

      final batch = _firestore.batch();

      // Remove from target user's followers collection
      final followerRef = _firestore
          .collection(_followersCollection)
          .doc(targetUserId)
          .collection('userFollowers')
          .doc(currentUserId);
      
      batch.delete(followerRef);

      // Remove from current user's following collection
      final followingRef = _firestore
          .collection(_followingCollection)
          .doc(currentUserId)
          .collection('userFollowing')
          .doc(targetUserId);
      
      batch.delete(followingRef);

      // Update follower count in users collection
      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      batch.update(targetUserRef, {
        'followersCount': FieldValue.increment(-1),
      });

      // Update following count in users collection
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'followingCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      // debugPrint('Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Get follower count for a user
  Future<int> getFollowerCount(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return (doc.data()?['followersCount'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      // debugPrint('Error getting follower count: $e');
      return 0;
    }
  }

  /// Get following count for a user
  Future<int> getFollowingCount(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return (doc.data()?['followingCount'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      // debugPrint('Error getting following count: $e');
      return 0;
    }
  }

  /// Get list of followers for a user
  Future<List<String>> getFollowers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_followersCollection)
          .doc(userId)
          .collection('userFollowers')
          .get();
      
      return snapshot.docs.map((doc) => doc.data()['followerId'] as String).toList();
    } catch (e) {
      // debugPrint('Error getting followers: $e');
      return [];
    }
  }

  /// Get list of users that a user is following
  Future<List<String>> getFollowing(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_followingCollection)
          .doc(userId)
          .collection('userFollowing')
          .get();
      
      return snapshot.docs.map((doc) => doc.data()['followingId'] as String).toList();
    } catch (e) {
      // debugPrint('Error getting following: $e');
      return [];
    }
  }
}
