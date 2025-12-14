import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Subspace AI Service
/// 
/// Handles fetching Subspace AI configuration including logo URL from Firestore
class SubspaceAIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Default Cloudinary URL (fallback if Firestore is not available)
  static const String _defaultLogoUrl = 'https://res.cloudinary.com/dqymvfmbi/image/upload/v1765755084/ai/subspace_logo.jpg';
  
  /// Get Subspace AI logo URL from Firestore or use default
  Future<String> getLogoUrl() async {
    try {
      final doc = await _firestore.collection('app_config').doc('subspace_ai').get();
      if (doc.exists) {
        final data = doc.data();
        final logoUrl = data?['logoUrl'] as String?;
        if (logoUrl != null && logoUrl.isNotEmpty) {
          return logoUrl;
        }
      }
      return _defaultLogoUrl;
    } catch (e) {
      debugPrint('❌ [SubspaceAIService] Error fetching logo URL: $e');
      return _defaultLogoUrl;
    }
  }
  
  /// Stream logo URL from Firestore
  Stream<String> getLogoUrlStream() {
    return _firestore
        .collection('app_config')
        .doc('subspace_ai')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data();
        final logoUrl = data?['logoUrl'] as String?;
        if (logoUrl != null && logoUrl.isNotEmpty) {
          return logoUrl;
        }
      }
      return _defaultLogoUrl;
    });
  }
  
  /// Get Subspace AI name
  String getName() {
    return 'Subspace';
  }
}
