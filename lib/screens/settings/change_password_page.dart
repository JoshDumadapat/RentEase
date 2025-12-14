import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

const Color _themeColorDark = Color(0xFF00B8E6);
const Color _themeColor = Color(0xFF00D1FF);

enum PasswordStrength {
  none,
  poor,
  moderate,
  strong,
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  
  // Password strength tracking
  PasswordStrength _passwordStrength = PasswordStrength.none;
  bool _passwordsMatch = false;
  bool _passwordsDoNotMatch = false;
  
  // Individual requirement states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Initialize progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );
    _progressController.value = 0.0;
    
    // Listen to password changes
    _newPasswordController.addListener(_checkPasswordStrength);
    _confirmPasswordController.addListener(_checkPasswordMatch);
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = _newPasswordController.text;
    
    // Check individual requirements
    final hasMinLength = password.length >= 12;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\\[\]~`]'));
    
    setState(() {
      _hasMinLength = hasMinLength;
      _hasUppercase = hasUppercase;
      _hasLowercase = hasLowercase;
      _hasNumber = hasNumber;
      _hasSpecialChar = hasSpecialChar;
      
      // Determine password strength
      if (password.isEmpty) {
        _passwordStrength = PasswordStrength.none;
      } else if (hasMinLength && hasUppercase && hasLowercase && hasNumber) {
        _passwordStrength = PasswordStrength.strong;
      } else if (password.length >= 8 && (hasUppercase || hasLowercase || hasNumber)) {
        _passwordStrength = PasswordStrength.moderate;
      } else {
        _passwordStrength = PasswordStrength.poor;
      }
      
      // Animate progress bar
      double targetProgress = 0.0;
      switch (_passwordStrength) {
        case PasswordStrength.poor:
          targetProgress = 0.33;
          break;
        case PasswordStrength.moderate:
          targetProgress = 0.66;
          break;
        case PasswordStrength.strong:
          targetProgress = 1.0;
          break;
        default:
          targetProgress = 0.0;
      }
      _progressController.animateTo(targetProgress);
    });
    
    // Also check match when password changes
    _checkPasswordMatch();
  }

  void _checkPasswordMatch() {
    setState(() {
      final confirmPassword = _confirmPasswordController.text;
      final password = _newPasswordController.text;
      
      if (confirmPassword.isEmpty) {
        _passwordsMatch = false;
        _passwordsDoNotMatch = false;
      } else if (password == confirmPassword) {
        _passwordsMatch = true;
        _passwordsDoNotMatch = false;
      } else {
        _passwordsMatch = false;
        _passwordsDoNotMatch = true;
      }
    });
  }

  // Helper method to check if user has password provider
  bool _hasPasswordProvider() {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    return user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }

  // Helper method to check if user is Google-only
  bool _isGoogleOnly() {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final providers = user.providerData.map((p) => p.providerId).toList();
    return providers.contains('google.com') && !providers.contains('password');
  }

  bool _isPasswordValid() {
    final password = _newPasswordController.text;
    final hasMinLength = password.length >= 12;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    
    return hasMinLength && hasUppercase && hasLowercase && hasNumber && _passwordsMatch;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isPasswordValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(
          context,
          'Please meet all password requirements',
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Verify old password by attempting to re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _oldPasswordController.text,
      );
      
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Password changed successfully'),
      );

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to change password';
      if (e.code == 'wrong-password') {
        message = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        message = 'New password is too weak';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please log out and log back in before changing password';
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, message),
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

  Widget _buildGoogleOnlyMessage(
    BuildContext context,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 80,
            color: _themeColorDark,
          ),
          const SizedBox(height: 24),
          Text(
            'Google Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'You signed in with Google, so you don\'t have a password to change.',
            style: TextStyle(
              fontSize: 16,
              color: subtextColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your account is secured through Google authentication. To manage your account security, please visit your Google account settings.',
            style: TextStyle(
              fontSize: 14,
              color: subtextColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final subtextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    final isGoogleOnly = _isGoogleOnly();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Change Password',
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
          child: isGoogleOnly
              ? _buildGoogleOnlyMessage(context, textColor, subtextColor, cardColor, isDark)
              : Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: _themeColorDark,
                ),
                const SizedBox(height: 16),
                Text(
                  'Update your password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your current password and choose a new one',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Current Password
                Text(
                  'Current Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: _obscureOldPassword,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Enter your current password',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureOldPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: textColor.withOpacity(0.6),
                      ),
                      onPressed: () {
                        setState(() => _obscureOldPassword = !_obscureOldPassword);
                      },
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // New Password
                Text(
                  'New Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Enter your new password',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: textColor.withOpacity(0.6),
                      ),
                      onPressed: () {
                        setState(() => _obscureNewPassword = !_obscureNewPassword);
                      },
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 12) {
                      return 'Password must be at least 12 characters';
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'Password must contain at least one uppercase letter';
                    }
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return 'Password must contain at least one lowercase letter';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Password must contain at least one number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Password strength indicator
                if (_newPasswordController.text.isNotEmpty) ...[
                  _PasswordStrengthIndicator(
                    strength: _passwordStrength,
                    progressAnimation: _progressAnimation,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _PasswordRequirements(
                    strength: _passwordStrength,
                    hasMinLength: _hasMinLength,
                    hasUppercase: _hasUppercase,
                    hasLowercase: _hasLowercase,
                    hasNumber: _hasNumber,
                    hasSpecialChar: _hasSpecialChar,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 24),

                // Confirm New Password
                Text(
                  'Confirm New Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Confirm your new password',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: textColor.withOpacity(0.6),
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Password match indicator
                if (_confirmPasswordController.text.isNotEmpty) ...[
                  if (_passwordsMatch)
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Passwords match',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else if (_passwordsDoNotMatch)
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Passwords do not match',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                ],
                const SizedBox(height: 32),

                // Change Password Button
                FilledButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: FilledButton.styleFrom(
                    backgroundColor: _themeColorDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

class _PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;
  final Animation<double> progressAnimation;
  final bool isDark;

  const _PasswordStrengthIndicator({
    required this.strength,
    required this.progressAnimation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (strength) {
      case PasswordStrength.poor:
        color = Colors.red;
        label = 'Poor';
        break;
      case PasswordStrength.moderate:
        color = Colors.orange;
        label = 'Moderate';
        break;
      case PasswordStrength.strong:
        color = Colors.green;
        label = 'Good';
        break;
      default:
        color = Colors.grey;
        label = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (strength != PasswordStrength.none)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        if (strength != PasswordStrength.none) const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedBuilder(
            animation: progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: progressAnimation.value,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  strength != PasswordStrength.none ? color : Colors.grey,
                ),
                minHeight: 6,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  final PasswordStrength strength;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialChar;
  final bool isDark;

  const _PasswordRequirements({
    required this.strength,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.grey[300] : Colors.grey[700];
    final successColor = Colors.green[600]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (strength == PasswordStrength.strong) ...[
          Text(
            'Great job! This password is good and secure.',
            style: TextStyle(
              fontSize: 12,
              color: successColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ] else if (strength == PasswordStrength.moderate) ...[
          Text(
            'Getting stronger! Add more requirements for better protection.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[600],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          'Password requirements:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        _RequirementItem(
          text: 'At least 12 characters',
          isChecked: hasMinLength,
          isDark: isDark,
        ),
        _RequirementItem(
          text: 'One uppercase letter',
          isChecked: hasUppercase,
          isDark: isDark,
        ),
        _RequirementItem(
          text: 'One lowercase letter',
          isChecked: hasLowercase,
          isDark: isDark,
        ),
        _RequirementItem(
          text: 'One number',
          isChecked: hasNumber,
          isDark: isDark,
        ),
        _RequirementItem(
          text: 'One special character (optional)',
          isChecked: hasSpecialChar,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String text;
  final bool isChecked;
  final bool isDark;

  const _RequirementItem({
    required this.text,
    this.isChecked = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final successColor = Colors.green[600]!;
    
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Row(
        children: [
          if (isChecked)
            Icon(Icons.check_circle, size: 16, color: successColor)
          else
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
            ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isChecked ? successColor : textColor,
              fontWeight: isChecked ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
