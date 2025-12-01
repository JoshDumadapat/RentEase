import 'package:flutter/material.dart';
import 'package:rentease_app/models/filter_model.dart';

// Theme color constants
const Color _themeColor = Color(0xFF00D1FF);
const Color _themeColorLight = Color(0xFFE5F9FF); // Light background (like blue[50])
const Color _themeColorDark = Color(0xFF00B8E6); // Darker shade for text (like blue[700])

class FilterSheet extends StatefulWidget {
  final FilterModel filterModel;

  const FilterSheet({
    super.key,
    required this.filterModel,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late FilterModel _filterModel;

  @override
  void initState() {
    super.initState();
    _filterModel = widget.filterModel;
    _filterModel.addListener(_onFilterChanged);
    // Initialize temporary values
    _filterModel.resetTemporaryFilters();
  }

  @override
  void dispose() {
    _filterModel.removeListener(_onFilterChanged);
    super.dispose();
  }

  void _onFilterChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceRangeSection(theme, colorScheme, textTheme),
                  const SizedBox(height: 32),
                  _buildBedroomsSection(theme, colorScheme, textTheme),
                  const SizedBox(height: 32),
                  _buildBathroomsSection(theme, colorScheme, textTheme),
                  const SizedBox(height: 32),
                  _buildPropertyTypeSection(theme, colorScheme, textTheme),
                  const SizedBox(height: 32),
                  _buildAmenitiesSection(theme, colorScheme, textTheme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    // Clear all filters and reset to default values
                    // Note: We do NOT close the sheet here - user can continue
                    // adjusting filters or click Apply/Cancel to close
                    _filterModel.clearFilters();
                  },
                  child: Text(
                    'Clear Filters',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    _filterModel.applyFilters();
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _themeColorDark,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeSection(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _themeColorDark,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: _themeColorDark,
            overlayColor: _themeColorDark.withValues(alpha: 0.2),
            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: RangeSlider(
            values: RangeValues(
              _filterModel.currentMinPrice,
              _filterModel.currentMaxPrice,
            ),
            min: 0,
            max: 50000,
            divisions: 50,
            labels: RangeLabels(
              '₱${_filterModel.currentMinPrice.toStringAsFixed(0)}',
              '₱${_filterModel.currentMaxPrice.toStringAsFixed(0)}',
            ),
            onChanged: (values) {
              _filterModel.setPriceRange(values.start, values.end);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₱${_filterModel.currentMinPrice.toStringAsFixed(0)}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '₱${_filterModel.currentMaxPrice.toStringAsFixed(0)}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBedroomsSection(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final bedrooms = ['Studio', '1', '2', '3', '4+'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bedrooms',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: bedrooms.map((bedroom) {
            final isSelected = _filterModel.selectedBedrooms == bedroom;
            return FilterChip(
              selected: isSelected,
              label: Text(bedroom),
              onSelected: (selected) {
                _filterModel.setBedrooms(selected ? bedroom : null);
              },
              selectedColor: _themeColorLight,
              checkmarkColor: _themeColorDark,
              labelStyle: TextStyle(
                color: isSelected
                    ? _themeColorDark
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBathroomsSection(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final bathrooms = ['1', '2', '3', '4+'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bathrooms',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: bathrooms.map((bathroom) {
            final isSelected = _filterModel.selectedBathrooms == bathroom;
            return FilterChip(
              selected: isSelected,
              label: Text(bathroom),
              onSelected: (selected) {
                _filterModel.setBathrooms(selected ? bathroom : null);
              },
              selectedColor: _themeColorLight,
              checkmarkColor: _themeColorDark,
              labelStyle: TextStyle(
                color: isSelected
                    ? _themeColorDark
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPropertyTypeSection(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final propertyTypes = ['Apartment', 'House', 'Condo', 'Room', 'Villa'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Type',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: propertyTypes.map((type) {
            final isSelected = _filterModel.selectedPropertyType == type;
            return FilterChip(
              selected: isSelected,
              label: Text(type),
              onSelected: (selected) {
                _filterModel.setPropertyType(selected ? type : null);
              },
              selectedColor: _themeColorLight,
              checkmarkColor: _themeColorDark,
              labelStyle: TextStyle(
                color: isSelected
                    ? _themeColorDark
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final amenities = [
      'Pets allowed',
      'Parking',
      'Furnished',
      'Air conditioning',
      'Balcony',
      'Laundry',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: amenities.map((amenity) {
            final isSelected = _filterModel.selectedAmenities.contains(amenity);
            return FilterChip(
              selected: isSelected,
              label: Text(amenity),
              onSelected: (selected) {
                _filterModel.toggleAmenity(amenity);
              },
              selectedColor: _themeColorLight,
              checkmarkColor: _themeColorDark,
              labelStyle: TextStyle(
                color: isSelected
                    ? _themeColorDark
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

