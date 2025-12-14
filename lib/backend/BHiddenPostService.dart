// ignore_for_file: file_names
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Backend service for hidden post operations in Firestore
/// Handles hiding/unhiding "looking for" posts from user's feed
class BHiddenPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'hiddenPosts';

  /// Hide a looking-for post from user's feed
  Future<void> hidePost({
    required String userId,
    required String postId,
  }) async {
    try {
      debugPrint('🔒 [BHiddenPostService] Checking if post is already hidden: $postId for user: $userId');
      
      // Check if already hidden
      final existing = await isPostHidden(userId, postId);
      if (existing) {
        debugPrint('⚠️ [BHiddenPostService] Post already hidden');
        return;
      }

      debugPrint('🔒 [BHiddenPostService] Creating hidden post document...');
      debugPrint('   - userId: $userId');
      debugPrint('   - postId: $postId');
      debugPrint('   - collection: $_collectionName');

      // Create hidden post document
      await _firestore.collection(_collectionName).add({
        'userId': userId,
        'postId': postId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ [BHiddenPostService] Post hidden successfully: $userId -> $postId');
    } catch (e, stackTrace) {
      debugPrint('❌ [BHiddenPostService] Error hiding post: $e');
      debugPrint('❌ [BHiddenPostService] Stack trace: $stackTrace');
      debugPrint('❌ [BHiddenPostService] Error type: ${e.runtimeType}');
      
      // Check if it's a Firestore permission error
      if (e.toString().contains('permission-denied')) {
        debugPrint('🔒 PERMISSION DENIED ERROR');
        debugPrint('   This usually means:');
        debugPrint('   1. User is not authenticated');
        debugPrint('   2. Firestore rules are blocking the operation');
        debugPrint('   3. userId does not match auth.uid');
        debugPrint('   Make sure Firestore rules are deployed!');
      }
      
      rethrow;
    }
  }

  /// Unhide a looking-for post (show it again in feed)
  Future<void> unhidePost({
    required String userId,
    required String postId,
  }) async {
    try {
      // Find hidden post document
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('postId', isEqualTo: postId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ [BHiddenPostService] Hidden post not found');
        return;
      }

      // Delete hidden post document
      await snapshot.docs.first.reference.delete();

      debugPrint('✅ [BHiddenPostService] Post unhidden: $userId -> $postId');
    } catch (e) {
      debugPrint('❌ [BHiddenPostService] Error unhiding post: $e');
      rethrow;
    }
  }

  /// Toggle hide status
  Future<bool> toggleHidePost({
    required String userId,
    required String postId,
  }) async {
    try {
      final isHidden = await isPostHidden(userId, postId);
      if (isHidden) {
        await unhidePost(userId: userId, postId: postId);
        return false;
      } else {
        await hidePost(userId: userId, postId: postId);
        return true;
      }
    } catch (e) {
      debugPrint('❌ [BHiddenPostService] Error toggling hide status: $e');
      rethrow;
    }
  }

  /// Check if post is hidden by user
  Future<bool> isPostHidden(String userId, String postId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('postId', isEqualTo: postId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [BHiddenPostService] Error checking if post is hidden: $e');
      return false;
    }
  }

  /// Get all hidden post IDs for a user
  Future<Set<String>> getHiddenPostIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['postId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('❌ [BHiddenPostService] Error getting hidden post IDs: $e');
      return {};
    }
  }

  /// Get hidden post IDs as a real-time stream
  Stream<Set<String>> getHiddenPostIdsStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data()['postId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    });
  }
}
