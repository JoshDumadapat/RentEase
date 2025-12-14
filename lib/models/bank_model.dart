/// Bank Model
/// 
/// Represents a bank with its logo and details.
class BankModel {
  final String id;
  final String name;
  final String logoUrl; // Cloudinary URL
  final String? code; // Bank code (optional)

  const BankModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.code,
  });

  /// Create BankModel from Firestore document
  factory BankModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BankModel(
      id: id,
      name: data['name'] as String? ?? '',
      logoUrl: data['logoUrl'] as String? ?? '',
      code: data['code'] as String?,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      if (code != null) 'code': code,
    };
  }
}
