import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerService {
  /// Get current location using GPS
  /// Returns: {latitude, longitude, address} or error
  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      // Check permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {'error': 'Location services are disabled'};
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'error': 'Location permissions denied'};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {'error': 'Location permissions permanently denied'};
      }

      // Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = '';
      if (placemarks.isNotEmpty) {
        address = _formatAddress(placemarks[0]);
      }

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
      };
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return {'error': e.toString()};
    }
  }

  /// Get address from coordinates
  static Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        lat, 
        lng,
      );
      
      if (placemarks.isNotEmpty) {
        // Try to find the best placemark with a street name
        Placemark? bestPlacemark;
        for (var placemark in placemarks) {
          // Prefer placemarks with actual street names (not Plus Codes or coordinates)
          final street = placemark.street ?? '';
          if (street.isNotEmpty && 
              !street.contains(RegExp(r'^[0-9A-Z]{2,}\+[0-9A-Z]+')) && // Not a Plus Code
              !street.contains(RegExp(r'^-?\d+\.?\d*,\s*-?\d+\.?\d*$'))) { // Not coordinates
            bestPlacemark = placemark;
            break;
          }
        }
        
        // If no good street found, use the first one
        bestPlacemark ??= placemarks[0];
        
        final formattedAddress = _formatAddress(bestPlacemark);
        
        // If the formatted address still looks like coordinates or Plus Code, try to improve it
        if (_isCoordinateOrPlusCode(formattedAddress) && placemarks.length > 1) {
          // Try other placemarks
          for (var placemark in placemarks.skip(1)) {
            final altAddress = _formatAddress(placemark);
            if (!_isCoordinateOrPlusCode(altAddress)) {
              return altAddress;
            }
          }
        }
        
        return formattedAddress;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }

  static bool _isCoordinateOrPlusCode(String address) {
    // Check if address is just coordinates
    if (RegExp(r'^-?\d+\.?\d*,\s*-?\d+\.?\d*$').hasMatch(address.trim())) {
      return true;
    }
    // Check if address starts with Plus Code pattern (e.g., "3J78+577")
    if (RegExp(r'^[0-9A-Z]{2,}\+[0-9A-Z]+').hasMatch(address.trim())) {
      return true;
    }
    return false;
  }

  static String _formatAddress(Placemark place) {
    List<String> parts = [];
    
    // Check if street contains Plus Code or coordinates - if so, skip it
    String? street = place.street;
    if (street != null && street.isNotEmpty) {
      // Skip if it's a Plus Code or coordinates
      if (!_isCoordinateOrPlusCode(street)) {
        // For Philippines, sometimes thoroughfare has the street name
        if (place.thoroughfare != null && 
            place.thoroughfare!.isNotEmpty && 
            place.thoroughfare != street) {
          parts.add(place.thoroughfare!);
        } else {
          parts.add(street);
        }
      }
    } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
      // Use thoroughfare if street is empty
      if (!_isCoordinateOrPlusCode(place.thoroughfare!)) {
        parts.add(place.thoroughfare!);
      }
    }
    
    // Add sub-thoroughfare (house/building number) if available
    if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
      parts.insert(0, place.subThoroughfare!);
    }
    
    // For Philippines: Add subLocality (Barangay) if available
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      // Format: "Brgy. X" or just the barangay name
      String barangay = place.subLocality!;
      if (!barangay.toLowerCase().startsWith('brgy') && 
          !barangay.toLowerCase().startsWith('barangay')) {
        barangay = 'Brgy. $barangay';
      }
      parts.add(barangay);
    }
    
    // Add locality (City/Municipality)
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    
    // Add administrative area (Province/Region)
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    
    // Only add country if it's not Philippines (to keep it shorter for PH addresses)
    if (place.country != null && 
        place.country!.isNotEmpty && 
        place.country!.toLowerCase() != 'philippines') {
      parts.add(place.country!);
    }
    
    // If we still don't have a good address, try to build from what we have
    if (parts.isEmpty) {
      // Fallback: use any available information
      if (place.name != null && place.name!.isNotEmpty) {
        parts.add(place.name!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        parts.add(place.locality!);
      }
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        parts.add(place.administrativeArea!);
      }
    }
    
    return parts.isEmpty 
        ? 'Location selected'
        : parts.join(', ');
  }
}
