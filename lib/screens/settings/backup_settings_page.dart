import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

const Color _themeColorDark = Color(0xFF00B8E6);
const Color _themeColor = Color(0xFF00D1FF);

class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  final _backupEmailController = TextEditingController();
  final _backupPhoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  bool _isLoading = false;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _backupEmail;
  String? _backupPhone;

  // Check if email has changed from saved value
  bool get _hasEmailChanged {
    final currentValue = _backupEmailController.text.trim();
    if (_backupEmail == null) {
      return currentValue.isNotEmpty;
    }
    return currentValue != _backupEmail;
  }

  // Check if phone has changed from saved value
  bool get _hasPhoneChanged {
    final currentValue = _backupPhoneController.text.trim();
    if (_backupPhone == null) {
      return currentValue.isNotEmpty;
    }
    return currentValue != _backupPhone;
  }

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
    // Add listeners to detect changes
    _backupEmailController.addListener(_onEmailChanged);
    _backupPhoneController.addListener(_onPhoneChanged);
  }

  void _onEmailChanged() {
    setState(() {}); // Trigger rebuild to update button state
  }

  void _onPhoneChanged() {
    setState(() {}); // Trigger rebuild to update button state
  }

  @override
  void dispose() {
    _backupEmailController.dispose();
    _backupPhoneController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBackupInfo() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _backupEmail = doc.data()?['backupEmail'] as String?;
          _backupPhone = doc.data()?['backupPhone'] as String?;
          _backupEmailController.text = _backupEmail ?? '';
          // Format phone number for display
          if (_backupPhone != null && _backupPhone!.isNotEmpty) {
            _backupPhoneController.text = _formatPhoneNumberDisplay(_backupPhone!);
          } else {
            _backupPhoneController.text = '';
          }
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  // Format phone number for display: 0912 345 6789
  String _formatPhoneNumberDisplay(String digitsOnly) {
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

  // Format phone number to Philippine format (09XXXXXXXXX - 11 digits) with spacing
  void _formatPhoneNumber(String value) {
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
    
    // Format with spacing: 0912 345 6789
    final formatted = _formatPhoneNumberDisplay(digitsOnly);
    
    // Update controller value only if it changed
    if (_backupPhoneController.text != formatted) {
      final cursorPosition = _backupPhoneController.selection.baseOffset;
      _backupPhoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: formatted.length,
        ),
      );
    }
  }

  // Validate email format
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a backup email';
    }
    
    // Email regex pattern
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Validate phone number format (Philippines: 09XXXXXXXXX - 11 digits)
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a backup phone number';
    }
    
    // Remove all non-digit characters
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
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

  Future<void> _saveBackupEmail() async {
    final emailError = _validateEmail(_backupEmailController.text.trim());
    if (emailError != null) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, emailError),
      );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'backupEmail': _backupEmailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _backupEmail = _backupEmailController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(
          context, 
          'Backup email saved successfully',
          duration: const Duration(seconds: 3),
        ),
      );
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

  Future<void> _saveBackupPhone() async {
    final phoneError = _validatePhoneNumber(_backupPhoneController.text.trim());
    if (phoneError != null) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, phoneError),
      );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get digits only (remove formatting) before saving
      final phoneDigits = _backupPhoneController.text.replaceAll(RegExp(r'[^\d]'), '');

      await _firestore.collection('users').doc(user.uid).update({
        'backupPhone': phoneDigits,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _backupPhone = _backupPhoneController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(
          context, 
          'Backup phone number saved successfully',
          duration: const Duration(seconds: 3),
        ),
      );
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Backup Settings',
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
              // Header
              Icon(
                Icons.backup_outlined,
                size: 64,
                color: _themeColorDark,
              ),
              const SizedBox(height: 16),
              Text(
                'Add Backup Contact Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add backup email and phone for account recovery and verification',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Backup Email Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.alternate_email, color: _themeColorDark, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Backup Email',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _backupEmailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Enter backup email address',
                        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.email_outlined, color: textColor.withOpacity(0.6)),
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
                        fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: (_isLoading || !_hasEmailChanged) ? null : () {
                        // Unfocus the email field and close keyboard immediately
                        _emailFocusNode.unfocus();
                        FocusScope.of(context).unfocus();
                        
                        if (_formKey.currentState!.validate()) {
                          _saveBackupEmail();
                        }
                      },
                      icon: Icon(
                        Icons.save_outlined,
                        color: (_isLoading || !_hasEmailChanged) 
                            ? Colors.grey[400] 
                            : Colors.white,
                      ),
                      label: Text(
                        'Save Backup Email',
                        style: TextStyle(
                          color: (_isLoading || !_hasEmailChanged) 
                              ? Colors.grey[400] 
                              : Colors.white,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _hasEmailChanged ? _themeColorDark : Colors.grey[400],
                        disabledBackgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Backup Phone Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, color: _themeColorDark, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Backup Phone Number',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _backupPhoneController,
                      focusNode: _phoneFocusNode,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: textColor),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(13), // Allow for formatted length (09XX XXX XXXX)
                      ],
                      onChanged: _formatPhoneNumber,
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
                        fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
                      ),
                      validator: _validatePhoneNumber,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: (_isLoading || !_hasPhoneChanged) ? null : () {
                        // Unfocus the phone field and close keyboard immediately
                        _phoneFocusNode.unfocus();
                        FocusScope.of(context).unfocus();
                        
                        if (_formKey.currentState!.validate()) {
                          _saveBackupPhone();
                        }
                      },
                      icon: Icon(
                        Icons.save_outlined,
                        color: (_isLoading || !_hasPhoneChanged) 
                            ? Colors.grey[400] 
                            : Colors.white,
                      ),
                      label: Text(
                        'Save Backup Phone',
                        style: TextStyle(
                          color: (_isLoading || !_hasPhoneChanged) 
                              ? Colors.grey[400] 
                              : Colors.white,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _hasPhoneChanged ? _themeColorDark : Colors.grey[400],
                        disabledBackgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _themeColor.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: _themeColorDark, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Backup contact information helps you recover your account if you lose access. You can use these for account verification.',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                        ),
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
}
