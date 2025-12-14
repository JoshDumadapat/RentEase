// ignore_for_file: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

/// Backend service for listing/property operations in Firestore
/// Handles all listing-related database operations
class BListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'listings';

  /// Create a new listing
  Future<String> createListing({
    required String userId,
    required String title,
    required String category,
    required String location,
    required double price,
    required String description,
    required int bedrooms,
    required int bathrooms,
    required double area,
    required List<String> imageUrls,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final listingData = <String, dynamic>{
        'userId': userId,
        'title': title,
        'category': category,
        'location': location,
        'price': price,
        'description': description,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'area': area,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (additionalData != null) ...additionalData,
      };

      final docRef = await _firestore.collection(_collectionName).add(listingData);
      return docRef.id;
    } catch (e) {
      // Error:'Error creating listing: $e');
      rethrow;
    }
  }

  /// Get listing by ID
  Future<Map<String, dynamic>?> getListing(String listingId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(listingId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      // Error:'Error getting listing: $e');
      return null;
    }
  }

  /// Get all listings
  Future<List<Map<String, dynamic>>> getAllListings() async {
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
      // Error:'Error getting all listings: $e');
      return [];
    }
  }

  /// Get listings by user ID
  Future<List<Map<String, dynamic>>> getListingsByUser(String userId) async {
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
      // Error:'Error getting listings by user: $e');
      return [];
    }
  }

  /// Get listings by category
  Future<List<Map<String, dynamic>>> getListingsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      // Error:'Error getting listings by category: $e');
      return [];
    }
  }

  /// Update listing
  Future<void> updateListing(String listingId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collectionName).doc(listingId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error:'Error updating listing: $e');
      rethrow;
    }
  }

  /// Delete listing
  Future<void> deleteListing(String listingId) async {
    try {
      await _firestore.collection(_collectionName).doc(listingId).delete();
    } catch (e) {
      // Error:'Error deleting listing: $e');
      rethrow;
    }
  }

  /// Search listings by query
  Future<List<Map<String, dynamic>>> searchListings(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      // Error:'Error searching listings: $e');
      return [];
    }
  }

  /// Get listing document reference
  DocumentReference getListingDocument(String listingId) {
    return _firestore.collection(_collectionName).doc(listingId);
  }

  /// Get user's favorite listings
  /// Favorites are stored in a 'favorites' collection with userId and listingId
  Future<List<Map<String, dynamic>>> getUserFavorites(String userId) async {
    try {
      // Get all favorite document IDs for this user
      final favoritesSnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      if (favoritesSnapshot.docs.isEmpty) {
        return [];
      }

      // Extract listing IDs from favorites
      final listingIds = favoritesSnapshot.docs
          .map((doc) => doc.data()['listingId'] as String?)
          .where((id) => id != null)
          .toList();

      if (listingIds.isEmpty) {
        return [];
      }

      // Fetch the actual listings
      final listings = <Map<String, dynamic>>[];
      for (final listingId in listingIds) {
        final listing = await getListing(listingId!);
        if (listing != null) {
          listings.add({
            'id': listingId,
            ...listing,
          });
        }
      }

      return listings;
    } catch (e) {
      // Error:'Error getting user favorites: $e');
      return [];
    }
  }

  /// Create or update a draft listing
  Future<String> saveDraft({
    required String userId,
    String? draftId,
    String? title,
    String? category,
    String? location,
    double? price,
    String? description,
    int? bedrooms,
    int? bathrooms,
    double? area,
    List<String>? imageUrls,
    int? currentStep,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final draftData = <String, dynamic>{
        'userId': userId,
        'isDraft': true,
        'updatedAt': FieldValue.serverTimestamp(),
        if (title != null) 'title': title,
        if (category != null) 'category': category,
        if (location != null) 'location': location,
        if (price != null) 'price': price,
        if (description != null) 'description': description,
        if (bedrooms != null) 'bedrooms': bedrooms,
        if (bathrooms != null) 'bathrooms': bathrooms,
        if (area != null) 'area': area,
        if (imageUrls != null) 'imageUrls': imageUrls,
        if (currentStep != null) 'currentStep': currentStep,
        if (additionalData != null) ...additionalData,
      };

      if (draftId != null) {
        // Update existing draft
        await _firestore.collection(_collectionName).doc(draftId).update(draftData);
        return draftId;
      } else {
        // Create new draft
        draftData['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _firestore.collection(_collectionName).add(draftData);
        return docRef.id;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get draft listings by user ID
  Future<List<Map<String, dynamic>>> getDraftsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('isDraft', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete draft
  Future<void> deleteDraft(String draftId) async {
    try {
      await _firestore.collection(_collectionName).doc(draftId).delete();
    } catch (e) {
      rethrow;
    }
  }
}

