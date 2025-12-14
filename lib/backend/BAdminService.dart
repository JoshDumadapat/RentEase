// ignore_for_file: file_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Backend service for admin operations in Firestore
/// Handles all admin-related database operations
class BAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user is admin
  Future<bool> isAdmin(String userId) async {
    try {
      final userData = await _firestore.collection('users').doc(userId).get();
      if (userData.exists) {
        final data = userData.data();
        return data?['role'] == 'admin';
      }
      return false;
    } catch (e) {
      debugPrint('❌ [BAdminService] Error checking admin status: $e');
      return false;
    }
  }

  /// Get all listings (admin access)
  Future<List<Map<String, dynamic>>> getAllListings() async {
    try {
      final snapshot = await _firestore
          .collection('listings')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ [BAdminService] Error getting all listings: $e');
      return [];
    }
  }

  /// Delete listing (admin access)
  Future<void> deleteListing(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).delete();
      debugPrint('✅ [BAdminService] Listing deleted: $listingId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error deleting listing: $e');
      rethrow;
    }
  }

  /// Get all notifications (admin access)
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ [BAdminService] Error getting all notifications: $e');
      return [];
    }
  }

  /// Delete notification (admin access)
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      debugPrint('✅ [BAdminService] Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error deleting notification: $e');
      rethrow;
    }
  }

  /// Get admin dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final listingsSnapshot = await _firestore.collection('listings').get();
      final notificationsSnapshot = await _firestore.collection('notifications').get();

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalListings': listingsSnapshot.docs.length,
        'totalNotifications': notificationsSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('❌ [BAdminService] Error getting dashboard stats: $e');
      return {
        'totalUsers': 0,
        'totalListings': 0,
        'totalNotifications': 0,
      };
    }
  }

  /// Get all users (admin access)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ [BAdminService] Error getting all users: $e');
      return [];
    }
  }

  /// Ban/suspend user
  Future<void> banUser(String userId, {String? reason}) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'bannedAt': FieldValue.serverTimestamp(),
        if (reason != null) 'banReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [BAdminService] User banned: $userId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error banning user: $e');
      rethrow;
    }
  }

  /// Unban user
  Future<void> unbanUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': false,
        'unbannedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'bannedAt': FieldValue.delete(),
        'banReason': FieldValue.delete(),
      });
      debugPrint('✅ [BAdminService] User unbanned: $userId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error unbanning user: $e');
      rethrow;
    }
  }

  /// Verify user
  Future<void> verifyUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [BAdminService] User verified: $userId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error verifying user: $e');
      rethrow;
    }
  }

  /// Unverify user
  Future<void> unverifyUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': false,
        'unverifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [BAdminService] User unverified: $userId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error unverifying user: $e');
      rethrow;
    }
  }

  // ==================== COMMENTS MANAGEMENT ====================

  /// Get all comments (admin access)
  Future<List<Map<String, dynamic>>> getAllComments() async {
    try {
      final snapshot = await _firestore
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ [BAdminService] Error getting all comments: $e');
      return [];
    }
  }

  /// Delete comment (admin access)
  Future<void> deleteComment(String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
      debugPrint('✅ [BAdminService] Comment deleted: $commentId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error deleting comment: $e');
      rethrow;
    }
  }

  /// Flag comment as inappropriate
  Future<void> flagComment(String commentId, String reason) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'isFlagged': true,
        'flagReason': reason,
        'flaggedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [BAdminService] Comment flagged: $commentId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error flagging comment: $e');
      rethrow;
    }
  }

  /// Unflag comment
  Future<void> unflagComment(String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'isFlagged': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'flagReason': FieldValue.delete(),
        'flaggedAt': FieldValue.delete(),
      });
      debugPrint('✅ [BAdminService] Comment unflagged: $commentId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error unflagging comment: $e');
      rethrow;
    }
  }

  // ==================== LOOKING FOR POSTS MANAGEMENT ====================

  /// Get all looking for posts (admin access)
  Future<List<Map<String, dynamic>>> getAllLookingForPosts() async {
    try {
      final snapshot = await _firestore
          .collection('lookingForPosts')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ [BAdminService] Error getting all looking for posts: $e');
      return [];
    }
  }

  /// Delete looking for post (admin access)
  Future<void> deleteLookingForPost(String postId) async {
    try {
      await _firestore.collection('lookingForPosts').doc(postId).delete();
      debugPrint('✅ [BAdminService] Looking for post deleted: $postId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error deleting looking for post: $e');
      rethrow;
    }
  }

  /// Flag looking for post as inappropriate
  Future<void> flagLookingForPost(String postId, String reason) async {
    try {
      await _firestore.collection('lookingForPosts').doc(postId).update({
        'isFlagged': true,
        'flagReason': reason,
        'flaggedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [BAdminService] Looking for post flagged: $postId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error flagging looking for post: $e');
      rethrow;
    }
  }

  /// Unflag looking for post
  Future<void> unflagLookingForPost(String postId) async {
    try {
      await _firestore.collection('lookingForPosts').doc(postId).update({
        'isFlagged': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'flagReason': FieldValue.delete(),
        'flaggedAt': FieldValue.delete(),
      });
      debugPrint('✅ [BAdminService] Looking for post unflagged: $postId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error unflagging looking for post: $e');
      rethrow;
    }
  }

  // ==================== REPORTS MANAGEMENT ====================

  /// Create a report
  Future<String> createReport({
    required String reporterId,
    required String contentType, // 'listing', 'comment', 'lookingForPost', 'user'
    required String contentId,
    required String reason,
    String? description,
  }) async {
    try {
      final reportData = <String, dynamic>{
        'reporterId': reporterId,
        'contentType': contentType,
        'contentId': contentId,
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (description != null) 'description': description,
      };

      final docRef = await _firestore.collection('reports').add(reportData);
      debugPrint('✅ [BAdminService] Report created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [BAdminService] Error creating report: $e');
      rethrow;
    }
  }

  /// Get all reports (admin access)
  Future<List<Map<String, dynamic>>> getAllReports({String? status}) async {
    try {
      Query query = _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true);
      
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return <String, dynamic>{
          'id': doc.id,
          if (data != null) ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ [BAdminService] Error getting all reports: $e');
      return [];
    }
  }

  /// Resolve report
  Future<void> resolveReport(String reportId, String action, String? adminNotes) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'resolved',
        'action': action, // 'deleted', 'warned', 'banned', 'dismissed', etc.
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (adminNotes != null) 'adminNotes': adminNotes,
      });
      debugPrint('✅ [BAdminService] Report resolved: $reportId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error resolving report: $e');
      rethrow;
    }
  }

  /// Dismiss report
  Future<void> dismissReport(String reportId, String? adminNotes) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'dismissed',
        'dismissedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (adminNotes != null) 'adminNotes': adminNotes,
      });
      debugPrint('✅ [BAdminService] Report dismissed: $reportId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error dismissing report: $e');
      rethrow;
    }
  }

  /// Flag listing as inappropriate
  Future<void> flagListing(String listingId, String reason) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'isFlagged': true,
        'flagReason': reason,
        'flaggedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [BAdminService] Listing flagged: $listingId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error flagging listing: $e');
      rethrow;
    }
  }

  /// Unflag listing
  Future<void> unflagListing(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'isFlagged': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'flagReason': FieldValue.delete(),
        'flaggedAt': FieldValue.delete(),
      });
      debugPrint('✅ [BAdminService] Listing unflagged: $listingId');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error unflagging listing: $e');
      rethrow;
    }
  }

  // ==================== BULK OPERATIONS ====================

  /// Bulk delete listings
  Future<void> bulkDeleteListings(List<String> listingIds) async {
    try {
      final batch = _firestore.batch();
      for (final listingId in listingIds) {
        batch.delete(_firestore.collection('listings').doc(listingId));
      }
      await batch.commit();
      debugPrint('✅ [BAdminService] Bulk deleted ${listingIds.length} listings');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error bulk deleting listings: $e');
      rethrow;
    }
  }

  /// Bulk delete comments
  Future<void> bulkDeleteComments(List<String> commentIds) async {
    try {
      final batch = _firestore.batch();
      for (final commentId in commentIds) {
        batch.delete(_firestore.collection('comments').doc(commentId));
      }
      await batch.commit();
      debugPrint('✅ [BAdminService] Bulk deleted ${commentIds.length} comments');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error bulk deleting comments: $e');
      rethrow;
    }
  }

  /// Bulk delete looking for posts
  Future<void> bulkDeleteLookingForPosts(List<String> postIds) async {
    try {
      final batch = _firestore.batch();
      for (final postId in postIds) {
        batch.delete(_firestore.collection('lookingForPosts').doc(postId));
      }
      await batch.commit();
      debugPrint('✅ [BAdminService] Bulk deleted ${postIds.length} looking for posts');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error bulk deleting looking for posts: $e');
      rethrow;
    }
  }

  /// Bulk ban users
  Future<void> bulkBanUsers(List<String> userIds, {String? reason}) async {
    try {
      final batch = _firestore.batch();
      for (final userId in userIds) {
        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'isBanned': true,
          'bannedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          if (reason != null) 'banReason': reason,
        });
      }
      await batch.commit();
      debugPrint('✅ [BAdminService] Bulk banned ${userIds.length} users');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error bulk banning users: $e');
      rethrow;
    }
  }

  /// Bulk flag listings
  Future<void> bulkFlagListings(List<String> listingIds, String reason) async {
    try {
      final batch = _firestore.batch();
      for (final listingId in listingIds) {
        final listingRef = _firestore.collection('listings').doc(listingId);
        batch.update(listingRef, {
          'isFlagged': true,
          'flagReason': reason,
          'flaggedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      debugPrint('✅ [BAdminService] Bulk flagged ${listingIds.length} listings');
    } catch (e) {
      debugPrint('❌ [BAdminService] Error bulk flagging listings: $e');
      rethrow;
    }
  }

  // ==================== ENHANCED ANALYTICS ====================

  /// Get enhanced dashboard stats with trends
  Future<Map<String, dynamic>> getEnhancedDashboardStats() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Get all data
      final usersSnapshot = await _firestore.collection('users').get();
      final listingsSnapshot = await _firestore.collection('listings').get();
      final commentsSnapshot = await _firestore.collection('comments').get();
      final lookingForPostsSnapshot = await _firestore.collection('lookingForPosts').get();
      final notificationsSnapshot = await _firestore.collection('notifications').get();
      final reportsSnapshot = await _firestore.collection('reports').where('status', isEqualTo: 'pending').get();

      // Calculate trends
      int newUsersLast7Days = 0;
      int newUsersLast30Days = 0;
      int newListingsLast7Days = 0;
      int newListingsLast30Days = 0;
      int activeUsers = 0;
      int bannedUsers = 0;
      int verifiedUsers = 0;

      // Count new users
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final createdDate = createdAt.toDate();
          if (createdDate.isAfter(sevenDaysAgo)) {
            newUsersLast7Days++;
          }
          if (createdDate.isAfter(thirtyDaysAgo)) {
            newUsersLast30Days++;
          }
        }
        if (data['isBanned'] == true) bannedUsers++;
        if (data['isVerified'] == true) verifiedUsers++;
        // Consider active if user has listings or comments
        activeUsers++; // Simplified - could check for recent activity
      }

      // Count new listings
      for (final doc in listingsSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final createdDate = createdAt.toDate();
          if (createdDate.isAfter(sevenDaysAgo)) {
            newListingsLast7Days++;
          }
          if (createdDate.isAfter(thirtyDaysAgo)) {
            newListingsLast30Days++;
          }
        }
      }

      // Category breakdown
      final Map<String, int> categoryCount = {};
      for (final doc in listingsSnapshot.docs) {
        final category = doc.data()['category'] as String? ?? 'Unknown';
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      return {
        // Totals
        'totalUsers': usersSnapshot.docs.length,
        'totalListings': listingsSnapshot.docs.length,
        'totalComments': commentsSnapshot.docs.length,
        'totalLookingForPosts': lookingForPostsSnapshot.docs.length,
        'totalNotifications': notificationsSnapshot.docs.length,
        'pendingReports': reportsSnapshot.docs.length,
        
        // Trends
        'newUsersLast7Days': newUsersLast7Days,
        'newUsersLast30Days': newUsersLast30Days,
        'newListingsLast7Days': newListingsLast7Days,
        'newListingsLast30Days': newListingsLast30Days,
        
        // User stats
        'activeUsers': activeUsers,
        'bannedUsers': bannedUsers,
        'verifiedUsers': verifiedUsers,
        
        // Category breakdown
        'categoryBreakdown': categoryCount,
      };
    } catch (e) {
      debugPrint('❌ [BAdminService] Error getting enhanced dashboard stats: $e');
      return {
        'totalUsers': 0,
        'totalListings': 0,
        'totalComments': 0,
        'totalLookingForPosts': 0,
        'totalNotifications': 0,
        'pendingReports': 0,
        'newUsersLast7Days': 0,
        'newUsersLast30Days': 0,
        'newListingsLast7Days': 0,
        'newListingsLast30Days': 0,
        'activeUsers': 0,
        'bannedUsers': 0,
        'verifiedUsers': 0,
        'categoryBreakdown': <String, int>{},
      };
    }
  }
}

