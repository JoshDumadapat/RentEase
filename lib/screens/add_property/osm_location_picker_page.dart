import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class OSMLocationPickerPage extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialAddress;

  const OSMLocationPickerPage({
    super.key,
    this.initialPosition,
    this.initialAddress,
  });

  @override
  State<OSMLocationPickerPage> createState() => _OSMLocationPickerPageState();
}

class _OSMLocationPickerPageState extends State<OSMLocationPickerPage> {
  final MapController _mapController = MapController();
  LatLng? _selectedPosition;
  String? _selectedAddress = '';
  bool _isLoading = false;
  bool _isLoadingAddress = false;
  Timer? _debounceTimer;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _selectedAddress = widget.initialAddress;
    
    // If no initial position, get GPS location immediately
    if (_selectedPosition == null) {
      setState(() => _isLoading = true);
      // Wait for the first frame before getting location
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getCurrentLocation();
      });
    } else {
      // If we have initial position, just get address
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getAddressFromCoordinates(_selectedPosition!);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_selectedPosition != null) {
      // If we have initial position, just get address
      await _getAddressFromCoordinates(_selectedPosition!);
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled');
        setState(() => _isLoading = false);
        // Set default to Manila if location services disabled
        _setDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions denied');
          setState(() => _isLoading = false);
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions permanently denied');
        setState(() => _isLoading = false);
        _setDefaultLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final latLng = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedPosition = latLng;
        _isLoading = false;
      });

      // Wait for map to be ready before moving
      _moveToLocation(latLng, 15.0);
      await _getAddressFromCoordinates(latLng);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error getting location: $e');
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    // Default to Davao, Philippines (closer to user's location)
    final defaultLatLng = const LatLng(7.1907, 125.4553);
    setState(() {
      _selectedPosition = defaultLatLng;
      _isLoading = false;
    });
    // Wait for map to be ready before moving
    _moveToLocation(defaultLatLng, 12.0);
    _getAddressFromCoordinates(defaultLatLng);
  }
  
  void _moveToLocation(LatLng location, double zoom) {
    if (_mapReady) {
      try {
        _mapController.move(location, zoom);
      } catch (e) {
        // Map might not be fully ready yet, retry after a delay
        _retryMoveLocation(location, zoom, 200);
      }
    } else {
      // If map not ready, wait and try again with multiple retries
      _retryMoveLocation(location, zoom, 300);
    }
  }
  
  void _retryMoveLocation(LatLng location, double zoom, int delayMs) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      
      if (_mapReady) {
        try {
          _mapController.move(location, zoom);
        } catch (e) {
          // Retry one more time
          if (delayMs < 1000) {
            _retryMoveLocation(location, zoom, delayMs + 200);
          }
        }
      } else {
        // Map still not ready, retry
        if (delayMs < 1000) {
          _retryMoveLocation(location, zoom, delayMs + 200);
        }
      }
    });
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    setState(() => _isLoadingAddress = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        // Use the first placemark - it's usually the most accurate
        final formattedAddress = _formatAddress(placemarks[0]);
        
        setState(() {
          _selectedAddress = formattedAddress;
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _selectedAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      setState(() {
        _selectedAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _isLoadingAddress = false;
      });
    }
  }


  String _formatAddress(Placemark place) {
    List<String> parts = [];
    
    // Prioritize street/thoroughfare (most important for accuracy)
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
      parts.add(place.thoroughfare!);
    }
    
    // Add sub-thoroughfare (house/building number) if available
    if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
      parts.insert(0, place.subThoroughfare!);
    }
    
    // Add subLocality (Barangay) if available
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }
    
    // Add locality (City/Municipality)
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    
    // Add administrative area (Province/Region)
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    
    // Only add country if it's not Philippines
    if (place.country != null && 
        place.country!.isNotEmpty && 
        place.country!.toLowerCase() != 'philippines') {
      parts.add(place.country!);
    }
    
    // If we still don't have a good address, use coordinates
    if (parts.isEmpty) {
      return 'Location selected';
    }
    
    return parts.join(', ');
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedPosition = point;
    });
    _getAddressFromCoordinates(point);
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMove) {
      final center = event.camera.center;
      setState(() {
        _selectedPosition = center;
      });
      
      // Debounce address lookup - wait for map to stop moving
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (_selectedPosition != null) {
          _getAddressFromCoordinates(_selectedPosition!);
        }
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Confirm the selected location
  /// Returns both coordinates (for accuracy) and human-readable address
  /// The coordinates are the source of truth - the address is just for display
  void _confirmSelection() {
    if (_selectedPosition != null && _selectedAddress != null) {
      Navigator.pop(context, {
        'latitude': _selectedPosition!.latitude,  // Exact coordinates - source of truth
        'longitude': _selectedPosition!.longitude, // Exact coordinates - source of truth
        'address': _selectedAddress,               // Human-readable address for display
      });
    } else {
      _showError('Please select a location on the map');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location on Map'),
        actions: [
          TextButton(
            onPressed: _confirmSelection,
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap
          _selectedPosition == null && _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Getting your location...'),
                    ],
                  ),
                )
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPosition ?? const LatLng(7.1907, 125.4553), // Default: Davao (closer to user)
                    initialZoom: _selectedPosition != null ? 15.0 : 12.0,
                    onTap: _onMapTap,
                    onMapEvent: (MapEvent event) {
                      // Mark map as ready on first event
                      if (!_mapReady) {
                        setState(() {
                          _mapReady = true;
                        });
                        // If we have a position but map wasn't ready, move to it now
                        if (_selectedPosition != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _moveToLocation(_selectedPosition!, 15.0);
                          });
                        }
                      }
                      _onMapEvent(event);
                    },
                  ),
                  children: [
                    // OpenStreetMap tile layer
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.rentease_app',
                      maxZoom: 19,
                    ),
                    // Marker for selected location
                    if (_selectedPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPosition!,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

          // Address display card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Address:',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  _isLoadingAddress
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Loading address...'),
                          ],
                        )
                      : Text(
                          _selectedAddress ?? 'Tap on map to select location',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  if (_selectedPosition != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Coordinates: ${_selectedPosition!.latitude.toStringAsFixed(6)}, ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // My Location button
          Positioned(
            bottom: 120,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: () {
                _getCurrentLocation();
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }
}
