import 'package:flutter/material.dart';
import 'package:rentease_app/models/looking_for_post_model.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

// Light blue theme constants aligned with HomePage / Add Property
const Color _themeColor = Color(0xFF00D1FF);
const Color _themeColorLight2 = Color(0xFFB3F0FF);
const Color _themeColorDark = Color(0xFF00B8E6);

class AddLookingForPostScreen extends StatefulWidget {
  const AddLookingForPostScreen({super.key});

  @override
  State<AddLookingForPostScreen> createState() => _AddLookingForPostScreenState();
}

class _AddLookingForPostScreenState extends State<AddLookingForPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();

  // State variables
  String? _propertyType;
  DateTime? _moveInDate;

  // Property types
  final List<String> _propertyTypes = [
    'Apartment',
    'House Rentals',
    'Condo Rentals',
    'Rooms',
    'Boarding House',
    'Student Dorms',
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectMoveInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _moveInDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _moveInDate = picked;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }


    final now = DateTime.now();
    final budget =
        '₱${_minBudgetController.text}-${_maxBudgetController.text}';

    final newPost = LookingForPostModel(
      id: now.millisecondsSinceEpoch.toString(),
      username: 'You',
      description: _descriptionController.text,
      location: _locationController.text,
      budget: budget,
      date: '${now.month}/${now.day}',
      propertyType: _propertyType ?? 'Apartment',
      moveInDate: _moveInDate,
      postedDate: now,
      isVerified: true,
      likeCount: 0,
      commentCount: 0,
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBarUtils.buildThemedSnackBar(context, 'Post created! Showing on your feed.'),
    );

    // Navigate back with the new post so Home can insert it at the top
    Navigator.of(context).pop<LookingForPostModel>(newPost);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    final iconColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Looking For a Place',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: _themeColorDark,
            secondary: _themeColor,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : _themeColorLight2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : _themeColorLight2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _themeColorDark, width: 1.5),
            ),
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Intro text
                      Text(
                        'Tell us what you\'re looking for',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Share a few details so we can surface the best matching listings for you.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: subtextColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Card: Location & Type
                      _buildFormCard(
                        title: 'Location & Type',
                        subtitle:
                            'Where are you planning to stay and what kind of place do you prefer?',
                        children: [
                          _buildSectionTitle('Preferred Location'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _locationController,
                            style: TextStyle(color: textColor),
                            decoration: const InputDecoration(
                              hintText: 'e.g., Cebu City, IT Park',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a preferred location';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildSectionTitle('Property Type'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _propertyType,
                            decoration: const InputDecoration(
                              hintText: 'Select property type',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items: _propertyTypes.map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type, style: TextStyle(color: textColor)),
                              );
                            }).toList(),
                            style: TextStyle(color: textColor),
                            onChanged: (String? value) {
                              setState(() {
                                _propertyType = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a property type';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      // Card: Budget & timing
                      _buildFormCard(
                        title: 'Budget & Timing',
                        subtitle:
                            'Set a comfortable budget range and when you\'d like to move in.',
                        children: [
                          _buildSectionTitle('Budget Range'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _minBudgetController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: textColor),
                                  decoration: const InputDecoration(
                                    hintText: 'Min',
                                    prefixText: '₱',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'to',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: subtextColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _maxBudgetController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: textColor),
                                  decoration: const InputDecoration(
                                    hintText: 'Max',
                                    prefixText: '₱',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Invalid';
                                    }
                                    final min =
                                        int.tryParse(_minBudgetController.text);
                                    final max = int.tryParse(value);
                                    if (min != null &&
                                        max != null &&
                                        max < min) {
                                      return 'Max < Min';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildSectionTitle('Move-in Date (Optional)'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectMoveInDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.grey[700]! : _themeColorLight2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _moveInDate != null
                                        ? '${_moveInDate!.day}/${_moveInDate!.month}/${_moveInDate!.year}'
                                        : 'Select move-in date',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _moveInDate != null
                                          ? textColor
                                          : (isDark ? Colors.grey[400] : Colors.grey[500]),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_moveInDate != null)
                                    IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        size: 20,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _moveInDate = null;
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Card: Description
                      _buildFormCard(
                        title: 'More Details',
                        subtitle:
                            'Any preferences about roommates, amenities, or surroundings?',
                        children: [
                          _buildSectionTitle('Description'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 5,
                            style: TextStyle(color: textColor),
                            decoration: const InputDecoration(
                              hintText:
                                  'Describe what you\'re looking for in a comfortable, friendly way...',
                              contentPadding: EdgeInsets.all(16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              // Submit Button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitForm,
                    style: FilledButton.styleFrom(
                      backgroundColor: _themeColorDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Post Looking-For Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: subtextColor,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}

