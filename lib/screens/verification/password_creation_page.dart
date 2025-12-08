import 'package:flutter/material.dart';
import 'package:rentease_app/main_app.dart';

/// Password Creation Page
/// 
/// Allows user to set a new password after verification
/// with password strength indicator and requirements
class PasswordCreationPage extends StatefulWidget {
  const PasswordCreationPage({super.key});

  @override
  State<PasswordCreationPage> createState() => _PasswordCreationPageState();
}

class _PasswordCreationPageState extends State<PasswordCreationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  PasswordStrength _passwordStrength = PasswordStrength.none;
  bool _passwordsMatch = false;
  bool _passwordsDoNotMatch = false;
  bool _isProcessing = false;
  
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
    });
    _confirmPasswordController.addListener(_checkPasswordMatch);
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
    
    // Check individual requirements (persist once met)
    final hasMinLength = password.length >= 12;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\\[\]~`]'));
    
    setState(() {
      // Update requirement states (only set to true, never back to false once checked)
      if (hasMinLength) _hasMinLength = true;
      if (hasUppercase) _hasUppercase = true;
      if (hasLowercase) _hasLowercase = true;
      if (hasNumber) _hasNumber = true;
      if (hasSpecialChar) _hasSpecialChar = true;
      
      // Determine password strength based on CURRENT password state (check all requirements directly)
      if (password.isEmpty) {
        _passwordStrength = PasswordStrength.none;
      } else if (hasMinLength && hasUppercase && hasLowercase && hasNumber && hasSpecialChar) {
        // ALL requirements currently met = Strong (Good)
        _passwordStrength = PasswordStrength.strong;
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
      } else {
        _passwordsMatch = false;
        _passwordsDoNotMatch = true;
      }
    });
  }

  Future<void> _handleSetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordStrength == PasswordStrength.strong && _passwordsMatch) {
        setState(() {
          _isProcessing = true;
        });
        
        // Simulate processing time (you can replace this with actual password setting logic)
        await Future.delayed(const Duration(seconds: 2));
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password set successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to main app
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainApp(),
          ),
          (route) => false,
        );
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
                // Verification Successful
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
                    'Verification Successful',
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
                  decoration: InputDecoration(
                    labelText: 'Set new password',
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
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
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
                // Password match/mismatch indicator
                if (_confirmPasswordController.text.isNotEmpty) ...[
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
                const SizedBox(height: 40),
                // Set Password button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_passwordStrength == PasswordStrength.strong && _passwordsMatch && !_isProcessing)
                        ? _handleSetPassword
                        : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.grey[850],
                    ),
                    child: _isProcessing
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Set Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                // Processing message
                if (_isProcessing)
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Setting up your account...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
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

