import 'package:flutter/material.dart';

/// Light shimmer effect widget
/// Creates a subtle gradient shimmer animation
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFF00B8E6),
    this.highlightColor = const Color(0xFF00D1FF),
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base child
        widget.child,
        // Shimmer overlay with lower opacity
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 - _controller.value * 2, 0),
                    end: Alignment(1.0 - _controller.value * 2, 0),
                    colors: [
                      Colors.transparent,
                      widget.highlightColor.withValues(alpha: 0.08),
                      widget.baseColor.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.6, 1.0],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
