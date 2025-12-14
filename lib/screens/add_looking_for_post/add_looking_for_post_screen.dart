import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/models/looking_for_post_model.dart';
import 'package:rentease_app/backend/BLookingForPostService.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

// Light blue theme constants aligned with HomePage / Add Property
const Color _themeColor = Color(0xFF00D1FF);
const Color _themeColorLight2 = Color(0xFFB3F0FF);
const Color _themeColorDark = Color(0xFF00B8E6);

class AddLookingForPostScreen extends StatefulWidget {
  final LookingForPostModel? post; // For edit mode
  
  const AddLookingForPostScreen({super.key, this.post});

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
  bool _isSubmitting = false;
  bool _isEditMode = false;
  String? _postId;
  
  // Backend services
  final BLookingForPostService _lookingForPostService = BLookingForPostService();
  final BUserService _userService = BUserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  void initState() {
    super.initState();
    if (widget.post != null) {
      _isEditMode = true;
      _postId = widget.post!.id;
      _locationController.text = widget.post!.location;
      _descriptionController.text = widget.post!.description;
      _propertyType = widget.post!.propertyType;
      _moveInDate = widget.post!.moveInDate;
      
      // Parse budget range (format: ₱10,000-₱12,000)
      final budgetParts = widget.post!.budget.replaceAll('₱', '').split('-');
      if (budgetParts.length == 2) {
        _minBudgetController.text = budgetParts[0].replaceAll(',', '').trim();
        _maxBudgetController.text = budgetParts[1].replaceAll(',', '').trim();
      }
    }
  }

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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Please sign in to create a post'),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get user data for username
      final userData = await _userService.getUserData(user.uid);
      final username = userData?['username'] as String? ?? 
                      userData?['displayName'] as String? ??
                      (userData?['fname'] != null && userData?['lname'] != null
                          ? '${userData!['fname']} ${userData['lname']}'.trim()
                          : null) ??
                      user.displayName ?? 
                      user.email?.split('@')[0] ?? 
                      'User';

      final budget = '₱${_minBudgetController.text}-${_maxBudgetController.text}';

      if (_isEditMode && _postId != null) {
        // UPDATE EXISTING POST
        final updateData = <String, dynamic>{
          'description': _descriptionController.text.trim(),
          'location': _locationController.text.trim(),
          'budget': budget,
          'propertyType': _propertyType ?? 'Apartment',
          if (_moveInDate != null) 'moveInDate': Timestamp.fromDate(_moveInDate!),
        };

        await _lookingForPostService.updateLookingForPost(_postId!, updateData);

        // Fetch the updated post to return it
        final postData = await _lookingForPostService.getLookingForPost(_postId!);
        if (postData != null) {
          final updatedPost = LookingForPostModel.fromMap({
            'id': _postId!,
            ...postData,
          });

          if (!mounted) return;

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(
              context,
              'Post updated successfully!',
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate back with the updated post
          Navigator.of(context).pop<LookingForPostModel>(updatedPost);
        } else {
          throw Exception('Failed to retrieve updated post');
        }
      } else {
        // CREATE NEW POST
        final postId = await _lookingForPostService.createLookingForPost(
          userId: user.uid,
          username: username,
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          budget: budget,
          propertyType: _propertyType ?? 'Apartment',
          moveInDate: _moveInDate,
        );

        // Fetch the created post to return it
        final postData = await _lookingForPostService.getLookingForPost(postId);
        if (postData != null) {
          final newPost = LookingForPostModel.fromMap({
            'id': postId,
            ...postData,
          });

          if (!mounted) return;

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(
              context,
              'Post created successfully!',
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate back with the new post so Home can insert it at the top
          Navigator.of(context).pop<LookingForPostModel>(newPost);
        } else {
          throw Exception('Failed to retrieve created post');
        }
      }
    } catch (e) {
      debugPrint('❌ [AddLookingForPost] Error creating post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error creating post: ${e.toString()}',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
          _isEditMode ? 'Edit Post' : 'Looking For a Place',
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
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: FilledButton.styleFrom(
                      backgroundColor: _themeColorDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isEditMode ? 'Update Post' : 'Post Looking-For Request',
                            style: const TextStyle(
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

