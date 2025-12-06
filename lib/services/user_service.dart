import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/backend/BUserService.dart';

/// Service class for handling user data operations
/// 
/// This is a wrapper around BUserService for backward compatibility.
/// All backend logic has been moved to BUserService.
/// 
/// @deprecated Use BUserService directly for new code
class UserService {
  final BUserService _backendService = BUserService();

  /// Check if user document exists in Firestore
  Future<bool> userExists(String uid) => _backendService.userExists(uid);

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
  }) =>
      _backendService.createOrUpdateUser(
        uid: uid,
        email: email,
        fname: fname,
        lname: lname,
        birthday: birthday,
        phone: phone,
        countryCode: countryCode,
        idImageFrontUrl: idImageFrontUrl,
        idImageBackUrl: idImageBackUrl,
        faceWithIdUrl: faceWithIdUrl,
        userType: userType,
        password: password,
        profileImageUrl: profileImageUrl,
        additionalData: additionalData,
      );

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) => _backendService.getUserData(uid);

  /// Get user document reference
  DocumentReference getUserDocument(String uid) => _backendService.getUserDocument(uid);
}

