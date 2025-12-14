import 'dart:math';
import 'package:flutter/material.dart';

/// Confetti Widget
/// 
/// Creates a confetti animation effect with particles falling from the top
class ConfettiWidget extends StatefulWidget {
  final int particleCount;
  final Duration duration;
  final List<Color> colors;

  const ConfettiWidget({
    super.key,
    this.particleCount = 50,
    this.duration = const Duration(seconds: 3),
    this.colors = const [
      Color(0xFF00D1FF),
      Color(0xFF00B8E6),
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
    ],
  });

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Create particles
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 0.2,
        size: 4 + _random.nextDouble() * 8,
        color: widget.colors[_random.nextInt(widget.colors.length)],
        speed: 0.3 + _random.nextDouble() * 0.5,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
      ));
    }

    _controller.forward();
    _controller.addListener(_updateParticles);
  }

  void _updateParticles() {
    setState(() {
      for (final particle in _particles) {
        particle.y += particle.speed * 0.02;
        particle.rotation += particle.rotationSpeed;
        
        // Reset particle if it goes off screen
        if (particle.y > 1.2) {
          particle.y = -0.1;
          particle.x = _random.nextDouble();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParticles);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(_particles),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  Color color;
  double speed;
  double rotation;
  double rotationSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(
        particle.x * size.width,
        particle.y * size.height,
      );
      canvas.rotate(particle.rotation);

      // Draw confetti piece (rectangle)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
