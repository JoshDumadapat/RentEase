// ignore_for_file: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

/// Backend service for "Looking For" post operations in Firestore
/// Handles all looking-for-post-related database operations
class BLookingForPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'lookingForPosts';

  /// Create a new looking for post
  Future<String> createLookingForPost({
    required String userId,
    required String username,
    required String description,
    required String location,
    required String budget,
    required String propertyType,
    DateTime? moveInDate,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final postData = <String, dynamic>{
        'userId': userId,
        'username': username,
        'description': description,
        'location': location,
        'budget': budget,
        'propertyType': propertyType,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'commentCount': 0,
        if (moveInDate != null) 'moveInDate': Timestamp.fromDate(moveInDate),
        if (additionalData != null) ...additionalData,
      };

      final docRef = await _firestore.collection(_collectionName).add(postData);
      return docRef.id;
    } catch (e) {
      // Error:'Error creating looking for post: $e');
      rethrow;
    }
  }

  /// Get looking for post by ID
  Future<Map<String, dynamic>?> getLookingForPost(String postId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(postId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      // Error:'Error getting looking for post: $e');
      return null;
    }
  }

  /// Get all looking for posts
  Future<List<Map<String, dynamic>>> getAllLookingForPosts() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      // Error:'Error getting all looking for posts: $e');
      return [];
    }
  }

  /// Get looking for posts by user ID
  Future<List<Map<String, dynamic>>> getLookingForPostsByUser(String userId) async {
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
      // Error:'Error getting looking for posts by user: $e');
      return [];
    }
  }

  /// Update looking for post
  Future<void> updateLookingForPost(String postId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error:'Error updating looking for post: $e');
      rethrow;
    }
  }

  /// Delete looking for post
  Future<void> deleteLookingForPost(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).delete();
    } catch (e) {
      // Error:'Error deleting looking for post: $e');
      rethrow;
    }
  }

  /// Increment like count
  Future<void> incrementLikeCount(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).update({
        'likeCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error:'Error incrementing like count: $e');
      rethrow;
    }
  }

  /// Decrement like count
  Future<void> decrementLikeCount(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).update({
        'likeCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error:'Error decrementing like count: $e');
      rethrow;
    }
  }

  /// Get looking for post document reference
  DocumentReference getLookingForPostDocument(String postId) {
    return _firestore.collection(_collectionName).doc(postId);
  }
}

