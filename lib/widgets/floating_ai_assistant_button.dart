import 'package:flutter/material.dart';
import 'package:rentease_app/screens/chat/ai_chat_page.dart';
import 'dart:math' as math;

const Color _themeColor = Color(0xFF00D1FF);

/// Floating AI Assistant Button
/// 
/// Mini circular button in bottom right corner for accessing AI assistant.
/// Should not display when inside a chat page.
class FloatingAIAssistantButton extends StatefulWidget {
  final bool hideWhenInChat;

  const FloatingAIAssistantButton({
    super.key,
    this.hideWhenInChat = true,
  });

  @override
  State<FloatingAIAssistantButton> createState() => _FloatingAIAssistantButtonState();
}

class _FloatingAIAssistantButtonState extends State<FloatingAIAssistantButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're in a chat route by examining the Navigator
    bool isInChat = false;
    if (widget.hideWhenInChat) {
      final navigator = Navigator.of(context, rootNavigator: false);
      final currentRoute = ModalRoute.of(context);
      if (currentRoute != null) {
        final routeSettings = currentRoute.settings;
        final routeName = routeSettings.name ?? '';
        final routeArguments = routeSettings.arguments;
        // Check if route name indicates chat, or if it's a MaterialPageRoute to a chat page
        isInChat = routeName.toLowerCase().contains('chat') ||
                   (routeArguments != null && routeArguments.toString().toLowerCase().contains('chat'));
      }
    }
    
    // Hide button if in chat
    if (widget.hideWhenInChat && isInChat) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;

    return Positioned(
      right: 16,
      bottom: 80, // Above bottom navigation bar
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIChatPage(),
                ),
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _themeColor.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating glow ring
                  Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            _themeColor.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Background circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bgColor, // Black in dark mode, white in light mode
                      border: Border.all(
                        color: _themeColor,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://res.cloudinary.com/dqymvfmbi/image/upload/v1765755084/ai/subspace_logo.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.smart_toy,
                            color: _themeColor,
                            size: 28,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
