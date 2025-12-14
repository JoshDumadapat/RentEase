import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LandmarkSuggestion {
  final String name;
  final String displayName;
  final String? type; // e.g., "mall", "school", "hospital"
  final double? latitude;
  final double? longitude;

  LandmarkSuggestion({
    required this.name,
    required this.displayName,
    this.type,
    this.latitude,
    this.longitude,
  });
}

class LandmarkSuggestionService {
  /// Search for landmarks/places near a location using Nominatim
  /// 
  /// [query] - The search query (e.g., "SM Mall", "University")
  /// [latitude] - Optional: Latitude to search nearby (if null, searches globally)
  /// [longitude] - Optional: Longitude to search nearby (if null, searches globally)
  /// [limit] - Maximum number of results (default: 5)
  static Future<List<LandmarkSuggestion>> searchLandmarks({
    required String query,
    double? latitude,
    double? longitude,
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      String url;
      
      if (latitude != null && longitude != null) {
        // Search near a specific location
        url = 'https://nominatim.openstreetmap.org/search?'
            'q=$query&'
            'format=json&'
            'lat=$latitude&'
            'lon=$longitude&'
            'radius=5000&' // 5km radius
            'limit=$limit&'
            'addressdetails=1&'
            'accept-language=en';
      } else {
        // Global search
        url = 'https://nominatim.openstreetmap.org/search?'
            'q=$query&'
            'format=json&'
            'limit=$limit&'
            'addressdetails=1&'
            'accept-language=en';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'RentEase App', // Required by Nominatim
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        return data.map((item) {
          final displayName = item['display_name'] as String? ?? '';
          final name = item['name'] as String? ?? displayName;
          final type = item['type'] as String?;
          final lat = item['lat'] != null ? double.tryParse(item['lat'] as String) : null;
          final lon = item['lon'] != null ? double.tryParse(item['lon'] as String) : null;
          
          return LandmarkSuggestion(
            name: name,
            displayName: displayName,
            type: type,
            latitude: lat,
            longitude: lon,
          );
        }).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error searching landmarks: $e');
      return [];
    }
  }

  /// Search for nearby places/landmarks based on coordinates
  /// Useful for suggesting landmarks near the selected address
  static Future<List<LandmarkSuggestion>> searchNearbyLandmarks({
    required double latitude,
    required double longitude,
    String? query,
    int limit = 10,
  }) async {
    try {
      String url;
      
      if (query != null && query.trim().isNotEmpty) {
        // Search with query near location
        url = 'https://nominatim.openstreetmap.org/search?'
            'q=$query&'
            'format=json&'
            'lat=$latitude&'
            'lon=$longitude&'
            'radius=2000&' // 2km radius for nearby places
            'limit=$limit&'
            'addressdetails=1&'
            'accept-language=en';
      } else {
        // Search for common landmarks near location (malls, schools, hospitals, etc.)
        url = 'https://nominatim.openstreetmap.org/search?'
            'q=landmark&'
            'format=json&'
            'lat=$latitude&'
            'lon=$longitude&'
            'radius=2000&'
            'limit=$limit&'
            'addressdetails=1&'
            'accept-language=en';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'RentEase App',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Filter and prioritize common landmarks
        final landmarkTypes = ['mall', 'school', 'university', 'hospital', 'market', 
                               'church', 'park', 'restaurant', 'bank', 'pharmacy'];
        
        return data
            .where((item) {
              final type = (item['type'] as String? ?? '').toLowerCase();
              final category = (item['class'] as String? ?? '').toLowerCase();
              return landmarkTypes.any((lt) => type.contains(lt) || category.contains(lt));
            })
            .take(limit)
            .map((item) {
              final displayName = item['display_name'] as String? ?? '';
              final name = item['name'] as String? ?? displayName;
              final type = item['type'] as String?;
              final lat = item['lat'] != null ? double.tryParse(item['lat'] as String) : null;
              final lon = item['lon'] != null ? double.tryParse(item['lon'] as String) : null;
              
              return LandmarkSuggestion(
                name: name,
                displayName: displayName,
                type: type,
                latitude: lat,
                longitude: lon,
              );
            })
            .toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error searching nearby landmarks: $e');
      return [];
    }
  }
}
