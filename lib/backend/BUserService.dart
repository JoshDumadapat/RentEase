// ignore_for_file: file_names
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    String? profileImageUrl,
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
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (additionalData != null) ...additionalData,
      };

      final docRef = _firestore.collection(_collectionName).doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        userData['createdAt'] = FieldValue.serverTimestamp();
        await docRef.set(userData);
      } else {
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
        return doc.data();
      }
      return null;
    } catch (e) {
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
    } catch (e) {
      rethrow;
    }
  }
}

