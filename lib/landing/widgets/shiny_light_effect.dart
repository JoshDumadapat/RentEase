import 'package:flutter/material.dart';

/// Widget that creates a shiny light effect that moves across the screen
class ShinyLightEffect extends StatefulWidget {
  final Widget child;

  const ShinyLightEffect({
    super.key,
    required this.child,
  });

  @override
  State<ShinyLightEffect> createState() => _ShinyLightEffectState();
}

class _ShinyLightEffectState extends State<ShinyLightEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3), // Slower for smoother effect
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Smoother curve instead of linear
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: CustomPaint(
                painter: ShinyLightPainter(_animation.value),
                size: Size.infinite,
              ),
            ),
          ],
        );
      },
    );
  }
}

class ShinyLightPainter extends CustomPainter {
  final double progress;

  ShinyLightPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the position of the shiny light - ensure it covers full width
    final lightWidth = size.width * 0.8; // Increased width for full coverage
    // Map progress from -1.0 to 2.0 to cover the entire width smoothly
    final normalizedProgress = (progress + 1.0) / 3.0; // 0.0 to 1.0
    final lightX = normalizedProgress * (size.width + lightWidth) - lightWidth / 2;

    // Create a diagonal gradient for the shiny effect - more visible
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.77), // Increased by 10% from 0.7 to 0.77
        Colors.white.withValues(alpha: 0.0),
        Colors.transparent,
      ],
      stops: const [0.0, 0.15, 0.5, 0.85, 1.0], // Adjusted stops for smoother gradient
    );

    // Draw the shiny light effect across the entire canvas
    canvas.save();
    
    // Calculate the visible portion of the light - ensure full coverage
    final startX = lightX.clamp(-lightWidth * 0.5, size.width);
    final endX = (lightX + lightWidth).clamp(0.0, size.width + lightWidth * 0.5);
    final visibleWidth = endX - startX;
    
    if (visibleWidth > 0 || lightX < size.width || lightX + lightWidth > 0) {
      // Create the gradient shader to cover full screen height
      final gradientRect = Rect.fromLTWH(
        lightX,
        0,
        lightWidth,
        size.height,
      );
      
      final paint = Paint()
        ..shader = gradient.createShader(gradientRect)
        ..blendMode = BlendMode.overlay; // Overlay for more visibility
      
      // Draw the full gradient rectangle to ensure complete coverage
      canvas.drawRect(
        Rect.fromLTWH(
          startX.clamp(-lightWidth, size.width),
          0,
          visibleWidth.clamp(0.0, size.width + lightWidth),
          size.height,
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

