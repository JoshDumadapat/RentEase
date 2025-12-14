// ignore_for_file: file_names
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/backend/BNotificationService.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/backend/BListingService.dart';
import 'package:rentease_app/backend/BLookingForPostService.dart';

/// Backend service for comment operations in Firestore
/// Handles all comment-related database operations
class BCommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BNotificationService _notificationService = BNotificationService();
  final BUserService _userService = BUserService();
  final BListingService _listingService = BListingService();
  final BLookingForPostService _lookingForPostService = BLookingForPostService();
  static const String _collectionName = 'comments';

  /// Create a new comment
  Future<String> createComment({
    required String userId,
    required String username,
    required String text,
    String? listingId,
    String? lookingForPostId,
    String? propertyListingId, // ID of property listing shared in the comment
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
        if (propertyListingId != null) 'propertyListingId': propertyListingId,
      };

      final docRef = await _firestore.collection(_collectionName).add(commentData);
      debugPrint('✅ [BCommentService] Comment created successfully! ID: ${docRef.id}');
      if (propertyListingId != null) {
        debugPrint('🔗 [BCommentService] Comment includes property link: $propertyListingId');
      }

      // Create notification for the post/listing owner
      try {
        if (listingId != null) {
          // Comment on a listing
          final listing = await _listingService.getListing(listingId);
          if (listing != null) {
            final listingOwnerId = listing['userId'] as String?;
            if (listingOwnerId != null && listingOwnerId != userId) {
              // Get commenter's avatar URL
              final commenterData = await _userService.getUserData(userId);
              final commenterAvatarUrl = commenterData?['profileImageUrl'] as String?;

              await _notificationService.notifyCommentOnListing(
                listingOwnerId: listingOwnerId,
                commenterId: userId,
                commenterName: username,
                commenterAvatarUrl: commenterAvatarUrl,
                commentText: text,
                listingId: listingId,
                listingTitle: listing['title'] as String?,
              );
              debugPrint('✅ [BCommentService] Notification created for listing owner');
            }
          }
        } else if (lookingForPostId != null) {
          // Comment on a looking-for post
          final post = await _lookingForPostService.getLookingForPost(lookingForPostId);
          if (post != null) {
            final postOwnerId = post['userId'] as String?;
            if (postOwnerId != null && postOwnerId != userId) {
              // Get commenter's avatar URL
              final commenterData = await _userService.getUserData(userId);
              final commenterAvatarUrl = commenterData?['profileImageUrl'] as String?;

              await _notificationService.notifyCommentOnLookingForPost(
                postOwnerId: postOwnerId,
                commenterId: userId,
                commenterName: username,
                commenterAvatarUrl: commenterAvatarUrl,
                commentText: text,
                postId: lookingForPostId,
                postDescription: post['description'] as String?,
              );
              debugPrint('✅ [BCommentService] Notification created for post owner');
            }
          }
        }
      } catch (e) {
        // Log error but don't throw - notification failure shouldn't break comment creation
        debugPrint('⚠️ [BCommentService] Error creating notification: $e');
      }

      return docRef.id;
    } catch (e) {
      debugPrint('❌ [BCommentService] Error creating comment: $e');
      rethrow;
    }
  }

  /// Get comments by listing ID
  Future<List<Map<String, dynamic>>> getCommentsByListing(String listingId) async {
    try {
      debugPrint('📖 [BCommentService] Fetching comments for listingId: $listingId');
      
      // Query without orderBy to avoid composite index requirement
      // We'll sort in memory instead
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('listingId', isEqualTo: listingId)
          .get();
      
      // Map to list and sort by createdAt in memory
      final comments = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // Sort by createdAt in memory (oldest first)
      comments.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        
        // Handle Timestamp objects
        DateTime aDateTime;
        DateTime bDateTime;
        
        if (aDate is Timestamp) {
          aDateTime = aDate.toDate();
        } else if (aDate is DateTime) {
          aDateTime = aDate;
        } else {
          aDateTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
        
        if (bDate is Timestamp) {
          bDateTime = bDate.toDate();
        } else if (bDate is DateTime) {
          bDateTime = bDate;
        } else {
          bDateTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
        
        return aDateTime.compareTo(bDateTime); // Ascending order (oldest first)
      });
      
      debugPrint('✅ [BCommentService] Found ${comments.length} comments for listingId: $listingId');
      return comments;
    } catch (e) {
      debugPrint('❌ [BCommentService] Error getting comments by listing: $e');
      rethrow; // Rethrow so we can see the actual error
    }
  }

  /// Get comments by looking for post ID
  Future<List<Map<String, dynamic>>> getCommentsByLookingForPost(String lookingForPostId) async {
    try {
      debugPrint('📖 [BCommentService] Fetching comments for lookingForPostId: $lookingForPostId');
      
      // Query without orderBy to avoid composite index requirement
      // We'll sort in memory instead
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('lookingForPostId', isEqualTo: lookingForPostId)
          .get();
      
      // Map to list and sort by createdAt in memory
      final comments = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // Sort by createdAt in memory (oldest first)
      comments.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        
        // Handle Timestamp objects
        DateTime aDateTime;
        DateTime bDateTime;
        
        if (aDate is Timestamp) {
          aDateTime = aDate.toDate();
        } else if (aDate is DateTime) {
          aDateTime = aDate;
        } else {
          aDateTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
        
        if (bDate is Timestamp) {
          bDateTime = bDate.toDate();
        } else if (bDate is DateTime) {
          bDateTime = bDate;
        } else {
          bDateTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
        
        return aDateTime.compareTo(bDateTime); // Ascending order (oldest first)
      });
      
      debugPrint('✅ [BCommentService] Found ${comments.length} comments for lookingForPostId: $lookingForPostId');
      return comments;
    } catch (e) {
      debugPrint('❌ [BCommentService] Error getting comments by looking for post: $e');
      rethrow; // Rethrow so we can see the actual error
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

