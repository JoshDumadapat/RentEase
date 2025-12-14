import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentease_app/main_app.dart';
import 'package:rentease_app/services/auth_service.dart';
import 'package:rentease_app/services/user_service.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

/// Password Creation Page
/// 
/// Allows user to set a new password after verification
/// with password strength indicator and requirements
class PasswordCreationPage extends StatefulWidget {
  final String email;
  final String firstName;
  final String lastName;
  final String? birthday;
  final String phone;
  final String countryCode;
  final String idNumber;
  final XFile frontIdImage;
  final XFile selfieImage;
  final GoogleSignInTempData? googleData;
  final User? firebaseUser; // For Google accounts (already created)
  final String? userType;

  const PasswordCreationPage({
    super.key,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.countryCode,
    required this.idNumber,
    required this.frontIdImage,
    required this.selfieImage,
    this.birthday,
    this.googleData,
    this.firebaseUser,
    this.userType,
  });

  @override
  State<PasswordCreationPage> createState() => _PasswordCreationPageState();
}

class _PasswordCreationPageState extends State<PasswordCreationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  PasswordStrength _passwordStrength = PasswordStrength.none;
  bool _passwordsMatch = false;
  bool _passwordsDoNotMatch = false;
  bool _isProcessing = false;
  String? _errorMessage;
  
  // Individual requirement states (persist once checked)
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize progress animation first
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );
    _progressController.value = 0.0;
    
    _passwordController.addListener(() {
      _checkPasswordStrength();
      _checkPasswordMatch(); // Also check match when password changes
      // Clear error message when user types
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
    _confirmPasswordController.addListener(() {
      _checkPasswordMatch();
      // Clear error message when user types
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    
    // Check individual requirements based on current password state
    final hasMinLength = password.length >= 12;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\\[\]~`]'));
    
    setState(() {
      // Update requirement states based on current password state
      _hasMinLength = hasMinLength;
      _hasUppercase = hasUppercase;
      _hasLowercase = hasLowercase;
      _hasNumber = hasNumber;
      _hasSpecialChar = hasSpecialChar;
      
      // Determine password strength based on CURRENT password state
      // Strong requires: minLength, uppercase, lowercase, number (special char is optional)
      if (password.isEmpty) {
        _passwordStrength = PasswordStrength.none;
      } else if (hasMinLength && hasUppercase && hasLowercase && hasNumber) {
        // Core requirements met (special char optional) = Strong (Good)
        _passwordStrength = PasswordStrength.strong;
        // Clear error messages related to password requirements (but not match errors)
        if (_errorMessage != null && _errorMessage != 'Passwords do not match') {
          _errorMessage = null;
        }
      } else if (password.length >= 8 && (hasUppercase || hasLowercase || hasNumber)) {
        // Some requirements met = Moderate
        _passwordStrength = PasswordStrength.moderate;
      } else {
        // Few or no requirements met = Poor
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
  }

  void _checkPasswordMatch() {
    setState(() {
      final confirmPassword = _confirmPasswordController.text;
      final password = _passwordController.text;
      
      if (confirmPassword.isEmpty) {
        _passwordsMatch = false;
        _passwordsDoNotMatch = false;
      } else if (password == confirmPassword) {
        _passwordsMatch = true;
        _passwordsDoNotMatch = false;
        // Clear error message when passwords match (if it's a password match error)
        if (_errorMessage != null && _errorMessage == 'Passwords do not match') {
          _errorMessage = null;
        }
      } else {
        _passwordsMatch = false;
        _passwordsDoNotMatch = true;
      }
    });
  }

  bool _isPasswordValid() {
    final password = _passwordController.text;
    final hasMinLength = password.length >= 12;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    
    return hasMinLength && hasUppercase && hasLowercase && hasNumber && _passwordsMatch;
  }

  Future<void> _handleSetPassword() async {
    if (!_isPasswordValid()) {
      // Set error message when requirements aren't met
      setState(() {
        final password = _passwordController.text;
        final hasMinLength = password.length >= 12;
        final hasUppercase = password.contains(RegExp(r'[A-Z]'));
        final hasLowercase = password.contains(RegExp(r'[a-z]'));
        final hasNumber = password.contains(RegExp(r'[0-9]'));
        
        if (!_passwordsMatch) {
          _errorMessage = 'Passwords do not match';
        } else if (!hasMinLength) {
          _errorMessage = 'Password must be at least 12 characters long';
        } else if (!hasUppercase) {
          _errorMessage = 'Password must contain at least one uppercase letter';
        } else if (!hasLowercase) {
          _errorMessage = 'Password must contain at least one lowercase letter';
        } else if (!hasNumber) {
          _errorMessage = 'Password must contain at least one number';
        } else {
          _errorMessage = 'Please meet all password requirements';
        }
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });
      
      try {
        User? user = widget.firebaseUser; // For Google accounts
        
        // For email/password accounts: Create Firebase Auth account now
        if (widget.googleData == null) {
          try {
            final password = _passwordController.text;
            final userCredential = await _authService.signUpWithEmailAndPassword(
              widget.email,
              password,
            );
            user = userCredential.user;
            
            if (user == null) {
              throw Exception('Failed to create account');
            }
          } catch (e) {
            if (!mounted) return;
            setState(() {
              _isProcessing = false;
              _errorMessage = 'Failed to create account: ${e.toString().replaceAll('Exception: ', '')}';
            });
            return;
          }
        } else {
          // For Google accounts, user should already exist from VerificationLoadingPage
          user = widget.firebaseUser;
          if (user == null) {
            throw Exception('Firebase user not found for Google account');
          }
        }
        
        // Get photo URL from Google data
        String? photoUrl;
        if (widget.googleData != null && widget.googleData!.photoUrl != null) {
          photoUrl = widget.googleData!.photoUrl;
        } else if (user.photoURL != null) {
          photoUrl = user.photoURL;
        }
        
        // Save all user data to Firestore
        // SECURITY: Do NOT pass password to Firestore
        // Firebase Auth automatically handles password hashing and storage
        // Passwords are securely stored in Firebase Auth, not in Firestore
        await _userService.createOrUpdateUser(
          uid: user.uid,
          email: widget.email,
          fname: widget.firstName,
          lname: widget.lastName,
          birthday: widget.birthday,
          phone: widget.phone,
          countryCode: widget.countryCode,
          idNumber: widget.idNumber,
          idImageFrontUrl: 'PENDING', // Will be uploaded later
          idImageBackUrl: 'PENDING',
          faceWithIdUrl: 'PENDING',
          userType: widget.userType ?? 'student',
          // password parameter removed - Firebase Auth handles password hashing automatically
          profileImageUrl: photoUrl,
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Account created successfully!',
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navigate to main app
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainApp(),
          ),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // RentEase Logo
                Center(
                  child: Image.asset(
                    'assets/sign_in_up/signlogo.png',
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.home, size: 60, color: Colors.blue);
                    },
                  ),
                ),
                const SizedBox(height: 40),
                // Validation Successful
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green[50],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.green[600],
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Validation Successful',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Please set your Password',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Set new password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enableInteractiveSelection: false,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Set new password',
                    labelStyle: const TextStyle(color: Colors.black),
                    hintText: 'Enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (_passwordStrength == PasswordStrength.poor) {
                      return 'Password is too weak';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Password strength indicator
                if (_passwordController.text.isNotEmpty) ...[
                  _PasswordStrengthIndicator(
                    strength: _passwordStrength,
                    progressAnimation: _progressAnimation,
                  ),
                  const SizedBox(height: 8),
                  _PasswordRequirements(
                    strength: _passwordStrength,
                    hasMinLength: _hasMinLength,
                    hasUppercase: _hasUppercase,
                    hasLowercase: _hasLowercase,
                    hasNumber: _hasNumber,
                    hasSpecialChar: _hasSpecialChar,
                  ),
                ],
                const SizedBox(height: 24),
                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  enableInteractiveSelection: false,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    labelStyle: const TextStyle(color: Colors.black),
                    hintText: 'Re-enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Password match/mismatch indicator (only show when no error message)
                if (_confirmPasswordController.text.isNotEmpty && _errorMessage == null) ...[
                  if (_passwordsMatch)
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Password matched.',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 13,
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
                          'Password doesn\'t match',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                ],
                // Error message display
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 40),
                // Set Password button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isProcessing ? null : _handleSetPassword,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.grey[850],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[850],
                      disabledForegroundColor: Colors.white,
                    ),
                    child: _isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Setting up your account...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Set Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum PasswordStrength {
  none,
  poor,
  moderate,
  strong,
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;
  final Animation<double> progressAnimation;

  const _PasswordStrengthIndicator({
    required this.strength,
    required this.progressAnimation,
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
                backgroundColor: Colors.grey[200],
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

  const _PasswordRequirements({
    required this.strength,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
  });

  @override
  Widget build(BuildContext context) {
    // Always show requirements with checkmarks
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (strength == PasswordStrength.strong) ...[
          Text(
            'Great job! This password is good and secure.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ] else if (strength == PasswordStrength.moderate) ...[
          Text(
            'Getting stronger! Add some symbols or numbers for better protection.',
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
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        _RequirementItem(
          text: 'At least 12 characters',
          isChecked: hasMinLength,
        ),
        _RequirementItem(
          text: 'One uppercase letter',
          isChecked: hasUppercase,
        ),
        _RequirementItem(
          text: 'One lowercase letter',
          isChecked: hasLowercase,
        ),
        _RequirementItem(
          text: 'One number',
          isChecked: hasNumber,
        ),
        _RequirementItem(
          text: 'One special character',
          isChecked: hasSpecialChar,
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String text;
  final bool isChecked;

  const _RequirementItem({
    required this.text,
    this.isChecked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Row(
        children: [
          if (isChecked)
            Icon(Icons.check_circle, size: 16, color: Colors.green[600])
          else
            Icon(Icons.circle, size: 4, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isChecked ? Colors.green[600] : Colors.grey[600],
              fontWeight: isChecked ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

