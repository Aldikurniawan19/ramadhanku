import 'package:flutter/material.dart';
import '../utils/qibla_calculator.dart';

class ArQiblaOverlay extends StatefulWidget {
  final double heading;
  final double qiblaAngle;
  final double distanceKm;
  final bool isAligned;
  final String cityName;
  final VoidCallback onSwitchToCompass;

  const ArQiblaOverlay({
    super.key,
    required this.heading,
    required this.qiblaAngle,
    required this.distanceKm,
    required this.isAligned,
    required this.cityName,
    required this.onSwitchToCompass,
  });

  @override
  State<ArQiblaOverlay> createState() => _ArQiblaOverlayState();
}

class _ArQiblaOverlayState extends State<ArQiblaOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double diff =
        QiblaCalculator.getOffsetFromHeading(widget.heading, widget.qiblaAngle);
    final double absDiff = diff.abs();
    final bool isAligned = widget.isAligned;

    // Field of View calculation: camera viewport is roughly ±32 degrees
    const double maxFovDegrees = 32.0;
    final bool isInViewport = absDiff <= maxFovDegrees;

    // Horizontal offset for the Ka'bah marker across screen width
    // diff < 0 means Ka'bah is to the LEFT
    // diff > 0 means Ka'bah is to the RIGHT
    final double screenHalfWidth = size.width / 2;
    final double horizontalOffset =
        (diff / maxFovDegrees) * (screenHalfWidth - 50);

    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Dark Vignette Gradients for clear text readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xCC000000), Color(0x00000000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 140,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x00000000), Color(0xCC000000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. Horizon Guide Line
          Center(
            child: Container(
              height: 1,
              width: size.width * 0.85,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),

          // 3. Center Target Viewfinder / Crosshair
          Center(
            child: _buildCenterReticle(isAligned),
          ),

          // 4. Floating AR Ka'bah Beacon (Visible when within Camera FOV)
          if (isInViewport)
            Center(
              child: Transform.translate(
                offset: Offset(horizontalOffset, -20),
                child: _buildKaabaMarker(isAligned, absDiff),
              ),
            ),

          // 5. Directional Arrow Guidance (Visible when Ka'bah is outside FOV)
          if (!isInViewport)
            Positioned(
              left: diff < 0 ? 16 : null,
              right: diff > 0 ? 16 : null,
              top: size.height * 0.42,
              child: _buildDirectionIndicator(
                isLeft: diff < 0,
                degreesOffset: absDiff,
              ),
            ),

          // 6. Top Header Status HUD (Positioned nicely next to the back button)
          Positioned(
            top: 10,
            left: 64,
            right: 16,
            child: _buildTopHeaderHud(isAligned),
          ),

          // 7. Bottom Navigation & Mode Hint Bar
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildBottomControls(isAligned),
          ),
        ],
      ),
    );
  }

  /// Center viewfinder reticle with tech crosshairs
  Widget _buildCenterReticle(bool isAligned) {
    final color = isAligned ? const Color(0xFF10B981) : Colors.white70;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isAligned ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer subtle ring
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: isAligned ? 0.8 : 0.3),
                      width: isAligned ? 2.5 : 1.5,
                    ),
                    boxShadow: isAligned
                        ? [
                            const BoxShadow(
                              color: Color(0x6610B981),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),

                // Corner bracket indicators
                CustomPaint(
                  size: const Size(110, 110),
                  painter: _ReticleCornerPainter(
                    color: color,
                    isAligned: isAligned,
                  ),
                ),

                // Center point
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Floating Ka'bah AR Beacon with Glow & Distance Tag
  Widget _buildKaabaMarker(bool isAligned, double absDiff) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing / Glowing Ka'bah Avatar
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: isAligned ? 84 : 70,
          height: isAligned ? 84 : 70,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isAligned
                ? const Color(0xFF047857).withValues(alpha: 0.9)
                : const Color(0xFF1E293B).withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: isAligned
                  ? const Color(0xFF34D399)
                  : const Color(0xFFF59E0B),
              width: isAligned ? 3.0 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isAligned
                    ? const Color(0x8810B981)
                    : const Color(0x66F59E0B),
                blurRadius: isAligned ? 28 : 16,
                spreadRadius: isAligned ? 6 : 2,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/kakbah.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.mosque_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Floating Title & Degree Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isAligned
                ? const Color(0xFF10B981)
                : const Color(0xDD0F172A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAligned ? Colors.white : Colors.white24,
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAligned ? Icons.check_circle_rounded : Icons.navigation_rounded,
                color: Colors.white,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                isAligned
                    ? 'Tepat Arah Ka\'bah'
                    : '${widget.qiblaAngle.toStringAsFixed(1)}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Direction guidance pill when Ka'bah is offscreen (left or right)
  Widget _buildDirectionIndicator({
    required bool isLeft,
    required double degreesOffset,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xDD0F172A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF14B8A6), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x660F766E),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLeft) ...[
                  const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF2DD4BF),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                ],
                Column(
                  crossAxisAlignment: isLeft
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLeft ? 'Putar ke Kiri' : 'Putar ke Kanan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${degreesOffset.toStringAsFixed(0)}° lagi',
                      style: const TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (!isLeft) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF2DD4BF),
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Top HUD with clean, modern, and informative status display
  Widget _buildTopHeaderHud(bool isAligned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xDD0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAligned
              ? const Color(0xFF10B981).withValues(alpha: 0.6)
              : Colors.white12,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isAligned
                  ? const Color(0xFF10B981)
                  : const Color(0xFF0F766E).withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAligned ? Icons.check_rounded : Icons.explore_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),

          // Main Header Text & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAligned
                      ? 'Tepat Arah Kiblat'
                      : 'Kiblat: ${widget.qiblaAngle.toStringAsFixed(1)}° ${QiblaCalculator.getDirectionLabel(widget.qiblaAngle)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isAligned ? const Color(0xFF34D399) : Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${widget.cityName} • Kompas ${widget.heading.toStringAsFixed(0)}°',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Compact Mode Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isAligned
                  ? const Color(0x3310B981)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isAligned
                    ? const Color(0xFF10B981)
                    : Colors.white24,
              ),
            ),
            child: Text(
              isAligned ? 'PAS' : 'AR',
              style: TextStyle(
                color: isAligned ? const Color(0xFF34D399) : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Controls HUD with Distance and Mode Switcher
  Widget _buildBottomControls(bool isAligned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xDD0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Distance Icon + Info
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              'assets/images/kakbah.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.mosque_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Jarak: ${QiblaCalculator.formatDistanceKm(widget.distanceKm)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Baringkan ponsel untuk Kompas 2D',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),

          // Button to switch to 2D compass manually
          TextButton.icon(
            onPressed: widget.onSwitchToCompass,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.explore_outlined, size: 14),
            label: const Text(
              'Kompas',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for tech reticle corner brackets
class _ReticleCornerPainter extends CustomPainter {
  final Color color;
  final bool isAligned;

  _ReticleCornerPainter({required this.color, required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = isAligned ? 2.5 : 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLen = 16.0;
    final w = size.width;
    final h = size.height;

    // Top-Left
    canvas.drawLine(const Offset(0, cornerLen), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), paint);

    // Top-Right
    canvas.drawLine(Offset(w - cornerLen, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, cornerLen), paint);

    // Bottom-Left
    canvas.drawLine(Offset(0, h - cornerLen), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(cornerLen, h), paint);

    // Bottom-Right
    canvas.drawLine(Offset(w - cornerLen, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant _ReticleCornerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isAligned != isAligned;
  }
}
