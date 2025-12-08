import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rentease_app/screens/verification/password_creation_page.dart';

/// Verification Loading Page
/// 
/// Shows a loading screen with face validation animation
/// after selfie capture, before password creation
class VerificationLoadingPage extends StatefulWidget {
  const VerificationLoadingPage({super.key});

  @override
  State<VerificationLoadingPage> createState() => _VerificationLoadingPageState();
}

class _VerificationLoadingPageState extends State<VerificationLoadingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );

    // Auto-navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PasswordCreationPage(),
          ),
        );
      }
    });
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
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Face icon with ID
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
          // Scanning line effect
          AnimatedBuilder(
            animation: scanAnimation,
            builder: (context, child) {
              return Positioned(
                top: scanAnimation.value * 200 - 2,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.blue[400]!,
                        Colors.blue[600]!,
                        Colors.blue[400]!,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Outer scanning frame
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
    );
  }
}

