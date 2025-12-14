import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentease_app/landing/widgets/shiny_light_effect.dart';
import 'package:rentease_app/get_started/get_started_page.dart';
import 'package:rentease_app/main_app.dart';
import 'package:rentease_app/sign_in/sign_in_page.dart';

/// Landing page that displays the landing background with animated logo
/// Acts as a loading screen and redirects to get started page if first time use
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000), // Slower animation
      vsync: this,
    );

    // Fade up animation - slower and smoother
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    // Scale up animation - slower and more noticeable
    _scaleAnimation = Tween<double>(
      begin: 0.6, // Start smaller for more dramatic effect
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Start animation when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward().then((_) {
        _checkFirstTimeAndNavigate();
      });
    });
  }

  /// Check if it's first time use and navigate accordingly
  Future<void> _checkFirstTimeAndNavigate() async {
    try {
      // Wait for minimum loading time (3 seconds total including animation)
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      // Check if user is already authenticated
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // User is logged in, navigate directly to main app
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainApp()),
          );
        }
        return;
      }

      // User is not logged in, check first time status
      final prefs = await SharedPreferences.getInstance();
      // Reload to ensure we have the latest persisted data
      await prefs.reload();
      final isFirstTime = prefs.getBool('is_first_time') ?? true;

      // Debug: Uncomment the line below to force reset first time flag for testing
      // await prefs.setBool('is_first_time', true);

      if (!mounted) return;

      // Navigate based on first time status
      if (mounted) {
        if (isFirstTime) {
          // First time opening the app - show Get Started onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const GetStartedPage()),
          );
        } else {
          // App has been opened before - go directly to Sign In page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SignInPage()),
          );
        }
      }
    } catch (e) {
      // If there's an error, default to Sign In page (not Get Started)
      // since if there's an error reading preferences, assume it's not first time
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SignInPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ShinyLightEffect(
        child: Stack(
          children: [
            // Animated background image
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Image.asset(
                        "assets/landingbg.png",
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if image fails to load
                          return Container(
                            color: Colors.white,
                            child: const Center(
                              child: Text('Loading...'),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            // Animated logo
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      alignment: Alignment.center,
                      child: Image.asset(
                        "assets/logo.png",
                        width: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if logo fails to load
                          return const SizedBox(
                            width: 150,
                            height: 150,
                            child: Icon(Icons.home, size: 80),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
