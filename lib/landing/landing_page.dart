import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentease_app/landing/widgets/shiny_light_effect.dart';
import 'package:rentease_app/get_started/get_started_page.dart';

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

      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('is_first_time') ?? true;

      // Debug: Uncomment the line below to force reset first time flag for testing
      // await prefs.setBool('is_first_time', true);

      if (!mounted) return;

      // Navigate to get started page if first time
      if (isFirstTime) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const GetStartedPage()),
          );
        }
      } else {
        // Navigate to home/main screen if not first time
        // Note: Replace with your home/main screen when available
        // if (mounted) {
        //   Navigator.of(context).pushReplacement(
        //     MaterialPageRoute(builder: (context) => const HomePage()),
        //   );
        // }
        // For now, if not first time but no home screen, still go to get started
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const GetStartedPage()),
          );
        }
      }
    } catch (e) {
      // If there's an error, still try to navigate to get started
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GetStartedPage()),
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
