import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

const Color _themeColorDark = Color(0xFF00B8E6);
const Color _themeColor = Color(0xFF00D1FF);

class ChangePhonePage extends StatefulWidget {
  const ChangePhonePage({super.key});

  @override
  State<ChangePhonePage> createState() => _ChangePhonePageState();
}

class _ChangePhonePageState extends State<ChangePhonePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  bool _isLoading = false;
  String? _currentPhone;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BUserService _userService = BUserService();

  @override
  void initState() {
    super.initState();
    _loadCurrentPhone();
    // Add listener to update button state when phone changes
    _phoneController.addListener(() {
      if (mounted) {
        setState(() {}); // Trigger rebuild to update button state
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPhone() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userData = await _userService.getUserData(user.uid);
      if (userData != null && mounted) {
        setState(() {
          final phone = userData['phone'] as String?;
          _currentPhone = phone;
          if (phone != null && phone.isNotEmpty) {
            _phoneController.text = _formatPhoneNumber(phone);
          }
        });
      }
    } catch (e) {
      // Handle error silently
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
      final cursorPosition = _phoneController.selection.baseOffset;
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: formatted.length,
        ),
      );
    }
    
    // Trigger rebuild to update button state
    setState(() {});
  }

  // Validate phone number format (Philippines: 09XXXXXXXXX - 11 digits)
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a phone number';
    }
    
    // Remove all non-digit characters
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Must be exactly 11 digits
    if (digitsOnly.length != 11) {
      return 'Phone number must be 11 digits (09XXXXXXXXX)';
    }
    
    // Must start with 09
    if (!digitsOnly.startsWith('09')) {
      return 'Phone number must start with 09';
    }
    
    return null;
  }

  // Check if phone has changed from saved value
  bool get _hasPhoneChanged {
    final currentValue = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '').trim();
    if (_currentPhone == null || _currentPhone!.isEmpty) {
      // No saved phone - button enabled if valid 11-digit number
      return currentValue.isNotEmpty && currentValue.length == 11 && currentValue.startsWith('09');
    }
    final savedDigits = _currentPhone!.replaceAll(RegExp(r'[^\d]'), '').trim();
    // Button enabled if current value is different from saved and is valid
    final isDifferent = currentValue != savedDigits;
    final isValid = currentValue.length == 11 && currentValue.startsWith('09');
    return isDifferent && isValid;
  }

  Future<void> _changePhone() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Unfocus and close keyboard
    _phoneFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Get digits only (remove formatting)
      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');

      // Update phone in Firestore using BUserService
      await _userService.createOrUpdateUser(
        uid: user.uid,
        email: user.email ?? '',
        phone: phoneDigits,
      );

      setState(() => _currentPhone = phoneDigits);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(
          context,
          'Phone number updated successfully',
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Error: ${e.toString()}'),
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
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Change Phone Number',
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _themeColorDark.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.phone_outlined,
                          size: 48,
                          color: _themeColorDark,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Update your phone number',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your new Philippine phone number',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Current Phone (if exists)
                if (_currentPhone != null && _currentPhone!.isNotEmpty) ...[
                  Text(
                    'Current Phone Number',
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
                      border: Border.all(color: borderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 20,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatPhoneNumber(_currentPhone!),
                          style: TextStyle(
                            color: textColor.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // New Phone
                Text(
                  'New Phone Number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Format: 09XX XXX XXXX (11 digits total)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Change Phone Button
                FilledButton(
                  onPressed: (_isLoading || !_hasPhoneChanged) ? null : _changePhone,
                  style: FilledButton.styleFrom(
                    backgroundColor: _hasPhoneChanged && !_isLoading 
                        ? _themeColorDark 
                        : Colors.grey[400],
                    disabledBackgroundColor: Colors.grey[400],
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: _hasPhoneChanged && !_isLoading ? 2 : 0,
                    shadowColor: _hasPhoneChanged && !_isLoading 
                        ? _themeColorDark.withOpacity(0.3) 
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: (_isLoading || !_hasPhoneChanged) 
                                  ? Colors.white.withOpacity(0.6) 
                                  : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Change Phone Number',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
