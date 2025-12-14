import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OSMLocationViewPage extends StatefulWidget {
  final String address;

  const OSMLocationViewPage({
    super.key,
    required this.address,
  });

  @override
  State<OSMLocationViewPage> createState() => _OSMLocationViewPageState();
}

class _OSMLocationViewPageState extends State<OSMLocationViewPage> {
  final MapController _mapController = MapController();
  LatLng? _location;
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  bool _isLoadingRoute = false;
  String? _errorMessage;
  bool _mapReady = false;
  double? _distance;
  double? _duration;

  @override
  void initState() {
    super.initState();
    _geocodeAddress();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });

      // Get route if we have both locations
      if (_location != null && _userLocation != null) {
        _getRoute();
      }
    } catch (e) {
      debugPrint('❌ [OSMLocationView] Error getting user location: $e');
    }
  }

  Future<void> _geocodeAddress() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Convert address to coordinates
      List<Location> locations = await locationFromAddress(widget.address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);
        
        setState(() {
          _location = latLng;
          _isLoading = false;
        });

        // Wait for map to be ready before moving to location
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mapReady && _location != null) {
            _moveToLocation(_location!, 15.0);
          }
        });

        // Get route if we have user location
        if (_userLocation != null) {
          _getRoute();
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not find location for this address.';
        });
      }
    } catch (e) {
      debugPrint('❌ [OSMLocationView] Error geocoding address: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not find location. The address may be invalid.';
      });
    }
  }

  void _moveToLocation(LatLng location, double zoom) {
    _mapController.move(location, zoom);
  }

  Future<void> _getRoute() async {
    if (_userLocation == null || _location == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // Use OSRM routing service (free, open-source routing)
      final startLng = _userLocation!.longitude;
      final startLat = _userLocation!.latitude;
      final endLng = _location!.longitude;
      final endLat = _location!.latitude;

      // OSRM route API
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson',
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'];
          
          // Convert coordinates to LatLng
          final routePoints = (geometry as List)
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();

          // Get distance and duration
          final distance = route['distance'] as double; // in meters
          final duration = route['duration'] as double; // in seconds

          setState(() {
            _routePoints = routePoints;
            _distance = distance;
            _duration = duration;
            _isLoadingRoute = false;
          });

          // Fit map to show both locations and route
          if (_routePoints.isNotEmpty && _mapReady) {
            _fitBounds();
          }
        } else {
          setState(() {
            _isLoadingRoute = false;
          });
        }
      } else {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [OSMLocationView] Error getting route: $e');
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  void _fitBounds() {
    if (_userLocation == null || _location == null) return;

    // Calculate bounds that include both locations
    final bounds = LatLngBounds(
      LatLng(
        _userLocation!.latitude < _location!.latitude 
            ? _userLocation!.latitude 
            : _location!.latitude,
        _userLocation!.longitude < _location!.longitude 
            ? _userLocation!.longitude 
            : _location!.longitude,
      ),
      LatLng(
        _userLocation!.latitude > _location!.latitude 
            ? _userLocation!.latitude 
            : _location!.latitude,
        _userLocation!.longitude > _location!.longitude 
            ? _userLocation!.longitude 
            : _location!.longitude,
      ),
    );

    // Move camera to fit bounds with padding
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
    }
  }

  String _formatDuration(double durationInSeconds) {
    if (durationInSeconds < 60) {
      return '${durationInSeconds.toStringAsFixed(0)} sec';
    } else if (durationInSeconds < 3600) {
      return '${(durationInSeconds / 60).toStringAsFixed(0)} min';
    } else {
      final hours = (durationInSeconds / 3600).floor();
      final minutes = ((durationInSeconds % 3600) / 60).floor();
      return '${hours}h ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Location'),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      ),
      body: Stack(
        children: [
          // Map
          _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('Finding location...'),
                    ],
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 64,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _geocodeAddress,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _location ?? const LatLng(14.5995, 120.9842), // Default: Manila
                        initialZoom: _location != null ? 15.0 : 12.0,
                        onMapEvent: (MapEvent event) {
                          // Mark map as ready on first event
                          if (!_mapReady && _location != null) {
                            setState(() {
                              _mapReady = true;
                            });
                            // Move to location once map is ready
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _moveToLocation(_location!, 15.0);
                            });
                          }
                        },
                      ),
                      children: [
                        // OpenStreetMap tile layer
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.rentease_app',
                          maxZoom: 19,
                        ),
                        // Route polyline
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 4.0,
                                color: const Color(0xFF00B8E6),
                              ),
                            ],
                          ),
                        // Marker for user location
                        if (_userLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _userLocation!,
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        // Marker for property location
                        if (_location != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _location!,
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

          // Route info and address card
          if (_location != null && !_isLoading && _errorMessage == null)
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
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route info (distance and duration)
                      if (_isLoadingRoute)
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Getting directions...'),
                          ],
                        )
                      else if (_distance != null && _duration != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B8E6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions,
                                color: const Color(0xFF00B8E6),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDistance(_distance!),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_duration!),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_userLocation == null)
                                IconButton(
                                  icon: const Icon(Icons.my_location),
                                  onPressed: _getUserLocation,
                                  tooltip: 'Get my location',
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Address
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: const Color(0xFF00B8E6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.address,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
