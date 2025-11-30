import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service class for handling user data operations in Firestore
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user document exists in Firestore
  Future<bool> userExists(String uid) async {
    try {
      // Add timeout to prevent long waits (reduced to 5 seconds for faster response)
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Timeout checking if user exists');
              throw TimeoutException('Firestore query timed out', const Duration(seconds: 5));
            },
          );
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      // Return false on error/timeout - user will be redirected to sign up
      return false;
    }
  }

  /// Create or update user document in Firestore
  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    String? fname,
    String? lname,
    String? birthday,
    String? phone,
    String? countryCode,
    String? idImageFrontUrl,
    String? idImageBackUrl,
    String? faceWithIdUrl,
    String? userType,
    String? password,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userData = <String, dynamic>{
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
        if (fname != null) 'fname': fname,
        if (lname != null) 'lname': lname,
        if (birthday != null) 'birthday': birthday,
        if (phone != null) 'phone': phone,
        if (countryCode != null) 'countryCode': countryCode,
        if (idImageFrontUrl != null) 'id_image_front_url': idImageFrontUrl,
        if (idImageBackUrl != null) 'id_image_back_url': idImageBackUrl,
        if (faceWithIdUrl != null) 'face_with_id_url': faceWithIdUrl,
        if (userType != null) 'userType': userType,
        if (password != null) 'password': password,
        if (additionalData != null) ...additionalData,
      };

      // Check if document exists
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Create new document
        userData['createdAt'] = FieldValue.serverTimestamp();
        await docRef.set(userData);
      } else {
        // Update existing document (merge to avoid overwriting)
        await docRef.set(userData, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error creating/updating user: $e');
      rethrow;
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  /// Get user document reference
  DocumentReference getUserDocument(String uid) {
    return _firestore.collection('users').doc(uid);
  }
}

