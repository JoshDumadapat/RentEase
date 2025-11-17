import 'package:flutter/material.dart';
import 'package:rentease_app/sign_in/sign_in_page.dart';

/// Sign Up Page with user type selection
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image Widget at the top
          _BackgroundImageWidget(),
          // White Card Background Widget
          _WhiteCardBackgroundWidget(
            child: _SignUpContentWidget(),
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

/// Widget for the sign up content
class _SignUpContentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Logo Widget
          _LogoWidget(),
          const SizedBox(height: 20),
          // Title Widget
          _TitleWidget(),
          const SizedBox(height: 8),
          // Description Widget
          _DescriptionWidget(),
          const SizedBox(height: 24),
          // Sign up as header
          _SignUpAsHeaderWidget(),
          const SizedBox(height: 16),
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
                    onTap: () {
                      // Handle student sign up
                    },
                  ),
                  const SizedBox(height: 12),
                  _UserTypeCardWidget(
                    imagePath: 'assets/sign_in_up/pro.png',
                    title: 'Professional',
                    description: 'Sign up with a valid government ID.',
                    backgroundColor: Colors.blue[50]!,
                    arrowColor: Colors.blue,
                    onTap: () {
                      // Handle professional sign up
                    },
                  ),
                  const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          // Sign In Link Widget
          _SignInLinkWidget(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Widget for the RentEase logo
class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/sign_in_up/signlogo.png',
        height: 45,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.home, size: 45, color: Colors.blue);
        },
      ),
    );
  }
}

/// Widget for the Get Started Now title
class _TitleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Get Started Now',
      style: TextStyle(
        fontSize: 28,
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
    return Text(
      'Create an account or log in to explore what RentEase has to offer.',
      style: TextStyle(
        fontSize: 14,
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
    return Text(
      'Sign up as:',
      style: TextStyle(
        fontSize: 16,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person, size: 40, color: Colors.grey);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Title and Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
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
                fontSize: 20,
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
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
          children: [
            const TextSpan(text: 'Already have an account? '),
            WidgetSpan(
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      _SlideUpPageRoute(page: const SignInPage()),
                    );
                  },
                  child: Text(
                    'Sign In here.',
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

