// ignore_for_file: file_names
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/backend/BListingService.dart';
import 'package:rentease_app/backend/BNotificationService.dart';
import 'package:rentease_app/backend/BUserService.dart';

/// Backend service for favorite operations in Firestore
/// Handles all favorite-related database operations
class BFavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BListingService _listingService = BListingService();
  final BNotificationService _notificationService = BNotificationService();
  final BUserService _userService = BUserService();
  static const String _collectionName = 'favorites';

  /// Add a listing to user's favorites
  Future<void> addFavorite({
    required String userId,
    required String listingId,
  }) async {
    try {
      // Check if already favorited
      final existing = await isFavorite(userId, listingId);
      if (existing) {
        debugPrint('⚠️ [BFavoriteService] Listing already in favorites');
        return;
      }

      // Create favorite document
      await _firestore.collection(_collectionName).add({
        'userId': userId,
        'listingId': listingId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment favorite count on listing
      await _listingService.incrementFavoriteCount(listingId);

      // Create notification for the listing owner
      try {
        final listing = await _listingService.getListing(listingId);
        if (listing != null) {
          final listingOwnerId = listing['userId'] as String?;
          if (listingOwnerId != null && listingOwnerId != userId) {
            // Get favoriter's data
            final favoriterData = await _userService.getUserData(userId);
            final favoriterName = favoriterData?['displayName'] as String? ??
                (favoriterData?['fname'] != null && favoriterData?['lname'] != null
                    ? '${favoriterData!['fname']} ${favoriterData['lname']}'.trim()
                    : favoriterData?['fname'] as String? ??
                        favoriterData?['lname'] as String? ??
                        favoriterData?['username'] as String? ??
                        'Someone');
            final favoriterAvatarUrl = favoriterData?['profileImageUrl'] as String?;

            await _notificationService.notifyFavoriteOnListing(
              listingOwnerId: listingOwnerId,
              favoriterId: userId,
              favoriterName: favoriterName,
              favoriterAvatarUrl: favoriterAvatarUrl,
              listingId: listingId,
              listingTitle: listing['title'] as String?,
            );
            debugPrint('✅ [BFavoriteService] Notification created for listing owner');
          }
        }
      } catch (e) {
        // Log error but don't throw - notification failure shouldn't break favorite creation
        debugPrint('⚠️ [BFavoriteService] Error creating notification: $e');
      }

      debugPrint('✅ [BFavoriteService] Favorite added: $userId -> $listingId');
    } catch (e) {
      debugPrint('❌ [BFavoriteService] Error adding favorite: $e');
      rethrow;
    }
  }

  /// Remove a listing from user's favorites
  Future<void> removeFavorite({
    required String userId,
    required String listingId,
  }) async {
    try {
      // Find favorite document
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('listingId', isEqualTo: listingId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ [BFavoriteService] Favorite not found');
        return;
      }

      // Delete favorite document
      await snapshot.docs.first.reference.delete();

      // Decrement favorite count on listing
      await _listingService.decrementFavoriteCount(listingId);

      debugPrint('✅ [BFavoriteService] Favorite removed: $userId -> $listingId');
    } catch (e) {
      debugPrint('❌ [BFavoriteService] Error removing favorite: $e');
      rethrow;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite({
    required String userId,
    required String listingId,
  }) async {
    try {
      final isFav = await isFavorite(userId, listingId);
      if (isFav) {
        await removeFavorite(userId: userId, listingId: listingId);
        return false;
      } else {
        await addFavorite(userId: userId, listingId: listingId);
        return true;
      }
    } catch (e) {
      debugPrint('❌ [BFavoriteService] Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Check if listing is in user's favorites
  Future<bool> isFavorite(String userId, String listingId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('listingId', isEqualTo: listingId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [BFavoriteService] Error checking favorite: $e');
      return false;
    }
  }

  /// Get all favorite listing IDs for a user
  Future<List<String>> getFavoriteListingIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['listingId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();
    } catch (e) {
      debugPrint('❌ [BFavoriteService] Error getting favorite IDs: $e');
      return [];
    }
  }

  /// Get all favorite listings for a user (with listing data)
  Future<List<Map<String, dynamic>>> getFavoriteListings(String userId) async {
    try {
      final favoriteIds = await getFavoriteListingIds(userId);
      if (favoriteIds.isEmpty) return [];

      final listings = <Map<String, dynamic>>[];
      final listingService = BListingService();

      for (final listingId in favoriteIds) {
        final listing = await listingService.getListing(listingId);
        if (listing != null) {
          listings.add({
            'id': listingId,
            ...listing,
          });
        }
      }

      // Sort by createdAt descending
      listings.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      return listings;
    } catch (e) {
      debugPrint('❌ [BFavoriteService] Error getting favorite listings: $e');
      return [];
    }
  }

  /// Get favorite count for a listing
  Future<int> getFavoriteCount(String listingId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('listingId', isEqualTo: listingId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ [BFavoriteService] Error getting favorite count: $e');
      return 0;
    }
  }

  /// Get favorite document ID (if exists)
  Future<String?> getFavoriteDocumentId(String userId, String listingId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('listingId', isEqualTo: listingId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [BFavoriteService] Error getting favorite document ID: $e');
      return null;
    }
  }
}

