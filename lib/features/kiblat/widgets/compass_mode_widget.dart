import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../utils/qibla_calculator.dart';
import 'qibla_compass_painter.dart';

class CompassModeWidget extends StatelessWidget {
  final double heading;
  final double qiblaAngle;
  final double distanceKm;
  final bool hasCompassSensor;
  final bool isAligned;
  final String cityName;
  final VoidCallback? onSwitchToCamera;

  const CompassModeWidget({
    super.key,
    required this.heading,
    required this.qiblaAngle,
    required this.distanceKm,
    required this.hasCompassSensor,
    required this.isAligned,
    required this.cityName,
    this.onSwitchToCamera,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Mode Indicator & Location Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Location Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryMedium),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cityName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Compass Mode Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Mode Kompas',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Alignment Status Banner
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isAligned
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAligned
                    ? const Color(0xFF10B981)
                    : AppColors.cardBorder,
                width: isAligned ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAligned
                      ? Icons.check_circle_rounded
                      : Icons.explore_rounded,
                  size: 18,
                  color: isAligned
                      ? const Color(0xFF10B981)
                      : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isAligned
                      ? 'Tepat Menghadap Ka\'bah'
                      : !hasCompassSensor
                          ? 'Sensor Kompas Tidak Terdeteksi'
                          : 'Putar ponsel ke arah panah hijau',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isAligned
                        ? const Color(0xFF047857)
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Dynamic Rotating Qibla Compass Centerpiece
          Center(
            child: SizedBox(
              width: 270,
              height: 270,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Outer Ring Shadow & Glow
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 270,
                    height: 270,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: isAligned
                              ? const Color(0x3310B981)
                              : const Color(0x120F766E),
                          blurRadius: isAligned ? 32 : 24,
                          spreadRadius: isAligned ? 6 : 4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),

                  // Rotatable Compass Dial (Rotates reverse to device heading)
                  Transform.rotate(
                    angle: -heading * (math.pi / 180),
                    child: Container(
                      width: 245,
                      height: 245,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(
                          color: isAligned
                              ? const Color(0xFF10B981)
                              : AppColors.primary.withValues(alpha: 0.2),
                          width: isAligned ? 6 : 4,
                        ),
                      ),
                      child: CustomPaint(
                        painter: QiblaCompassPainter(
                          qiblaAngle: qiblaAngle,
                          isAligned: isAligned,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pointer Arrow towards Kaaba Angle on the Dial
                            Transform.rotate(
                              angle: qiblaAngle * (math.pi / 180),
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  Positioned(
                                    top: 8,
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: isAligned
                                            ? const Color(0xFF10B981)
                                            : AppColors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x33000000),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.navigation_rounded,
                                        color: Colors.white,
                                        size: 17,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Center Kaaba Image Badge
                            Container(
                              width: 74,
                              height: 74,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isAligned
                                      ? const Color(0xFF10B981)
                                      : AppColors.accentGold,
                                  width: 2.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x18000000),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/kakbah.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.mosque_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Heading Degrees & Direction Badge
          Column(
            children: [
              Text(
                '${qiblaAngle.toStringAsFixed(1)}°',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  height: 1.0,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  QiblaCalculator.getDirectionLabel(qiblaAngle),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // AR Camera Promotion Card (Interactive prompt to tilt up or tap)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.view_in_ar_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode Kamera AR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tegakkan ponsel untuk melihat arah kiblat di kamera secara langsung.',
                        style: TextStyle(
                          color: Color(0xFFE6FFFA),
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onSwitchToCamera != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onSwitchToCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F766E),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 14),
                        SizedBox(width: 4),
                        Text('Buka'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Distance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/images/kakbah.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.mosque_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jarak ke Ka\'bah',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${QiblaCalculator.formatDistanceKm(distanceKm)} dari lokasi Anda',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Compass Calibration Advice Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryMedium.withValues(alpha: 0.5),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.screen_rotation_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pegang ponsel secara mendatar & gerakkan membentuk angka 8 jika kompas kurang akurat.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.primary,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
