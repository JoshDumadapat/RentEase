import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rentease_app/sign_up/sign_up_page.dart';
import 'package:rentease_app/main_app.dart';
import 'package:rentease_app/services/auth_service.dart';
import 'package:rentease_app/services/user_service.dart';

/// Sign In Page with form and authentication options
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // Clear errors when user starts typing
    _emailController.addListener(() {
      if (_emailError != null) {
        setState(() {
          _emailError = null;
        });
      }
    });
    _passwordController.addListener(() {
      if (_passwordError != null) {
        setState(() {
          _passwordError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
  }

  void _setEmailError(String? error) {
    setState(() {
      _emailError = error;
    });
  }

  void _setPasswordError(String? error) {
    setState(() {
      _passwordError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image Widget at the top
          _BackgroundImageWidget(),
          // White Card Background Widget
          _WhiteCardBackgroundWidget(
            child: _SignInContentWidget(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              rememberMe: _rememberMe,
              emailError: _emailError,
              passwordError: _passwordError,
              onPasswordToggle: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              onRememberMeChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
              onClearErrors: _clearErrors,
              onSetEmailError: _setEmailError,
              onSetPasswordError: _setPasswordError,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying the background image at the top
class _BackgroundImageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.30; // Top 30% of screen (smaller)
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: imageHeight,
      child: Image.asset(
        'assets/sign_in_up/signGen.png',
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.blue[100],
            child: const Center(
              child: Icon(Icons.image, size: 100, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}

/// Widget for the white card background with rounded top corners
class _WhiteCardBackgroundWidget extends StatelessWidget {
  final Widget child;

  const _WhiteCardBackgroundWidget({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.30;
    
    return Positioned(
      left: 0,
      right: 0,
      top: imageHeight - 55,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Widget for the sign in content
class _SignInContentWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final VoidCallback onPasswordToggle;
  final ValueChanged<bool?> onRememberMeChanged;
  final String? emailError;
  final String? passwordError;
  final VoidCallback onClearErrors;
  final ValueChanged<String?> onSetEmailError;
  final ValueChanged<String?> onSetPasswordError;

  const _SignInContentWidget({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.onPasswordToggle,
    required this.onRememberMeChanged,
    this.emailError,
    this.passwordError,
    required this.onClearErrors,
    required this.onSetEmailError,
    required this.onSetPasswordError,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isNarrowScreen = screenWidth < 360;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isNarrowScreen ? 20.0 : 24.0,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top spacing - proportional to bottom margin
                    SizedBox(height: isVerySmallScreen ? 15 : isSmallScreen ? 18 : 22),
                    // Logo Widget
                    _LogoWidget(),
                    SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 15 : 18),
                    // Title Widget
                    _TitleWidget(),
                    SizedBox(height: isVerySmallScreen ? 5 : 7),
                    // Welcome Message Widget
                    _WelcomeMessageWidget(),
                    SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 15 : 18),
                    // Email Input Widget
                    _EmailInputWidget(
                      controller: emailController,
                      errorText: emailError,
                    ),
                    SizedBox(height: isVerySmallScreen ? 10 : 12),
                    // Password Input Widget
                    _PasswordInputWidget(
                      controller: passwordController,
                      obscurePassword: obscurePassword,
                      onToggle: onPasswordToggle,
                      errorText: passwordError,
                    ),
                    SizedBox(height: isVerySmallScreen ? 5 : 7),
                    // Remember Me and Forgot Password Widget
                    _RememberMeAndForgotPasswordWidget(
                      rememberMe: rememberMe,
                      onRememberMeChanged: onRememberMeChanged,
                    ),
                    SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 15 : 18),
                    // Sign In Button Widget
                    _SignInButtonWidget(
                      emailController: emailController,
                      passwordController: passwordController,
                      formKey: formKey,
                      onClearErrors: onClearErrors,
                      onSetEmailError: onSetEmailError,
                      onSetPasswordError: onSetPasswordError,
                    ),
                    SizedBox(height: isVerySmallScreen ? 8 : 10),
                    // Sign Up Link Widget
                    _SignUpLinkWidget(),
                    SizedBox(height: isVerySmallScreen ? 15 : isSmallScreen ? 18 : 22),
                    // Divider Widget
                    _DividerWidget(),
                    SizedBox(height: isVerySmallScreen ? 15 : isSmallScreen ? 18 : 22),
                    // Google Sign In Button Widget
                    _GoogleSignInButtonWidget(),
                    // Bottom spacing - proportional to top margin
                    SizedBox(height: isVerySmallScreen ? 15 : isSmallScreen ? 18 : 22),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget for the RentEase logo
class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isNarrowScreen = screenWidth < 360;
    
    // Dynamic logo size based on screen dimensions
    double logoHeight;
    if (isVerySmallScreen) {
      logoHeight = screenHeight * 0.06; // 6% of screen height
    } else if (isSmallScreen) {
      logoHeight = screenHeight * 0.065; // 6.5% of screen height
    } else {
      logoHeight = screenHeight * 0.07; // 7% of screen height
    }
    
    // Cap the maximum size and ensure minimum size
    logoHeight = logoHeight.clamp(35.0, 45.0);
    
    // Adjust for narrow screens
    if (isNarrowScreen) {
      logoHeight *= 0.9;
    }
    
    return Center(
      child: Image.asset(
        'assets/sign_in_up/signlogo.png',
        height: logoHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.home, size: logoHeight, color: Colors.blue);
        },
      ),
    );
  }
}

/// Widget for the Sign In title
class _TitleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Text(
      'Sign In',
      style: TextStyle(
        fontSize: isVerySmallScreen ? 20 : isSmallScreen ? 22 : 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

/// Widget for the welcome message
class _WelcomeMessageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Text(
      'Welcome back! Continue your rental journey with RentEase.',
      style: TextStyle(
        fontSize: isVerySmallScreen ? 12 : isSmallScreen ? 13 : 14,
        fontWeight: FontWeight.normal,
        color: Colors.grey[700],
        height: 1.4,
      ),
    );
  }
}

/// Widget for email input field
class _EmailInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;

  const _EmailInputWidget({
    required this.controller,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: TextStyle(
            fontSize: isVerySmallScreen ? 11 : isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: isVerySmallScreen ? 6 : 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(
            fontSize: isVerySmallScreen ? 13 : 14,
            color: Colors.black, // Black text color - explicitly black
          ),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: isVerySmallScreen ? 13 : 14,
            ),
            filled: true,
            fillColor: Colors.white,
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
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: isVerySmallScreen ? 12 : isSmallScreen ? 13 : 14,
            ),
            errorStyle: TextStyle(
              fontSize: isVerySmallScreen ? 11 : 12,
              color: Colors.red[700],
            ),
            errorText: errorText,
          ),
          validator: (value) {
            if (errorText != null) {
              return errorText;
            }
            if (value == null || value.trim().isEmpty) {
              return 'Email is required';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }
}

/// Widget for password input field
class _PasswordInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool obscurePassword;
  final VoidCallback onToggle;
  final String? errorText;

  const _PasswordInputWidget({
    required this.controller,
    required this.obscurePassword,
    required this.onToggle,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: isVerySmallScreen ? 11 : isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: isVerySmallScreen ? 6 : 8),
        TextFormField(
          controller: controller,
          obscureText: obscurePassword,
          style: TextStyle(
            fontSize: isVerySmallScreen ? 13 : 14,
            color: Colors.black, // Black text color - explicitly black
          ),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: isVerySmallScreen ? 13 : 14,
            ),
            filled: true,
            fillColor: Colors.white,
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
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: isVerySmallScreen ? 12 : isSmallScreen ? 13 : 14,
            ),
            errorStyle: TextStyle(
              fontSize: isVerySmallScreen ? 11 : 12,
              color: Colors.red[700],
            ),
            errorText: errorText,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
                size: isVerySmallScreen ? 20 : 22,
              ),
              onPressed: onToggle,
            ),
          ),
          validator: (value) {
            if (errorText != null) {
              return errorText;
            }
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

/// Widget for remember me and forgot password
class _RememberMeAndForgotPasswordWidget extends StatelessWidget {
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;

  const _RememberMeAndForgotPasswordWidget({
    required this.rememberMe,
    required this.onRememberMeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: onRememberMeChanged,
              activeColor: Colors.blue,
            ),
            Text(
              'Remember me',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            // Handle forgot password
          },
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget for Sign In button
class _SignInButtonWidget extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onClearErrors;
  final ValueChanged<String?> onSetEmailError;
  final ValueChanged<String?> onSetPasswordError;

  const _SignInButtonWidget({
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.onClearErrors,
    required this.onSetEmailError,
    required this.onSetPasswordError,
  });

  @override
  State<_SignInButtonWidget> createState() => _SignInButtonWidgetState();
}

class _SignInButtonWidgetState extends State<_SignInButtonWidget> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isLoading = false;

  String _getUserFriendlyError(String errorMessage) {
    // Check for common Firebase error patterns
    if (errorMessage.contains('operation-not-allowed') ||
        errorMessage.contains('Email/Password authentication is not enabled')) {
      return 'Email/Password authentication is not enabled. Please enable it in Firebase Console → Authentication → Sign-in method.';
    } else if (errorMessage.contains('user-not-found') || 
        errorMessage.contains('No user found')) {
      return 'No account found with this email. The account may not exist in Firebase Auth. Please sign up first.';
    } else if (errorMessage.contains('wrong-password') || 
               errorMessage.contains('Wrong password') ||
               errorMessage.contains('invalid-credential')) {
      return 'Incorrect password. Make sure you are using: Pass123 (case-sensitive, no spaces).';
    } else if (errorMessage.contains('invalid-email') || 
               errorMessage.contains('invalid email')) {
      return 'Invalid email address. Please enter a valid email.';
    } else if (errorMessage.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    } else if (errorMessage.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    } else if (errorMessage.contains('network') || 
               errorMessage.contains('Network')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorMessage.contains('email') && 
               errorMessage.contains('required')) {
      return 'Email is required';
    } else if (errorMessage.contains('password') && 
               errorMessage.contains('required')) {
      return 'Password is required';
    } else {
      // Return a generic but friendly message with the actual error
      final cleanError = errorMessage.contains('Exception: ') 
          ? errorMessage.split('Exception: ').last 
          : errorMessage;
      return 'Invalid email or password. Error: $cleanError';
    }
  }

  Future<void> _handleSignIn() async {
    // Clear previous errors
    widget.onClearErrors();

    // Validate form
    if (!widget.formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Trim and convert to lowercase for consistency with sign-up
      final email = widget.emailController.text.trim().toLowerCase();
      // Trim password to remove any accidental whitespace
      final password = widget.passwordController.text.trim();

      // Additional validation
      if (email.isEmpty) {
        widget.onSetEmailError('Email is required');
        widget.formKey.currentState!.validate();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (password.isEmpty) {
        widget.onSetPasswordError('Password is required');
        widget.formKey.currentState!.validate();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Debug logging to see exactly what we're sending
      debugPrint('=== SIGN IN ATTEMPT ===');
      debugPrint('Email: "$email" (length: ${email.length})');
      debugPrint('Password: "${password.replaceAll(RegExp(r'.'), '*')}" (length: ${password.length})');
      debugPrint('Password should be: "Pass123" (length: 7)');
      
      final userCredential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      debugPrint('✅ Sign in successful. UID: ${userCredential.user?.uid}');

      if (userCredential.user != null && mounted) {
        // Check if user exists in Firestore
        final userExists = await _userService.userExists(userCredential.user!.uid);
        
        if (!userExists && mounted) {
          // User authenticated but not in Firestore - redirect to sign up
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete your registration.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const SignUpPage(),
            ),
          );
        } else if (mounted) {
          // User exists, navigate to main app
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainApp(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        debugPrint('Sign in error: $errorMessage');
        final friendlyError = _getUserFriendlyError(errorMessage);
        
        // Determine which field the error relates to
        if (errorMessage.contains('email') || 
            errorMessage.contains('user-not-found') ||
            errorMessage.contains('invalid-email') ||
            errorMessage.contains('user-not-found')) {
          widget.onSetEmailError(friendlyError);
        } else if (errorMessage.contains('password') || 
                   errorMessage.contains('wrong-password') ||
                   errorMessage.contains('Wrong password')) {
          widget.onSetPasswordError(friendlyError);
        } else {
          // Show general error in snackbar with more details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendlyError),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        
        // Trigger validation to show errors
        widget.formKey.currentState!.validate();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return SizedBox(
      width: double.infinity,
      height: isVerySmallScreen ? 44 : isSmallScreen ? 46 : 48,
      child: IgnorePointer(
        ignoring: _isLoading, // Prevent clicks when loading but keep visual state
        child: ElevatedButton(
          onPressed: _handleSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[850], // Always use same background color
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Widget for Sign Up link
class _SignUpLinkWidget extends StatefulWidget {
  @override
  State<_SignUpLinkWidget> createState() => _SignUpLinkWidgetState();
}

class _SignUpLinkWidgetState extends State<_SignUpLinkWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
          children: [
            const TextSpan(text: "Doesn't have an account? "),
            WidgetSpan(
              child: MouseRegion(
                onEnter: (_) {
                  if (mounted) setState(() => _isHovered = true);
                },
                onExit: (_) {
                  if (mounted) setState(() => _isHovered = false);
                },
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      _SlideUpPageRoute(page: const SignUpPage()),
                    );
                  },
                  child: Text(
                    'Sign Up here.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _isHovered ? Colors.blue[800] : Colors.blue,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for divider
class _DividerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or sign in with',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

/// Widget for Google Sign In button
class _GoogleSignInButtonWidget extends StatefulWidget {
  @override
  State<_GoogleSignInButtonWidget> createState() => _GoogleSignInButtonWidgetState();
}

class _GoogleSignInButtonWidgetState extends State<_GoogleSignInButtonWidget> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null && userCredential.user != null && mounted) {
        final user = userCredential.user!;
        final uid = user.uid;
        
        // Check if user exists in Firestore (with timeout protection)
        bool userExists = false;
        try {
          userExists = await _userService.userExists(uid).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('User exists check timed out, assuming new user');
              return false;
            },
          );
        } catch (e) {
          debugPrint('Error checking user exists: $e');
          // Assume new user on error
          userExists = false;
        }
        
        if (!userExists && mounted) {
          // User authenticated but not in Firestore - create basic record and redirect to sign up
          try {
            // Create a basic user record with Google account info
            final displayName = user.displayName;
            final nameParts = displayName != null ? displayName.split(' ') : <String>[];
            await _userService.createOrUpdateUser(
              uid: uid,
              email: user.email ?? '',
              fname: nameParts.isNotEmpty ? nameParts.first : null,
              lname: nameParts.length > 1 
                  ? nameParts.sublist(1).join(' ')
                  : null,
              userType: 'student',
            );
          } catch (e) {
            debugPrint('Error creating user record: $e');
            // Continue anyway - user can complete sign up manually
          }
          
          // Redirect to sign up page with Google account info
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => SignUpPage(
                  googleUser: user,
                ),
              ),
            );
          }
        } else if (mounted) {
          // User exists in Firestore, navigate to main app
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainApp(),
            ),
          );
        }
      } else if (mounted) {
        // User canceled sign in
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show error message with better formatting
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return SizedBox(
      width: double.infinity,
      height: isVerySmallScreen ? 44 : isSmallScreen ? 46 : 48,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google icon from assets
                  Image.asset(
                    'assets/sign_in_up/google.png',
                    width: isVerySmallScreen ? 18 : 20,
                    height: isVerySmallScreen ? 18 : 20,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: isVerySmallScreen ? 18 : 20,
                        height: isVerySmallScreen ? 18 : 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 13 : 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: isVerySmallScreen ? 8 : 10),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Custom page route with slide upward animation
class _SlideUpPageRoute extends PageRouteBuilder {
  final Widget page;

  _SlideUpPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

