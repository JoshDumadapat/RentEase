import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/services/cloudinary_service.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/dialogs/image_source_dialog.dart';
import 'package:rentease_app/screens/settings/change_email_page.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

const Color _themeColorDark = Color(0xFF00B8E6);
const Color _themeColor = Color(0xFF00D1FF);

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final BUserService _userService = BUserService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize with fallback values first
    _fallbackInitializeFields();
    // Then fetch actual fname and lname from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNameFromFirestore();
    });
  }

  Future<void> _loadNameFromFirestore() async {
    // Fetch fname, lname, and phone directly from Firestore to avoid splitting issues
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userData = await _userService.getUserData(user.uid);
        if (userData != null) {
          // Use fname and lname directly from Firestore
          final fname = userData['fname'] as String? ?? '';
          final lname = userData['lname'] as String? ?? '';
          final phone = userData['phone'] as String? ?? '';
          
          if (mounted) {
            setState(() {
              _firstNameController.text = fname;
              _lastNameController.text = lname;
              if (phone.isNotEmpty) {
                _phoneController.text = _formatPhoneNumber(phone);
              } else {
                _phoneController.text = '';
              }
            });
          }
          
          debugPrint('🔍 [EditProfile] Loaded from Firestore - fname: "$fname", lname: "$lname", phone: "$phone"');
        }
      } catch (e) {
        debugPrint('❌ [EditProfile] Error fetching user data: $e');
      }
    }
  }

  void _fallbackInitializeFields() {
    // Initialize with username, bio, phone, and image first
    _usernameController.text = widget.user.username ?? '';
    _bioController.text = widget.user.bio ?? '';
    // Format phone number for display
    if (widget.user.phone != null && widget.user.phone!.isNotEmpty) {
      _phoneController.text = _formatPhoneNumber(widget.user.phone!);
    }
    _uploadedImageUrl = widget.user.profileImageUrl;
    
    // Fallback: Split displayName into first and last name (will be replaced by Firestore data)
    final nameParts = widget.user.displayName.split(' ');
    if (nameParts.length >= 2) {
      _firstNameController.text = nameParts.first;
      _lastNameController.text = nameParts.sublist(1).join(' ');
    } else if (nameParts.length == 1) {
      _firstNameController.text = nameParts.first;
    }
  }

  // Format phone number for display: 0912 345 6789
  String _formatPhoneNumber(String value) {
    // Remove all non-digit characters
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limit to 11 digits
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }
    
    // Format: 09XX XXX XXXX
    if (digitsOnly.length >= 4) {
      final part1 = digitsOnly.substring(0, 4); // 0912
      final part2 = digitsOnly.length > 4 ? digitsOnly.substring(4, 7) : ''; // 345
      final part3 = digitsOnly.length > 7 ? digitsOnly.substring(7) : ''; // 6789
      
      if (part3.isNotEmpty) {
        return '$part1 $part2 $part3';
      } else if (part2.isNotEmpty) {
        return '$part1 $part2';
      } else {
        return part1;
      }
    }
    
    return digitsOnly;
  }

  // Format phone number as user types
  void _onPhoneChanged(String value) {
    // Remove all non-digit characters
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limit to 11 digits
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }
    
    // Auto-format: If user types starting with 9 (without 0), prepend 0
    if (digitsOnly.isNotEmpty && digitsOnly.startsWith('9') && !digitsOnly.startsWith('09')) {
      if (digitsOnly.length <= 10) {
        digitsOnly = '0$digitsOnly';
      }
    }
    
    // Format with spacing
    final formatted = _formatPhoneNumber(digitsOnly);
    
    // Update controller value only if it changed
    if (_phoneController.text != formatted) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: formatted.length,
        ),
      );
    }
  }

  // Validate phone number format (Philippines: 09XXXXXXXXX - 11 digits)
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional in edit profile
    }
    
    // Remove all non-digit characters
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // If empty after removing formatting, it's valid (optional field)
    if (digitsOnly.isEmpty) {
      return null;
    }
    
    // Must be exactly 11 digits
    if (digitsOnly.length != 11) {
      return 'Phone number must be 11 digits (09XX XXX XXXX)';
    }
    
    // Must start with 09
    if (!digitsOnly.startsWith('09')) {
      return 'Phone number must start with 09';
    }
    
    return null;
  }

  @override
  void dispose() {
    // Note: _firstNameController and _lastNameController are kept for display purposes
    // but they are not editable in the UI
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showImageSourceDialog(context);
    if (source == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        
        // Upload image immediately
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error picking image: $e'),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final XFile imageFile = XFile(_selectedImage!.path);
      final imageUrl = await _cloudinaryService.uploadImage(
        file: imageFile,
        uploadType: 'profile',
      );

      if (imageUrl != null && mounted) {
        setState(() {
          _uploadedImageUrl = imageUrl;
          _isUploadingImage = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Profile image uploaded successfully'),
        );
      } else {
        if (mounted) {
          setState(() => _isUploadingImage = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(context, 'Failed to upload image'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error uploading image: $e'),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Get existing user data to preserve fname and lname (they are not editable)
      final existingUserData = await _userService.getUserData(user.uid);
      
      // Preserve existing fname and lname - they are NOT editable since they were validated with ID
      String? fnameToSave;
      String? lnameToSave;
      if (existingUserData != null) {
        fnameToSave = existingUserData['fname'] as String?;
        lnameToSave = existingUserData['lname'] as String?;
      }
      
      final username = _usernameController.text.trim();
      final bio = _bioController.text.trim();
      // Get phone digits only (remove any formatting/spacing)
      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '').trim();
      
      // Prepare additional data - only include fields that have values or preserve existing
      final additionalData = <String, dynamic>{};
      if (username.isNotEmpty) {
        additionalData['username'] = username;
      } else if (existingUserData != null && existingUserData['username'] != null) {
        // Preserve existing username if new one is empty
        additionalData['username'] = existingUserData['username'];
      }
      
      if (bio.isNotEmpty) {
        additionalData['bio'] = bio;
      } else if (existingUserData != null && existingUserData['bio'] != null) {
        // Preserve existing bio if new one is empty
        additionalData['bio'] = existingUserData['bio'];
      }

      // Update user data in Firestore - DO NOT update fname/lname (they are validated with ID)
      await _userService.createOrUpdateUser(
        uid: user.uid,
        email: widget.user.email,
        fname: fnameToSave, // Preserve existing - not editable
        lname: lnameToSave, // Preserve existing - not editable
        phone: phoneDigits.isNotEmpty ? phoneDigits : null, // Save phone or null if empty
        profileImageUrl: _uploadedImageUrl ?? widget.user.profileImageUrl,
        additionalData: additionalData.isNotEmpty ? additionalData : null,
      );

      debugPrint('✅ [EditProfile] Successfully saved to Firestore:');
      debugPrint('   - Username: ${username.isNotEmpty ? username : "(preserved existing)"}');
      debugPrint('   - Bio: ${bio.isNotEmpty ? bio : "(preserved existing)"}');
      debugPrint('   - Phone: ${phoneDigits.isNotEmpty ? phoneDigits : "(removed)"}');
      debugPrint('   - Profile Image: ${_uploadedImageUrl ?? widget.user.profileImageUrl ?? "none"}');
      
      debugPrint('🔍 [EditProfile] Saved to Firestore - username: "$username" (fname/lname preserved as read-only)');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Profile updated successfully'),
      );

      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Error updating profile: $e'),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = (isDark ? Colors.grey[900]! : Colors.white);
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: _themeColorDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Image Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _themeColorDark,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _themeColorDark.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 140,
                            height: 140,
                            child: _isUploadingImage
                                ? Container(
                                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : _selectedImage != null
                                    ? Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                        width: 140,
                                        height: 140,
                                      )
                                    : _uploadedImageUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: _uploadedImageUrl!,
                                            fit: BoxFit.cover,
                                            width: 140,
                                            height: 140,
                                            memCacheWidth: 280,
                                            memCacheHeight: 280,
                                            placeholder: (context, url) => _buildDefaultAvatar(textColor, isDark),
                                            errorWidget: (context, url, error) => _buildDefaultAvatar(textColor, isDark),
                                          )
                                        : _buildDefaultAvatar(textColor, isDark),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _themeColorDark,
                            border: Border.all(
                              color: backgroundColor,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: _isUploadingImage ? null : _pickImage,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _isUploadingImage ? null : _pickImage,
                    icon: Icon(Icons.edit, size: 16, color: _themeColorDark),
                    label: Text(
                      'Change Photo',
                      style: TextStyle(color: _themeColorDark),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Username (Editable - auto-generated from name during sign up)
                Text(
                  'Username',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: textColor),
                  inputFormatters: [
                    // Remove @ symbol if user types it (we add it in display)
                    FilteringTextInputFormatter.deny(RegExp(r'@')),
                    // Allow only alphanumeric and underscore for username
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'username (without @)',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.alternate_email, color: textColor.withOpacity(0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _themeColorDark, width: 2),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                        return 'Username can only contain letters, numbers, and underscore';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Bio
                Text(
                  'Bio',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Tell us about yourself...',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.edit_note, color: textColor.withOpacity(0.6)),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _themeColorDark, width: 2),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 20),

                // Phone
                Text(
                  'Phone Number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: textColor),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13), // Allow for formatted length (09XX XXX XXXX)
                  ],
                  onChanged: _onPhoneChanged,
                  decoration: InputDecoration(
                    hintText: '0912 345 6789',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.phone_outlined, color: textColor.withOpacity(0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _themeColorDark, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                  ),
                  validator: _validatePhoneNumber,
                ),
                const SizedBox(height: 4),
                Text(
                  'Format: 09XX XXX XXXX (11 digits, optional)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),

                // Email (Read-only)
                Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, color: textColor.withOpacity(0.6)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.user.email,
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to change email page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChangeEmailPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Change',
                          style: TextStyle(color: _themeColorDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(Color textColor, bool isDark) {
    return Container(
      color: isDark ? Colors.grey[800] : Colors.grey[200],
      child: Icon(
        Icons.person,
        size: 60,
        color: textColor.withOpacity(0.5),
      ),
    );
  }
}
