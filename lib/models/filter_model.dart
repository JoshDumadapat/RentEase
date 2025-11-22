import 'package:flutter/foundation.dart';

class FilterModel extends ChangeNotifier {
  // Price Range
  double _minPrice = 0;
  double _maxPrice = 50000;
  double _currentMinPrice = 0;
  double _currentMaxPrice = 50000;

  // Bedrooms
  String? _selectedBedrooms;

  // Bathrooms
  String? _selectedBathrooms;

  // Property Type
  String? _selectedPropertyType;

  // Amenities (multi-select)
  final Set<String> _selectedAmenities = {};

  // Getters
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  double get currentMinPrice => _currentMinPrice;
  double get currentMaxPrice => _currentMaxPrice;
  String? get selectedBedrooms => _selectedBedrooms;
  String? get selectedBathrooms => _selectedBathrooms;
  String? get selectedPropertyType => _selectedPropertyType;
  Set<String> get selectedAmenities => Set.unmodifiable(_selectedAmenities);

  bool get hasActiveFilters =>
      _selectedBedrooms != null ||
      _selectedBathrooms != null ||
      _selectedPropertyType != null ||
      _selectedAmenities.isNotEmpty ||
      _currentMinPrice != _minPrice ||
      _currentMaxPrice != _maxPrice;

  // Setters
  void setPriceRange(double min, double max) {
    _currentMinPrice = min;
    _currentMaxPrice = max;
    notifyListeners();
  }

  void setBedrooms(String? bedrooms) {
    _selectedBedrooms = bedrooms;
    notifyListeners();
  }

  void setBathrooms(String? bathrooms) {
    _selectedBathrooms = bathrooms;
    notifyListeners();
  }

  void setPropertyType(String? type) {
    _selectedPropertyType = type;
    notifyListeners();
  }

  void toggleAmenity(String amenity) {
    if (_selectedAmenities.contains(amenity)) {
      _selectedAmenities.remove(amenity);
    } else {
      _selectedAmenities.add(amenity);
    }
    notifyListeners();
  }

  void applyFilters() {
    _minPrice = _currentMinPrice;
    _maxPrice = _currentMaxPrice;
    notifyListeners();
  }

  void clearFilters() {
    _currentMinPrice = _minPrice = 0;
    _currentMaxPrice = _maxPrice = 50000;
    _selectedBedrooms = null;
    _selectedBathrooms = null;
    _selectedPropertyType = null;
    _selectedAmenities.clear();
    notifyListeners();
  }

  void resetTemporaryFilters() {
    _currentMinPrice = _minPrice;
    _currentMaxPrice = _maxPrice;
    notifyListeners();
  }
}

