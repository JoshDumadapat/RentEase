import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentease_app/main_app.dart';
import 'package:rentease_app/screens/verification/password_creation_page.dart';
import 'package:rentease_app/screens/verification/verification_error_page.dart';
import 'package:rentease_app/services/id_validation_service.dart';
import 'package:rentease_app/services/auth_service.dart';
import 'package:rentease_app/services/user_service.dart';

/// Verification Loading Page
/// 
/// Shows a loading screen with face validation animation
/// after selfie capture, before password creation
/// Performs actual ID validation using OCR and face recognition
class VerificationLoadingPage extends StatefulWidget {
  final XFile frontIdImage;
  final XFile? backIdImage;
  final XFile selfieImage;
  final String idNumber;
  final String firstName;
  final String lastName;
  final String email;
  final String? birthday;
  final String phone;
  final String countryCode;
  final GoogleSignInTempData? googleData;
  final String? userType; // 'student' or 'professional'

  const VerificationLoadingPage({
    super.key,
    required this.frontIdImage,
    this.backIdImage,
    required this.selfieImage,
    required this.idNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.countryCode,
    this.birthday,
    this.googleData,
    this.userType,
  });

  @override
  State<VerificationLoadingPage> createState() => _VerificationLoadingPageState();
}

class _VerificationLoadingPageState extends State<VerificationLoadingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  final IdValidationService _validationService = IdValidationService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    // Use longer duration for smoother animation (reduces CPU usage)
    // Increased duration further to reduce CPU load during heavy processing
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 3000), // Slower = less CPU, smoother during processing
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );

    // Perform actual validation
    _performValidation();
  }

  /// Perform validation with periodic yields to keep UI responsive
  Future<IdValidationResult> _performValidationWithYields({
    required File frontIdFile,
    File? backIdFile,
    required File selfieFile,
  }) async {
    // Yield to allow UI to update before starting heavy processing
    await Future.delayed(const Duration(milliseconds: 100));
    
    try {
      // Perform validation with timeout to prevent hanging
      final result = await _validationService.validateId(
        frontIdImage: frontIdFile,
        backIdImage: backIdFile,
        selfieImage: selfieFile,
        userInputIdNumber: widget.idNumber,
        userInputFirstName: widget.firstName,
        userInputLastName: widget.lastName,
        userInputBirthday: widget.birthday,
        userType: widget.userType,
      ).timeout(
        const Duration(minutes: 5), // 5 minute timeout
        onTimeout: () {
          throw TimeoutException('Validation timed out after 5 minutes');
        },
      );
      
      return result;
    } catch (e) {
      // Log error and return invalid result
      debugPrint('Validation error: $e');
      rethrow;
    }
  }

  Future<void> _performValidation() async {
    try {
      // Convert XFile to File
      final frontIdFile = File(widget.frontIdImage.path);
      final backIdFile = widget.backIdImage != null ? File(widget.backIdImage!.path) : null;
      final selfieFile = File(widget.selfieImage.path);

      // Perform validation with periodic yields to keep UI responsive
      // This prevents the UI from freezing during heavy processing
      final result = await _performValidationWithYields(
        frontIdFile: frontIdFile,
        backIdFile: backIdFile,
        selfieFile: selfieFile,
      );

      if (!mounted) return;

      // Navigate based on result
      if (result.isValid) {
        if (widget.googleData != null) {
          // For Google accounts: Create Firebase Auth account, save to Firestore, then go to MainApp
          try {
            final credential = GoogleAuthProvider.credential(
              idToken: widget.googleData!.idToken,
              accessToken: widget.googleData!.accessToken,
            );
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            final user = userCredential.user;
            
            if (user == null) {
              throw Exception('Failed to create Google account');
            }
            
            // Get photo URL from Google data
            String? photoUrl = widget.googleData!.photoUrl ?? user.photoURL;
            
            // Save all user data to Firestore
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
              password: null, // Google accounts don't need password
              profileImageUrl: photoUrl,
            );
            
            // Navigate directly to MainApp
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const MainApp(),
              ),
              (route) => false,
            );
          } catch (e) {
            // If Google sign-in fails, show error
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const VerificationErrorPage(),
              ),
            );
            return;
          }
        } else {
          // For email/password accounts: Navigate to password creation
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PasswordCreationPage(
                email: widget.email,
                firstName: widget.firstName,
                lastName: widget.lastName,
                birthday: widget.birthday,
                phone: widget.phone,
                countryCode: widget.countryCode,
                idNumber: widget.idNumber,
                frontIdImage: widget.frontIdImage,
                selfieImage: widget.selfieImage,
                googleData: null,
                firebaseUser: null,
                userType: widget.userType,
              ),
            ),
          );
        }
      } else {
        // Validation failed - show error screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const VerificationErrorPage(),
          ),
        );
      }
    } catch (e) {
      // On error, show error screen
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const VerificationErrorPage(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // RentEase Logo - cache to prevent rebuilds
              RepaintBoundary(
                child: Center(
                  child: Image.asset(
                    'assets/sign_in_up/signlogo.png',
                    height: 60,
                    fit: BoxFit.contain,
                    cacheWidth: 120, // Cache at specific size for performance
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.home, size: 60, color: Colors.blue);
                    },
                  ),
                ),
              ),
              const Spacer(),
              // Face validation animation - centered
              Center(
                child: _FaceValidationAnimation(scanAnimation: _scanAnimation),
              ),
              const SizedBox(height: 40),
              // Loading text - centered
              const Center(
                child: Text(
                  "You're almost done!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  "We are validating your credentials.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              // Warning message
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Don't leave or refresh this page",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.grey[200],
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaceValidationAnimation extends StatelessWidget {
  final Animation<double> scanAnimation;

  const _FaceValidationAnimation({required this.scanAnimation});

  @override
  Widget build(BuildContext context) {
    // Cache static widgets to prevent rebuilds
    final staticContent = RepaintBoundary(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Face icon with ID - static, no animation
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue[50],
                border: Border.all(
                  color: Colors.blue[300]!,
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Face icon
                  Icon(
                    Icons.face,
                    size: 80,
                    color: Colors.blue[600],
                  ),
                  // ID icon overlay
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.badge,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Outer scanning frame - static
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue[200]!.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Only animate the scanning line
    return RepaintBoundary(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Static content (cached, won't rebuild)
            staticContent,
            // Scanning line effect - optimized with CustomPainter
            AnimatedBuilder(
              animation: scanAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(200, 200),
                  painter: _ScanLinePainter(
                    scanPosition: scanAnimation.value,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for scan line - much more performant than Container with gradient/shadow
class _ScanLinePainter extends CustomPainter {
  final double scanPosition;
  static const double lineHeight = 4.0;

  _ScanLinePainter({required this.scanPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final y = scanPosition * size.height - lineHeight / 2;
    
    // Create gradient shader for this specific position
    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        Colors.blue[400]!,
        Colors.blue[600]!,
        Colors.blue[400]!,
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
    );
    
    final linePaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, lineHeight),
      )
      ..style = PaintingStyle.fill;
    
    // Simplified shadow (just a semi-transparent blue line)
    final shadowPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    // Draw shadow first
    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, lineHeight),
      shadowPaint,
    );
    
    // Draw scan line
    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, lineHeight),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) {
    // Only repaint if position changed significantly (reduce repaints)
    return (scanPosition - oldDelegate.scanPosition).abs() > 0.01;
  }
}

