import 'package:flutter/material.dart';
import 'package:rentease_app/sign_in/sign_in_page.dart';
import 'package:rentease_app/sign_up/sign_up_form_page.dart';
import 'package:rentease_app/services/auth_service.dart';

/// Sign Up Page with user type selection
class SignUpPage extends StatefulWidget {
  final GoogleSignInTempData? googleData; // Google account data (no Firebase user yet)
  
  const SignUpPage({super.key, this.googleData});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  GoogleSignInTempData? _googleData;

  @override
  void initState() {
    super.initState();
    _googleData = widget.googleData;
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
            child: _SignUpContentWidget(
              googleData: _googleData,
              onGoogleDataChanged: (value) {
                setState(() {
                  _googleData = value;
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

/// Widget for the sign up content
class _SignUpContentWidget extends StatelessWidget {
  final GoogleSignInTempData? googleData;
  final ValueChanged<GoogleSignInTempData?> onGoogleDataChanged;

  const _SignUpContentWidget({
    this.googleData,
    required this.onGoogleDataChanged,
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
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrowScreen ? 20.0 : 24.0,
            vertical: isVerySmallScreen ? 16.0 : 20.0,
          ),
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
              SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 15 : 18),
              // Sign up as header
              _SignUpAsHeaderWidget(),
              SizedBox(height: isVerySmallScreen ? 10 : 12),
              // User Type Options
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _UserTypeCardWidget(
                        imagePath: 'assets/sign_in_up/student.png',
                        title: 'Student',
                        description: 'Register with Student ID if you don\'t have a valid ID.',
                        backgroundColor: Colors.blue[50]!,
                        arrowColor: Colors.blue,
                        onTap: () async {
                          final discarded = await Navigator.of(context).push<bool>(
                            MaterialPageRoute<bool>(
                              builder: (context) => StudentSignUpPage(
                                googleData: googleData,
                                userType: 'student',
                              ),
                            ),
                          );

                          if (discarded == true) {
                            onGoogleDataChanged(null);
                          }
                        },
                      ),
                      SizedBox(height: isVerySmallScreen ? 8 : 10),
                      _UserTypeCardWidget(
                        imagePath: 'assets/sign_in_up/pro.png',
                        title: 'Professional',
                        description: 'Sign up with a valid government ID.',
                        backgroundColor: Colors.blue[50]!,
                        arrowColor: Colors.blue,
                        onTap: () async {
                          final discarded = await Navigator.of(context).push<bool>(
                            MaterialPageRoute<bool>(
                              builder: (context) => StudentSignUpPage(
                                googleData: googleData,
                                userType: 'professional',
                              ),
                            ),
                          );

                          if (discarded == true) {
                            onGoogleDataChanged(null);
                          }
                        },
                      ),
                      SizedBox(height: isVerySmallScreen ? 8 : 10),
                      _UserTypeCardWidget(
                        imagePath: 'assets/sign_in_up/guest.png',
                        title: 'Guest',
                        description: 'Continue as a guest and experience RentEase.',
                        backgroundColor: Colors.orange[50]!,
                        arrowColor: Colors.orange,
                        onTap: () {
                          // Handle guest sign up
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isVerySmallScreen ? 12 : 15),
              // Sign In Link Widget
              _SignInLinkWidget(),
              // Bottom spacing - proportional to top
              SizedBox(height: isVerySmallScreen ? 15 : isSmallScreen ? 18 : 22),
            ],
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

/// Widget for the Get Started Now title
class _TitleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Text(
      'Get Started Now',
      style: TextStyle(
        fontSize: isVerySmallScreen ? 20 : isSmallScreen ? 22 : 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

/// Widget for the description text
class _DescriptionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Text(
      'Create an account or log in to explore what RentEase has to offer.',
      style: TextStyle(
        fontSize: isVerySmallScreen ? 12 : isSmallScreen ? 13 : 14,
        fontWeight: FontWeight.normal,
        color: Colors.grey[700],
        height: 1.4,
      ),
    );
  }
}

/// Widget for Sign up as header
class _SignUpAsHeaderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Text(
      'Sign up as:',
      style: TextStyle(
        fontSize: isVerySmallScreen ? 14 : isSmallScreen ? 15 : 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }
}

/// Widget for user type card
class _UserTypeCardWidget extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final Color backgroundColor;
  final Color arrowColor;
  final VoidCallback onTap;

  const _UserTypeCardWidget({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.arrowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isVerySmallScreen ? 12 : 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar Image
            Container(
              width: isVerySmallScreen ? 50 : isSmallScreen ? 55 : 60,
              height: isVerySmallScreen ? 50 : isSmallScreen ? 55 : 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: isVerySmallScreen ? 30 : 40,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: isVerySmallScreen ? 12 : 14),
            // Title and Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: isVerySmallScreen ? 3 : 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 11 : 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow Icon
            Text(
              '→',
              style: TextStyle(
                fontSize: isVerySmallScreen ? 18 : 20,
                color: arrowColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for Sign In link
class _SignInLinkWidget extends StatefulWidget {
  @override
  State<_SignInLinkWidget> createState() => _SignInLinkWidgetState();
}

class _SignInLinkWidgetState extends State<_SignInLinkWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
          children: [
            const TextSpan(text: 'Already have an account? '),
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
                      _SlideUpPageRoute(page: const SignInPage()),
                    );
                  },
                  child: Text(
                    'Sign In here.',
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

