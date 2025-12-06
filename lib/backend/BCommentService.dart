// ignore_for_file: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

/// Backend service for comment operations in Firestore
/// Handles all comment-related database operations
class BCommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'comments';

  /// Create a new comment
  Future<String> createComment({
    required String userId,
    required String username,
    required String text,
    String? listingId,
    String? lookingForPostId,
  }) async {
    try {
      final commentData = <String, dynamic>{
        'userId': userId,
        'username': username,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (listingId != null) 'listingId': listingId,
        if (lookingForPostId != null) 'lookingForPostId': lookingForPostId,
      };

      final docRef = await _firestore.collection(_collectionName).add(commentData);
      return docRef.id;
    } catch (e) {
      // Error:'Error creating comment: $e');
      rethrow;
    }
  }

  /// Get comments by listing ID
  Future<List<Map<String, dynamic>>> getCommentsByListing(String listingId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('listingId', isEqualTo: listingId)
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      // Error:'Error getting comments by listing: $e');
      return [];
    }
  }

  /// Get comments by looking for post ID
  Future<List<Map<String, dynamic>>> getCommentsByLookingForPost(String lookingForPostId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('lookingForPostId', isEqualTo: lookingForPostId)
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      // Error:'Error getting comments by looking for post: $e');
      return [];
    }
  }

  /// Update comment
  Future<void> updateComment(String commentId, String text) async {
    try {
      await _firestore.collection(_collectionName).doc(commentId).update({
        'text': text,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error:'Error updating comment: $e');
      rethrow;
    }
  }

  /// Delete comment
  Future<void> deleteComment(String commentId) async {
    try {
      await _firestore.collection(_collectionName).doc(commentId).delete();
    } catch (e) {
      // Error:'Error deleting comment: $e');
      rethrow;
    }
  }

  /// Get comment document reference
  DocumentReference getCommentDocument(String commentId) {
    return _firestore.collection(_collectionName).doc(commentId);
  }
}

