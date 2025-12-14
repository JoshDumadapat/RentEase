import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Helper function to set admin role for current user
/// 
/// Usage: Call this function once to set your current user as admin
/// After running, you can delete this file or comment out the call
Future<void> setCurrentUserAsAdmin() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in');
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'role': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Admin role set for user: ${user.uid}');
    debugPrint('✅ Email: ${user.email}');
  } catch (e) {
    debugPrint('❌ Error setting admin role: $e');
  }
}

/// Helper function to set admin role for a specific user by UID
/// 
/// Usage: setUserAsAdmin('YkvOU98qgZfE3uM30sHTLX5Z7Mx1')
Future<void> setUserAsAdmin(String userId) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'role': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Admin role set for user: $userId');
  } catch (e) {
    debugPrint('❌ Error setting admin role: $e');
  }
}

