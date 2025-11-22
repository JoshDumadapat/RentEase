import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentease_app/sign_in/sign_in_page.dart';

/// Get Started Page with three onboarding screens
class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Get started content data
  final List<GetStartedContent> _contents = [
    GetStartedContent(
      imagePath: 'assets/getstarted_imgs/gs1.png',
      title: 'Find Your Perfect Place',
      description: 'Explore available rooms, houses, and apartments near you.',
    ),
    GetStartedContent(
      imagePath: 'assets/getstarted_imgs/gs2.png',
      title: 'List Your Property Fast',
      description: 'Post your rental, add details, and attract tenants quickly.',
    ),
    GetStartedContent(
      imagePath: 'assets/getstarted_imgs/gs3.png',
      title: 'Get Started with Rentease',
      description: 'Chat with landlords or renters and find your ideal place today.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < _contents.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Mark onboarding as complete
      await _markOnboardingComplete();
      // Navigate to sign in page with upward animation
      if (mounted) {
        Navigator.pushReplacement(
          context,
          _SlideUpPageRoute(page: const SignInPage()),
        );
      }
    }
  }

  void _skip() async {
    // Mark onboarding as complete
    await _markOnboardingComplete();
    // Navigate to sign in page with upward animation
    if (mounted) {
      Navigator.pushReplacement(
        context,
        _SlideUpPageRoute(page: const SignInPage()),
      );
    }
  }

  /// Mark that onboarding has been completed
  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView for background images with slide animation
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _contents.length,
            itemBuilder: (context, index) {
              return _BackgroundImageWidget(
                imagePath: _contents[index].imagePath,
              );
            },
          ),
          // White Arc Background Widget with animated content
          _WhiteArcBackgroundWidget(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _ContentWidget(
                key: ValueKey<int>(_currentPage),
                content: _contents[_currentPage],
                currentPage: _currentPage,
                totalPages: _contents.length,
                onNext: _nextPage,
                onSkip: _skip,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Model class for Get Started content
class GetStartedContent {
  final String imagePath;
  final String title;
  final String description;

  GetStartedContent({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

/// Widget for displaying the background image
class _BackgroundImageWidget extends StatelessWidget {
  final String imagePath;

  const _BackgroundImageWidget({
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      fit: BoxFit.fitWidth,
      width: double.infinity,
      alignment: Alignment.topCenter,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.image, size: 100, color: Colors.grey),
          ),
        );
      },
    );
  }
}

/// Widget for the white arc background at the bottom
class _WhiteArcBackgroundWidget extends StatelessWidget {
  final Widget child;

  const _WhiteArcBackgroundWidget({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Responsive height: smaller screens = slightly taller, larger screens = shorter
    final height = screenHeight * (screenHeight < 700 ? 0.43 : 0.38);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Stack(
        children: [
          // Shadow layer using CustomPaint
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, height),
            painter: _ArcShadowPainter(),
          ),
          // White arc background
          ClipPath(
            clipper: _ArcClipper(),
            child: Container(
              height: height,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for arc shadow
class _ArcShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.2);
    path.quadraticBezierTo(
      size.width / 2,
      0,
      size.width,
      size.height * 0.2,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw shadow with offset upward
    canvas.save();
    canvas.translate(0, -8); // Offset shadow upward
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Custom clipper for arc shape
class _ArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.2);
    path.quadraticBezierTo(
      size.width / 2,
      0,
      size.width,
      size.height * 0.2,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Widget for the content inside the white arc background
class _ContentWidget extends StatelessWidget {
  final GetStartedContent content;
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _ContentWidget({
    super.key,
    required this.content,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final spacing = screenHeight * 0.012;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // TOP: dots with more top padding to bring them lower and make visible
          SizedBox(height: spacing * 6),
          _PaginationIndicatorsWidget(
            currentPage: currentPage,
            totalPages: totalPages,
          ),

          // MIDDLE: title + description, take flexible space with less space from dots
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: spacing * 0.1), // Less space between dots and title
                  _TitleWidget(title: content.title),
                  SizedBox(height: spacing * 0.8),
                  _DescriptionWidget(description: content.description),
                ],
              ),
            ),
          ),

          // BOTTOM: buttons with less space from description, reduced space between Next and Skip
          Column(
            children: [
              SizedBox(height: spacing * 0.1), // Less space between description and Next
              _NextButtonWidget(
                onPressed: onNext,
                isLastPage: currentPage == totalPages - 1,
              ),
              SizedBox(height: spacing * 1.2), // Reduced space between Next and Skip
              _SkipLinkWidget(onSkip: onSkip),
              SizedBox(height: spacing * 3), // More spacing below Skip button
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget for pagination indicators (dots)
class _PaginationIndicatorsWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _PaginationIndicatorsWidget({
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == currentPage
                ? Colors.grey[800]
                : Colors.grey[300],
          ),
        ),
      ),
    );
  }
}

/// Widget for the title text
class _TitleWidget extends StatelessWidget {
  final String title;

  const _TitleWidget({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Text(
      title,
      style: TextStyle(
        fontSize: isSmallScreen ? 22 : 25,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Widget for the description text
class _DescriptionWidget extends StatelessWidget {
  final String description;

  const _DescriptionWidget({
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Text(
      description,
      style: TextStyle(
        fontSize: isSmallScreen ? 13 : 14,
        fontWeight: FontWeight.normal,
        color: Colors.grey[700],
        height: 1.5,
      ),
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Widget for the Next button
class _NextButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLastPage;

  const _NextButtonWidget({
    required this.onPressed,
    required this.isLastPage,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 40 : 43,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastPage ? 'Get Started' : 'Next',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Widget for the Skip link
class _SkipLinkWidget extends StatelessWidget {
  final VoidCallback onSkip;

  const _SkipLinkWidget({
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSkip,
      child: Text(
        'Skip',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
          decoration: TextDecoration.underline,
          decorationColor: Colors.grey[700],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Custom page route with upward slide animation
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
