import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/backend/BAdminService.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/models/user_model.dart';

/// Utility class for admin authentication and authorization
class AdminAuthUtils {
  static final BAdminService _adminService = BAdminService();
  static final BUserService _userService = BUserService();

  /// Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      return await _adminService.isAdmin(user.uid);
    } catch (e) {
      return false;
    }
  }

  /// Get current user model with admin check
  static Future<UserModel?> getCurrentUserModel() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userData = await _userService.getUserData(user.uid);
      if (userData == null) return null;

      return UserModel.fromFirestore(userData, user.uid);
    } catch (e) {
      return null;
    }
  }

  /// Verify admin access and return user model
  static Future<UserModel?> verifyAdminAccess() async {
    final userModel = await getCurrentUserModel();
    if (userModel == null || !userModel.isAdmin) {
      return null;
    }
    return userModel;
  }
}

