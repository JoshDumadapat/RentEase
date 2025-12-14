import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

/// Forgot Password Page with email verification
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(
          context,
          'Password reset email sent! Check your inbox.',
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = 'Failed to send reset email. Please try again.';
      }

      setState(() {
        _emailError = errorMessage;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _emailError = 'An error occurred. Please try again.';
      });
    }
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
            child: _ForgotPasswordContentWidget(
              formKey: _formKey,
              emailController: _emailController,
              isLoading: _isLoading,
              emailSent: _emailSent,
              emailError: _emailError,
              onSendEmail: _sendPasswordResetEmail,
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
    final imageHeight = screenHeight * 0.30; // Top 30% of screen
    
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
            color: Colors.grey[100],
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
      top: imageHeight - 40,
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

/// Widget for the forgot password content
class _ForgotPasswordContentWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final bool emailSent;
  final String? emailError;
  final VoidCallback onSendEmail;

  const _ForgotPasswordContentWidget({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.emailSent,
    this.emailError,
    required this.onSendEmail,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmallScreen ? 20 : isSmallScreen ? 24 : 28,
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top spacing - responsive
              SizedBox(height: isVerySmallScreen ? 15 : isSmallScreen ? 18 : 22),
              // Logo Widget
              _LogoWidget(),
              SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 15 : 18),
              // Title Widget
              _TitleWidget(),
              SizedBox(height: isVerySmallScreen ? 5 : 7),
              // Description Widget
              _DescriptionWidget(),
              SizedBox(height: isVerySmallScreen ? 20 : isSmallScreen ? 24 : 28),
              // Email Input Widget
              if (!emailSent) ...[
                _EmailInputWidget(
                  controller: emailController,
                  errorText: emailError,
                ),
                SizedBox(height: isVerySmallScreen ? 20 : isSmallScreen ? 24 : 28),
                // Send Reset Email Button
                _SendResetEmailButton(
                  isLoading: isLoading,
                  onPressed: onSendEmail,
                ),
              ] else ...[
                // Success State
                _SuccessStateWidget(),
                SizedBox(height: isVerySmallScreen ? 20 : isSmallScreen ? 24 : 28),
                // Resend Email Button
                _ResendEmailButton(
                  onPressed: () {
                    // This will be handled by parent state reset
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                ),
              ],
              SizedBox(height: isVerySmallScreen ? 15 : 18),
              // Back to Sign In Link
              _BackToSignInLink(),
              // Bottom spacing
              SizedBox(height: isVerySmallScreen ? 15 : isSmallScreen ? 18 : 22),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isNarrowScreen = screenWidth < 360;
    
    double logoHeight;
    if (isVerySmallScreen) {
      logoHeight = screenHeight * 0.06;
    } else if (isSmallScreen) {
      logoHeight = screenHeight * 0.065;
    } else {
      logoHeight = screenHeight * 0.07;
    }
    
    logoHeight = logoHeight.clamp(35.0, 45.0);
    
    if (isNarrowScreen) {
      logoHeight *= 0.9;
    }
    
    return Center(
      child: Image.asset(
        'assets/sign_in_up/signlogo.png',
        height: logoHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.home, size: logoHeight, color: Colors.black87);
        },
      ),
    );
  }
}

/// Widget for the Forgot Password title
class _TitleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Text(
      'Forgot Password?',
      style: TextStyle(
        fontSize: isVerySmallScreen ? 20 : isSmallScreen ? 22 : 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

/// Widget for the description
class _DescriptionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Text(
      'No worries! Enter your email address and we\'ll send you a link to reset your password.',
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
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            // Trigger form submission
            final form = Form.of(context);
            if (form?.validate() ?? false) {
              // Will be handled by button press
            }
          },
          style: TextStyle(
            fontSize: isVerySmallScreen ? 13 : 14,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: isVerySmallScreen ? 13 : 14,
            ),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Colors.grey,
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
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }
}

/// Widget for Send Reset Email button
class _SendResetEmailButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SendResetEmailButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isVerySmallScreen ? 14 : isSmallScreen ? 15 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Send Reset Link',
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 14 : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Widget for success state
class _SuccessStateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: isVerySmallScreen ? 48 : 56,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          Text(
            'Email Sent!',
            style: TextStyle(
              fontSize: isVerySmallScreen ? 18 : isSmallScreen ? 20 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: isVerySmallScreen ? 8 : 12),
          Text(
            'We\'ve sent a password reset link to your email address. Please check your inbox and follow the instructions to reset your password.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isVerySmallScreen ? 12 : isSmallScreen ? 13 : 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for Resend Email button
class _ResendEmailButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ResendEmailButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black, width: 1.5),
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isVerySmallScreen ? 14 : isSmallScreen ? 15 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Send to Different Email',
          style: TextStyle(
            fontSize: isVerySmallScreen ? 14 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Widget for Back to Sign In link
class _BackToSignInLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 18, color: Colors.black87),
            const SizedBox(width: 4),
            Text(
              'Back to Sign In',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
