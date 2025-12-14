import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rentease_app/models/bank_model.dart';

/// Bank Service
/// 
/// Handles fetching bank data from Firestore.
/// Banks are stored in a 'banks' collection with Cloudinary logo URLs.
class BBankService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'banks';

  /// Get all banks from Firestore
  /// Returns list of BankModel with logos from Cloudinary
  Future<List<BankModel>> getAllBanks() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => BankModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ [BBankService] Error fetching banks: $e');
      return [];
    }
  }

  /// Get a single bank by ID
  Future<BankModel?> getBankById(String bankId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(bankId).get();
      if (doc.exists) {
        return BankModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [BBankService] Error fetching bank: $e');
      return null;
    }
  }

  /// Stream banks for real-time updates
  Stream<List<BankModel>> streamBanks() {
    return _firestore
        .collection(_collectionName)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BankModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
