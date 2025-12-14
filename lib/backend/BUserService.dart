// ignore_for_file: file_names
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper function to generate username from first name and last name
/// Example: "Ivan Josh Dumadapat" -> "ivanjoshdumadapat" (lowercase, no spaces)
/// If both are provided, combines them. If only one is provided, uses that.
String _generateUsername(String? fname, String? lname) {
  final fnameStr = fname?.trim() ?? '';
  final lnameStr = lname?.trim() ?? '';
  
  // Combine first name and last name
  final fullName = '$fnameStr $lnameStr'.trim();
  
  if (fullName.isEmpty) {
    return '';
  }
  
  // Convert to lowercase and remove all spaces and special characters
  // Keep only alphanumeric characters
  final username = fullName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), ''); // Remove all non-alphanumeric
  
  return username;
}

/// Backend service for user data operations in Firestore
/// Handles all user-related database operations
class BUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'users';

  /// Check if user document exists in Firestore
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(uid)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Firestore query timed out', const Duration(seconds: 5));
            },
          );
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// Create or update user document in Firestore
  /// 
  /// SECURITY NOTE: The password parameter is deprecated and ignored.
  /// Passwords are NEVER stored in Firestore. Firebase Auth handles
  /// password hashing and storage automatically. Passwords should only
  /// be used with Firebase Auth methods (signUpWithEmailAndPassword, etc.)
  /// 
  /// @param password - DEPRECATED: This parameter is ignored for security reasons.
  ///                   Passwords are handled by Firebase Auth, not Firestore.
  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    String? fname,
    String? lname,
    String? birthday,
    String? phone,
    String? countryCode,
    String? idNumber,
    String? idImageFrontUrl,
    String? idImageBackUrl,
    String? faceWithIdUrl,
    String? userType,
    String? password, // DEPRECATED: Never stored in Firestore for security
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Calculate displayName from fname and lname
      String? displayName;
      if (fname != null || lname != null) {
        final fnameStr = fname ?? '';
        final lnameStr = lname ?? '';
        displayName = '$fnameStr $lnameStr'.trim();
        if (displayName.isEmpty) {
          displayName = null;
        }
      }
      
      // If displayName is provided in additionalData, use it instead
      if (additionalData != null && additionalData['displayName'] != null) {
        displayName = additionalData['displayName'] as String?;
      }

      final userData = <String, dynamic>{
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
        if (fname != null) 'fname': fname,
        if (lname != null) 'lname': lname,
        if (displayName != null) 'displayName': displayName,
        if (birthday != null) 'birthday': birthday,
        if (phone != null) 'phone': phone,
        if (countryCode != null) 'countryCode': countryCode,
        if (idNumber != null) 'id_number': idNumber,
        if (idImageFrontUrl != null) 'id_image_front_url': idImageFrontUrl,
        if (idImageBackUrl != null) 'id_image_back_url': idImageBackUrl,
        if (faceWithIdUrl != null) 'face_with_id_url': faceWithIdUrl,
        if (userType != null) 'userType': userType,
        // SECURITY: Never store passwords in Firestore
        // Firebase Auth handles password hashing automatically
        // Passwords should only be used with Firebase Auth methods
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (additionalData != null) ...additionalData,
      };

      final docRef = _firestore.collection(_collectionName).doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        // New user creation - auto-generate username from first name + last name
        userData['createdAt'] = FieldValue.serverTimestamp();
        
        // Auto-generate username if not provided in additionalData
        if ((additionalData == null || additionalData['username'] == null) && 
            (fname != null || lname != null)) {
          final generatedUsername = _generateUsername(fname, lname);
          if (generatedUsername.isNotEmpty) {
            userData['username'] = generatedUsername;
            debugPrint('✅ [BUserService] Auto-generated username: $generatedUsername from fname: "$fname", lname: "$lname"');
          }
        }
        
        await docRef.set(userData);
      } else {
        // Existing user update - preserve existing username if not provided
        // Only update username if explicitly provided in additionalData
        if (additionalData != null && additionalData['username'] != null) {
          userData['username'] = additionalData['username'];
        }
        // If username is not in additionalData, don't include it in userData
        // This preserves the existing username when using merge: true
        
        await docRef.set(userData, SetOptions(merge: true));
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        // Debug: Log username from Firestore
        if (data != null) {
          debugPrint('🔍 [BUserService] Fetched username from Firestore: ${data['username']} (type: ${data['username'].runtimeType})');
        }
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [BUserService] Error fetching user data: $e');
      return null;
    }
  }

  /// Get user document reference
  DocumentReference getUserDocument(String uid) {
    return _firestore.collection(_collectionName).doc(uid);
  }

  /// Update user field
  Future<void> updateUserField(String uid, String field, dynamic value) async {
    try {
      await _firestore.collection(_collectionName).doc(uid).update({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Delete user document
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_collectionName).doc(uid).delete();
      debugPrint('✅ [BUserService] User document deleted: $uid');
    } catch (e) {
      debugPrint('❌ [BUserService] Error deleting user: $e');
      rethrow;
    }
  }

  /// Delete all user data (comprehensive cascade delete)
  /// This deletes all user-related data across all collections
  Future<void> deleteAllUserData(String uid) async {
    try {
      debugPrint('🗑️ [BUserService] Starting comprehensive deletion for user: $uid');
      
      // Get user's listing IDs first (before deletion) for cascade operations
      final userListingsSnapshot = await _firestore
          .collection('listings')
          .where('userId', isEqualTo: uid)
          .get();
      final userListingIds = userListingsSnapshot.docs.map((doc) => doc.id).toList();
      
      // 1. Delete all user's listings
      try {
        if (userListingsSnapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in userListingsSnapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          debugPrint('✅ [BUserService] Deleted ${userListingsSnapshot.docs.length} listings');
        }
      } catch (e) {
        debugPrint('⚠️ [BUserService] Error deleting listings: $e');
        // Continue with other deletions
      }

      // 2. Delete all user's favorites
      try {
        final favoritesSnapshot = await _firestore
            .collection('favorites')
            .where('userId', isEqualTo: uid)
            .get();
        
        if (favoritesSnapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in favoritesSnapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          debugPrint('✅ [BUserService] Deleted ${favoritesSnapshot.docs.length} favorites');
        }
      } catch (e) {
        debugPrint('⚠️ [BUserService] Error deleting favorites: $e');
      }

      // 3. Delete all user's comments
      try {
        final commentsSnapshot = await _firestore
            .collection('comments')
            .where('userId', isEqualTo: uid)
            .get();
        
        if (commentsSnapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in commentsSnapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          debugPrint('✅ [BUserService] Deleted ${commentsSnapshot.docs.length} comments');
        }
      } catch (e) {
        debugPrint('⚠️ [BUserService] Error deleting comments: $e');
      }

      // 4. Delete all user's reviews
      try {
        final reviewsSnapshot = await _firestore
            .collection('reviews')
            .where('userId', isEqualTo: uid)
            .get();
        
        if (reviewsSnapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in reviewsSnapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          debugPrint('✅ [BUserService] Deleted ${reviewsSnapshot.docs.length} reviews');
        }
      } catch (e) {
        debugPrint('⚠️ [BUserService] Error deleting reviews: $e');
      }

      // 5. Delete all user's "Looking For" posts
      try {
        final lookingForSnapshot = await _firestore
            .collection('lookingForPosts')
            .where('userId', isEqualTo: uid)
            .get();
        
        if (lookingForSnapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in lookingForSnapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          debugPrint('✅ [BUserService] Deleted ${lookingForSnapshot.docs.length} looking for posts');
        }
      } catch (e) {
        debugPrint('⚠️ [BUserService] Error deleting looking for posts: $e');
      }

      // 6. Delete user document (must be last)
      try {
        await _firestore.collection(_collectionName).doc(uid).delete();
        debugPrint('✅ [BUserService] User document deleted: $uid');
      } catch (e) {
        debugPrint('❌ [BUserService] Error deleting user document: $e');
        rethrow;
      }

      debugPrint('✅ [BUserService] Comprehensive deletion completed for user: $uid');
    } catch (e) {
      debugPrint('❌ [BUserService] Error in comprehensive deletion: $e');
      rethrow;
    }
  }

  /// Deactivate user account
  /// Marks the account as deactivated but preserves all data
  /// User can reactivate by logging in again
  Future<void> deactivateUser({
    required String uid,
    required String reason,
    String? customReason,
  }) async {
    try {
      // Update user document with deactivation status
      await _firestore.collection(_collectionName).doc(uid).update({
        'isDeactivated': true,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'deactivationReason': reason,
        if (customReason != null && customReason.isNotEmpty) 'deactivationCustomReason': customReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log deactivation in separate collection for analytics
      await _firestore.collection('deactivated_accounts').add({
        'userId': uid,
        'email': (await getUserData(uid))?['email'] ?? 'unknown',
        'reason': reason,
        if (customReason != null && customReason.isNotEmpty) 'customReason': customReason,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ [BUserService] User account deactivated: $uid');
    } catch (e) {
      debugPrint('❌ [BUserService] Error deactivating user: $e');
      rethrow;
    }
  }

  /// Reactivate user account
  /// Removes deactivation status and restores account access
  Future<void> reactivateUser(String uid) async {
    try {
      await _firestore.collection(_collectionName).doc(uid).update({
        'isDeactivated': false,
        'reactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Remove deactivation-related fields
        'deactivatedAt': FieldValue.delete(),
        'deactivationReason': FieldValue.delete(),
        'deactivationCustomReason': FieldValue.delete(),
      });

      debugPrint('✅ [BUserService] User account reactivated: $uid');
    } catch (e) {
      debugPrint('❌ [BUserService] Error reactivating user: $e');
      rethrow;
    }
  }

  /// Check if user account is deactivated
  Future<bool> isUserDeactivated(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData?['isDeactivated'] as bool? ?? false;
    } catch (e) {
      debugPrint('❌ [BUserService] Error checking deactivation status: $e');
      return false;
    }
  }

  /// Batch check which users are deactivated
  /// Returns a Set of user IDs that are deactivated
  Future<Set<String>> getDeactivatedUserIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) {
        debugPrint('🔍 [BUserService] No user IDs provided for deactivation check');
        return {};
      }
      
      // Remove duplicates
      final uniqueUserIds = userIds.toSet().toList();
      debugPrint('🔍 [BUserService] Checking deactivation status for ${uniqueUserIds.length} unique users');
      
      // Batch fetch user documents (Firestore allows up to 10 in a single batch)
      // We'll need to do multiple batches if there are more than 10 users
      final deactivatedIds = <String>{};
      
      for (var i = 0; i < uniqueUserIds.length; i += 10) {
        final batch = uniqueUserIds.skip(i).take(10).toList();
        debugPrint('🔍 [BUserService] Fetching batch ${(i ~/ 10) + 1} with ${batch.length} users');
        final futures = batch.map((uid) => _firestore.collection(_collectionName).doc(uid).get());
        final docs = await Future.wait(futures);
        
        for (var j = 0; j < docs.length; j++) {
          final doc = docs[j];
          final userId = batch[j];
          if (doc.exists) {
            final data = doc.data();
            final isDeactivated = data?['isDeactivated'] == true;
            if (isDeactivated) {
              deactivatedIds.add(userId);
              debugPrint('🚫 [BUserService] User $userId is deactivated');
            }
          } else {
            debugPrint('⚠️ [BUserService] User document not found: $userId (assuming not deactivated)');
          }
        }
      }
      
      debugPrint('✅ [BUserService] Found ${deactivatedIds.length} deactivated users out of ${uniqueUserIds.length} checked');
      return deactivatedIds;
    } catch (e, stackTrace) {
      debugPrint('❌ [BUserService] Error batch checking deactivation status: $e');
      debugPrint('❌ [BUserService] Stack trace: $stackTrace');
      return {}; // Return empty set on error to be safe (won't filter anything)
    }
  }

  /// Update user email in Firestore
  /// This should be called after updating email in Firebase Auth
  Future<void> updateUserEmail(String uid, String newEmail) async {
    try {
      await _firestore.collection(_collectionName).doc(uid).update({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [BUserService] User email updated in Firestore: $uid -> $newEmail');
    } catch (e) {
      debugPrint('❌ [BUserService] Error updating email: $e');
      rethrow;
    }
  }

  /// Check if user is verified
  /// Returns true if user has isVerified field set to true in Firestore
  Future<bool> isUserVerified(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData?['isVerified'] == true;
    } catch (e) {
      debugPrint('❌ [BUserService] Error checking verification status: $e');
      return false;
    }
  }

  /// Update user verification status
  /// Sets isVerified to true/false in Firestore
  Future<void> updateVerificationStatus(String uid, bool isVerified) async {
    try {
      await _firestore.collection(_collectionName).doc(uid).update({
        'isVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [BUserService] User verification status updated: $uid -> $isVerified');
    } catch (e) {
      debugPrint('❌ [BUserService] Error updating verification status: $e');
      rethrow;
    }
  }
}

