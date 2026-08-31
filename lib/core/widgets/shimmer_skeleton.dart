import 'package:flutter/material.dart';

/// Reusable Sliding Gradient Shimmer Skeleton Box Widget
class ShimmerSkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerSkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<ShimmerSkeletonBox> createState() => _ShimmerSkeletonBoxState();
}

class _ShimmerSkeletonBoxState extends State<ShimmerSkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-2.0 + (progress * 4.0), -0.3),
              end: Alignment(-1.0 + (progress * 4.0), 0.3),
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}
