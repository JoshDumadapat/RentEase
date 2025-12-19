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
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    // Pulsing animation for visibility
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
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
      right: 20,
      bottom: 90, // Above bottom navigation bar
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController]),
        builder: (context, child) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AIChatPage(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(32),
              child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Outer glow shadow
                  BoxShadow(
                    color: _themeColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                  // Inner shadow for depth
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer rotating glow ring - more visible
                  Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            _themeColor.withValues(alpha: 0.8),
                            _themeColor.withValues(alpha: 0.9),
                            _themeColor.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Middle pulsing ring - more visible
                  Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.15),
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _themeColor.withValues(alpha: 0.6 + (_pulseController.value * 0.3)),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                  // Background circle with gradient
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.grey[900]!,
                                Colors.black,
                              ]
                            : [
                                Colors.white,
                                Colors.grey[50]!,
                              ],
                      ),
                      border: Border.all(
                        color: _themeColor.withValues(alpha: 0.8),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _themeColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://res.cloudinary.com/dqymvfmbi/image/upload/v1765755084/ai/subspace_logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _themeColor.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              Icons.smart_toy,
                              color: _themeColor,
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }
}
