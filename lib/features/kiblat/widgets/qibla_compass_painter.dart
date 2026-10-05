import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Custom Painter for Modern Compass Dial Ticks & N/S/E/W Labels
class QiblaCompassPainter extends CustomPainter {
  final double qiblaAngle;
  final bool isAligned;

  const QiblaCompassPainter({
    required this.qiblaAngle,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    final paintMajor = Paint()
      ..color = isAligned
          ? const Color(0xFF10B981)
          : AppColors.primary.withValues(alpha: 0.6)
      ..strokeWidth = 2.0;

    final paintMinor = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 360; i += 10) {
      final angle = (i - 90) * (math.pi / 180);
      final isMajor = i % 30 == 0;
      final tickLength = isMajor ? 10.0 : 5.0;

      final start = Offset(
        center.dx + (radius - tickLength) * math.cos(angle),
        center.dy + (radius - tickLength) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawLine(start, end, isMajor ? paintMajor : paintMinor);
    }

    // Draw Cardinal Direction Labels (N, E, S, W)
    const textStyleN = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Colors.red,
    );
    const textStyleOther = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppColors.textSecondary,
    );

    _drawText(canvas, center, 'N', -90, radius - 22, textStyleN);
    _drawText(canvas, center, 'E', 0, radius - 22, textStyleOther);
    _drawText(canvas, center, 'S', 90, radius - 22, textStyleOther);
    _drawText(canvas, center, 'W', 180, radius - 22, textStyleOther);
  }

  void _drawText(
    Canvas canvas,
    Offset center,
    String text,
    double angleDegrees,
    double distance,
    TextStyle style,
  ) {
    final angle = angleDegrees * (math.pi / 180);
    final pos = Offset(
      center.dx + distance * math.cos(angle),
      center.dy + distance * math.sin(angle),
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant QiblaCompassPainter oldDelegate) {
    return oldDelegate.qiblaAngle != qiblaAngle ||
        oldDelegate.isAligned != isAligned;
  }
}
