// ignore_for_file: file_names
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'BUserService.dart';

/// Backend service for "Looking For" post operations in Firestore
/// Handles all looking-for-post-related database operations
class BLookingForPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BUserService _userService = BUserService();
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

  /// Get paginated looking for posts (optimized for performance)
  /// Returns a list of posts and a DocumentSnapshot for the last item (for pagination)
  Future<Map<String, dynamic>> getLookingForPostsPaginated({
    int limit = 12,
    DocumentSnapshot? lastDocument,
    bool randomize = true,
  }) async {
    try {
      debugPrint('📖 [BLookingForPostService] Fetching paginated posts (limit: $limit)...');
      
      Query query = _firestore.collection(_collectionName);
      
      // If we have a last document, start after it
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      // Order by createdAt for consistent pagination
      query = query.orderBy('createdAt', descending: true).limit(limit);
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        return {
          'posts': <Map<String, dynamic>>[],
          'lastDocument': null,
          'hasMore': false,
        };
      }
      
      // Convert to map
      var posts = snapshot.docs.map<Map<String, dynamic>>((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return <String, dynamic>{
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // Filter out posts from deactivated users
      if (posts.isNotEmpty) {
        final userIds = posts.map((p) => p['userId'] as String?).whereType<String>().toList();
        final deactivatedUserIds = await _userService.getDeactivatedUserIds(userIds);
        
        if (deactivatedUserIds.isNotEmpty) {
          posts = posts.where((post) {
            final userId = post['userId'] as String?;
            return userId == null || !deactivatedUserIds.contains(userId);
          }).toList();
        }
      }
      
      // Randomize if requested (shuffle the list)
      if (randomize && posts.length > 1) {
        posts.shuffle();
      }
      
      final lastDoc = snapshot.docs.last;
      final hasMore = snapshot.docs.length == limit; // If we got full limit, there might be more
      
      debugPrint('✅ [BLookingForPostService] Fetched ${posts.length} posts (hasMore: $hasMore)');
      
      return {
        'posts': posts,
        'lastDocument': lastDoc,
        'hasMore': hasMore,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ [BLookingForPostService] Error fetching paginated posts: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      return {
        'posts': <Map<String, dynamic>>[],
        'lastDocument': null,
        'hasMore': false,
      };
    }
  }

  /// Get all looking for posts (excludes posts from deactivated users)
  /// NOTE: Query without orderBy to avoid Firestore composite index requirement
  /// Sorting is done in memory instead
  Future<List<Map<String, dynamic>>> getAllLookingForPosts() async {
    try {
      // Query WITHOUT orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection(_collectionName)
          .get();
      
      var posts = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      // Sort by createdAt in memory (newest first)
      posts.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate); // Descending order
      });
      
      // Filter out posts from deactivated users
      if (posts.isNotEmpty) {
        final userIds = posts.map((p) => p['userId'] as String?).whereType<String>().toList();
        if (userIds.isNotEmpty) {
          final deactivatedUserIds = await _userService.getDeactivatedUserIds(userIds);
          
          if (deactivatedUserIds.isNotEmpty) {
            posts = posts.where((post) {
              final userId = post['userId'] as String?;
              return userId == null || !deactivatedUserIds.contains(userId);
            }).toList();
          }
        }
      }
      
      return posts;
    } catch (e) {
      // Error:'Error getting all looking for posts: $e');
      return [];
    }
  }

  /// Get looking for posts by user ID
  /// NOTE: Query without orderBy to avoid Firestore composite index requirement
  /// Sorting is done in memory instead
  Future<List<Map<String, dynamic>>> getLookingForPostsByUser(String userId) async {
    try {
      // Query WITHOUT orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();
      
      // Sort by createdAt descending in memory (newest first)
      final posts = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      posts.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate); // Descending order
      });
      
      return posts;
    } catch (e) {
      // Error:'Error getting looking for posts by user: $e');
      return [];
    }
  }

  /// Get looking for posts by user ID as a real-time stream
  /// Returns a stream that emits updated lists of posts whenever posts change
  /// NOTE: This query does NOT use orderBy to avoid Firestore composite index requirement
  Stream<List<Map<String, dynamic>>> getLookingForPostsByUserStream(String userId) {
    // Query WITHOUT orderBy to avoid composite index requirement
    // We sort in memory instead
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        // NO orderBy here - sorting is done in memory below
        .snapshots()
        .map((snapshot) {
      // Get all posts and sort in memory (to avoid composite index requirement)
      final posts = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      // Sort by createdAt descending (newest first) - in memory, not in query
      posts.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate); // Descending order
      });
      
      return posts;
    });
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

  /// Increment comment count
  Future<void> incrementCommentCount(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).update({
        'commentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error:'Error incrementing comment count: $e');
      rethrow;
    }
  }

  /// Decrement comment count
  Future<void> decrementCommentCount(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).update({
        'commentCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error:'Error decrementing comment count: $e');
      rethrow;
    }
  }

  /// Search looking for posts with filters
  /// Searches by description, location, propertyType, and budget
  Future<List<Map<String, dynamic>>> searchLookingForPosts({
    String? searchQuery,
    String? location,
    String? propertyType,
    String? budget,
  }) async {
    try {
      // Query without orderBy to avoid composite index requirement
      // We'll sort in memory instead
      Query query = _firestore.collection(_collectionName);
      
      // Apply filters that can be done in Firestore
      if (location != null && location.isNotEmpty) {
        // Note: Firestore doesn't support case-insensitive search, so we'll filter in memory
        // For now, we'll get all posts and filter in memory
      }
      
      if (propertyType != null && propertyType.isNotEmpty) {
        query = query.where('propertyType', isEqualTo: propertyType);
      }
      
      final snapshot = await query.get();
      
      var posts = snapshot.docs.map<Map<String, dynamic>>((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return <String, dynamic>{
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // Filter out posts from deactivated users
      if (posts.isNotEmpty) {
        final userIds = posts.map((p) => p['userId'] as String?).whereType<String>().toList();
        if (userIds.isNotEmpty) {
          final deactivatedUserIds = await _userService.getDeactivatedUserIds(userIds);
          
          if (deactivatedUserIds.isNotEmpty) {
            posts = posts.where((post) {
              final userId = post['userId'] as String?;
              return userId == null || !deactivatedUserIds.contains(userId);
            }).toList();
          }
        }
      }
      
      // Apply text search filter in memory (if provided)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryLower = searchQuery.toLowerCase();
        posts = posts.where((post) {
          final description = (post['description'] as String? ?? '').toLowerCase();
          final postLocation = (post['location'] as String? ?? '').toLowerCase();
          final postPropertyType = (post['propertyType'] as String? ?? '').toLowerCase();
          final postBudget = (post['budget'] as String? ?? '').toLowerCase();
          return description.contains(queryLower) || 
                 postLocation.contains(queryLower) || 
                 postPropertyType.contains(queryLower) ||
                 postBudget.contains(queryLower);
        }).toList();
      }
      
      // Apply location filter in memory (if provided)
      if (location != null && location.isNotEmpty) {
        final locationLower = location.toLowerCase();
        posts = posts.where((post) {
          final postLocation = (post['location'] as String? ?? '').toLowerCase();
          return postLocation.contains(locationLower);
        }).toList();
      }
      
      // Apply budget filter in memory (if provided)
      if (budget != null && budget.isNotEmpty) {
        final budgetLower = budget.toLowerCase();
        posts = posts.where((post) {
          final postBudget = (post['budget'] as String? ?? '').toLowerCase();
          return postBudget.contains(budgetLower);
        }).toList();
      }
      
      // Sort by createdAt in memory (newest first)
      posts.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate); // Descending order
      });
      
      return posts;
    } catch (e) {
      debugPrint('❌ [BLookingForPostService] Error searching looking for posts: $e');
      return [];
    }
  }

  /// Get looking for post document reference
  DocumentReference getLookingForPostDocument(String postId) {
    return _firestore.collection(_collectionName).doc(postId);
  }
}

