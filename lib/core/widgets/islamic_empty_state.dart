import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IslamicEmptyState extends StatefulWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const IslamicEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  State<IslamicEmptyState> createState() => _IslamicEmptyStateState();
}

class _IslamicEmptyStateState extends State<IslamicEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _walkController;

  @override
  void initState() {
    super.initState();
    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _walkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Walking loading.png Character with Ground Track
            AnimatedBuilder(
              animation: _walkController,
              builder: (context, child) {
                // Smooth side-to-side walking translation (horizontal only, no jumping)
                final double walkX = math.sin(_walkController.value * math.pi) * 36 - 18;

                return SizedBox(
                  width: 180,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Animated Ground / Sand Track Line underneath
                      Positioned(
                        bottom: 0,
                        child: CustomPaint(
                          size: const Size(160, 16),
                          painter: _SandTrackPainter(
                            progress: _walkController.value,
                          ),
                        ),
                      ),

                      // Shadow under loading.png feet
                      Positioned(
                        bottom: 2,
                        child: Transform.translate(
                          offset: Offset(walkX, 0),
                          child: Container(
                            width: 64,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF063D2E).withOpacity(0.15),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Walking Image loading.png (Positioned right on the ground line)
                      Positioned(
                        bottom: 2,
                        child: Transform.translate(
                          offset: Offset(walkX, 0),
                          child: Image.asset(
                            'assets/images/loading.png',
                            height: 95,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.directions_walk_rounded,
                              size: 60,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Title Text
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF063D2E),
              ),
            ),

            const SizedBox(height: 6),

            // Subtitle / Message Text
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),

            // Action Button (Reset Filter/Search)
            if (widget.actionLabel != null && widget.onActionPressed != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: widget.onActionPressed,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  backgroundColor: const Color(0xFFECFDF5),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFA7F3D0)),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  widget.actionLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom Painter for Organic Desert Sand Dunes & Floating Wind-Blown Dust Track
class _SandTrackPainter extends CustomPainter {
  final double progress;

  _SandTrackPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Layer 1: Background Soft Sand Dune Ridge
    final bgDunePath = Path();
    bgDunePath.moveTo(0, h * 0.7);
    for (double x = 0; x <= w; x += 4) {
      final y = h * 0.65 + math.sin((x / w * 2 * math.pi) + (progress * math.pi)) * 3;
      bgDunePath.lineTo(x, y);
    }
    bgDunePath.lineTo(w, h);
    bgDunePath.lineTo(0, h);
    bgDunePath.close();

    final bgDunePaint = Paint()
      ..color = const Color(0xFFEAB308).withOpacity(0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bgDunePath, bgDunePaint);

    // 2. Layer 2: Foreground Organic Curved Golden Sand Dune Path
    final fgDunePath = Path();
    fgDunePath.moveTo(0, h * 0.5);
    for (double x = 0; x <= w; x += 3) {
      final y = h * 0.5 + math.sin((x / w * 3 * math.pi) - (progress * 2 * math.pi)) * 2;
      fgDunePath.lineTo(x, y);
    }

    final fgDuneStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFD4AF37).withOpacity(0.1),
          const Color(0xFFD4AF37).withOpacity(0.65),
          const Color(0xFFFEF3C7).withOpacity(0.9),
          const Color(0xFFD4AF37).withOpacity(0.65),
          const Color(0xFFD4AF37).withOpacity(0.1),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fgDunePath, fgDuneStroke);

    // 3. Layer 3: Organic Wind-Blown Sand Particles & Small Pebbles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    const int particleCount = 7;

    for (int i = 0; i < particleCount; i++) {
      final double speedMultiplier = 1.0 + (i % 3) * 0.4;
      final double rawX = ((progress * w * speedMultiplier) + (i * (w / particleCount))) % w;
      final double yOffset = math.sin((progress * 4 * math.pi) + i) * 3;
      final double y = h * 0.5 + yOffset + (i % 2 == 0 ? 1 : -2);
      final double radius = 0.9 + (i % 3) * 0.6;
      final double opacity = 0.35 + (i % 4) * 0.15;

      particlePaint.color = const Color(0xFFD4AF37).withOpacity(opacity);
      canvas.drawCircle(Offset(rawX, y), radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SandTrackPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
