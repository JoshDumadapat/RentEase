import 'package:flutter/material.dart';
import 'package:rentease_app/sign_up/sign_up_page.dart';
import 'package:rentease_app/main_app.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      top: imageHeight - 25, // Start higher to create more overlap and taller card
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

  const _SignInContentWidget({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.onPasswordToggle,
    required this.onRememberMeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: isSmallScreen ? 12.0 : 16.0,
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: isSmallScreen ? 4 : 8),
              // Logo Widget
              _LogoWidget(),
              SizedBox(height: isSmallScreen ? 16 : 20),
              // Title Widget
              _TitleWidget(),
              SizedBox(height: isSmallScreen ? 2 : 4),
              // Welcome Message Widget
              _WelcomeMessageWidget(),
              SizedBox(height: isSmallScreen ? 16 : 20),
              // Email Input Widget
              _EmailInputWidget(controller: emailController),
              SizedBox(height: isSmallScreen ? 12 : 14),
              // Password Input Widget
              _PasswordInputWidget(
                controller: passwordController,
                obscurePassword: obscurePassword,
                onToggle: onPasswordToggle,
              ),
              SizedBox(height: isSmallScreen ? 8 : 10),
              // Remember Me and Forgot Password Widget
              _RememberMeAndForgotPasswordWidget(
                rememberMe: rememberMe,
                onRememberMeChanged: onRememberMeChanged,
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              // Sign In Button Widget
              _SignInButtonWidget(),
              SizedBox(height: isSmallScreen ? 8 : 12),
              // Sign Up Link Widget
              _SignUpLinkWidget(),
              SizedBox(height: isSmallScreen ? 24 : 32),
              // Divider Widget
              _DividerWidget(),
              SizedBox(height: isSmallScreen ? 24 : 32),
              // Google Sign In Button Widget
              _GoogleSignInButtonWidget(),
              SizedBox(height: isSmallScreen ? 8 : 16),
            ],
        ),
      ),
      ),
    );
  }
}

/// Widget for the RentEase logo
class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final logoHeight = isSmallScreen ? 40.0 : 45.0;
    
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
    
    return Text(
      'Sign In',
      style: TextStyle(
        fontSize: isSmallScreen ? 24 : 28,
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
    return Text(
      'Welcome back! Continue your rental journey with RentEase.',
      style: TextStyle(
        fontSize: 14,
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

  const _EmailInputWidget({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
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

  const _PasswordInputWidget({
    required this.controller,
    required this.obscurePassword,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: onToggle,
            ),
          ),
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
                fontSize: 14,
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
              fontSize: 14,
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
class _SignInButtonWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 44 : 48,
      child: ElevatedButton(
        onPressed: () {
          // Handle sign in - Navigate to HomePage after successful login
          // TODO: Add actual authentication logic here
          // For now, navigate directly to HomePage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainApp(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Sign In',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
            fontSize: 14,
            color: Colors.grey[700],
          ),
          children: [
            const TextSpan(text: "Doesn't have an account? "),
            WidgetSpan(
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      _SlideUpPageRoute(page: const SignUpPage()),
                    );
                  },
                  child: Text(
                    'Sign Up here.',
                    style: TextStyle(
                      fontSize: 14,
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
              fontSize: 14,
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
class _GoogleSignInButtonWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 44 : 48,
      child: OutlinedButton(
        onPressed: () {
          // Handle Google sign in
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google icon from assets
            Image.asset(
              'assets/sign_in_up/google.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 16,
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

