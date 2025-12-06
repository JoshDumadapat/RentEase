import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';

/// Cloudinary Service
/// 
/// Handles image uploads to Cloudinary cloud storage.
/// All images uploaded through this service will be stored in Cloudinary.
/// 
/// Upload Presets:
/// - rentease_profile: For user profile images (folder: users)
/// - rentease_properties: For rental property images (folder: properties)
class CloudinaryService {
  // Cloudinary credentials
  static const String _cloudName = 'dqymvfmbi';
  static const String _apiKey = '521481162223833';
  static const String _apiSecret = 'Oo8-fwyxqi-k8GQijCS36TB1xfk';
  
  // Upload presets (for signed uploads)
  static const String _presetProfile = 'rentease_profile';
  static const String _presetProperties = 'rentease_properties';
  
  // Base URL for Cloudinary API
  static const String _baseUrl = 'https://api.cloudinary.com/v1_1';
  
  /// Upload a single image file to Cloudinary
  /// 
  /// [file] - The image file to upload (XFile from image_picker)
  /// [uploadType] - Type of upload: 'profile' for user images, 'property' for property images
  /// [publicId] - Optional custom public ID for the image
  /// 
  /// Returns the uploaded image URL if successful, null otherwise
  Future<String?> uploadImage({
    required XFile file,
    required String uploadType, // 'profile' or 'property'
    String? publicId,
  }) async {
    // Determine preset and folder based on upload type
    final preset = uploadType == 'profile' ? _presetProfile : _presetProperties;
    final folder = uploadType == 'profile' ? 'users' : 'properties';
    try {
      final fileBytes = await file.readAsBytes();
      final fileName = file.name;
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create upload URL
      final uploadUrl = '$_baseUrl/$_cloudName/image/upload';
      
      // Prepare form data
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );
      
      // Add parameters for signed uploads
      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['folder'] = folder;
      request.fields['upload_preset'] = preset;
      
      if (publicId != null) {
        request.fields['public_id'] = publicId;
      }
      
      // Generate signature for signed uploads
      final signature = _generateSignature(
        timestamp: timestamp,
        folder: folder,
        publicId: publicId,
        preset: preset,
      );
      request.fields['signature'] = signature;
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['secure_url'] as String?;
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
  
  /// Upload multiple images to Cloudinary
  /// 
  /// [files] - List of image files to upload
  /// [uploadType] - Type of upload: 'profile' for user images, 'property' for property images
  /// 
  /// Returns list of uploaded image URLs (null for failed uploads)
  Future<List<String?>> uploadMultipleImages({
    required List<XFile> files,
    required String uploadType,
  }) async {
    final List<String?> urls = [];
    
    for (final file in files) {
      final url = await uploadImage(
        file: file,
        uploadType: uploadType,
      );
      urls.add(url);
    }
    
    return urls;
  }
  
  /// Delete an image from Cloudinary
  /// 
  /// [publicId] - The public ID of the image to delete
  /// 
  /// Returns true if deletion was successful
  Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateDeleteSignature(publicId: publicId, timestamp: timestamp);
      
      final url = Uri.parse(
        '$_baseUrl/$_cloudName/image/destroy?'
        'public_id=$publicId&'
        'timestamp=$timestamp&'
        'api_key=$_apiKey&'
        'signature=$signature',
      );
      
      final response = await http.post(url);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['result'] == 'ok';
      }
      
      return false;
    } catch (_) {
      return false;
    }
  }
  
  /// Generate signature for signed uploads
  String _generateSignature({
    required String timestamp,
    required String folder,
    required String preset,
    String? publicId,
  }) {
    final params = <String, String>{
      'timestamp': timestamp,
      'folder': folder,
      'upload_preset': preset,
    };
    
    if (publicId != null) {
      params['public_id'] = publicId;
    }
    
    // Sort parameters alphabetically
    final sortedParams = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    // Create signature string: param1=value1&param2=value2...&apiSecret
    final signatureString = sortedParams
        .map((e) => '${e.key}=${e.value}')
        .join('&') + _apiSecret;
    
    // Generate SHA1 hash
    final bytes = utf8.encode(signatureString);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }
  
  /// Generate signature for delete operations
  String _generateDeleteSignature({
    required String publicId,
    required String timestamp,
  }) {
    final signatureString = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    final bytes = utf8.encode(signatureString);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
  
  /// Get optimized image URL with transformations
  /// 
  /// [publicId] - The public ID of the image
  /// [width] - Optional width for resizing
  /// [height] - Optional height for resizing
  /// [quality] - Optional quality (auto, auto:good, auto:best, etc.)
  /// [format] - Optional format (auto, webp, jpg, png)
  /// 
  /// Returns the optimized image URL
  String getOptimizedImageUrl({
    required String publicId,
    int? width,
    int? height,
    String quality = 'auto:good',
    String format = 'auto',
  }) {
    final transformations = <String>[];
    
    if (width != null || height != null) {
      final size = 'w_${width ?? 'auto'},h_${height ?? 'auto'},c_limit';
      transformations.add(size);
    }
    
    transformations.add('q_$quality');
    transformations.add('f_$format');
    
    final transformString = transformations.join(',');
    return 'https://res.cloudinary.com/$_cloudName/image/upload/$transformString/$publicId';
  }
}

