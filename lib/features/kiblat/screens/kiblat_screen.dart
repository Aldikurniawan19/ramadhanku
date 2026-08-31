import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_back_button.dart';
import '../../../providers/prayer_provider.dart';
import '../../main_navigation_screen.dart';

class KiblatScreen extends StatefulWidget {
  const KiblatScreen({super.key});

  @override
  State<KiblatScreen> createState() => _KiblatScreenState();
}

class _KiblatScreenState extends State<KiblatScreen> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  double? _heading;
  double _qiblaAngle = 295.0; // Default Indonesia Qibla angle (~295°)
  double _distanceKm = 8257.0; // Default distance to Kaaba from Jakarta
  bool _hasCompassSensor = true;
  bool _wasAligned = false;

  @override
  void initState() {
    super.initState();
    _initCompassAndLocation();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  void _initCompassAndLocation() {
    // 1. Listen to real-time device compass sensor events
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() {
          _heading = event.heading;
          _hasCompassSensor = event.heading != null;
        });

        // Trigger subtle haptic feedback when user aligns with Qibla
        if (_heading != null) {
          final diff = ((_qiblaAngle - _heading! + 360) % 360);
          final normDiff = diff > 180 ? 360 - diff : diff;
          final isAligned = normDiff.abs() <= 5.0;

          if (isAligned && !_wasAligned) {
            HapticFeedback.mediumImpact();
            _wasAligned = true;
          } else if (!isAligned && _wasAligned) {
            _wasAligned = false;
          }
        }
      }
    });

    // 2. Fetch user location and calculate exact Qibla bearing & distance
    _calculateLocationQibla();
  }

  Future<void> _calculateLocationQibla() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      double lat = pos.latitude;
      double lng = pos.longitude;

      if (lat != 0.0 || lng != 0.0) {
        final calculatedQibla = _calculateQiblaBearing(lat, lng);
        final distanceMeters = Geolocator.distanceBetween(
          lat, lng, 21.422487, 39.826206, // Kaaba coordinates
        );
        if (mounted) {
          setState(() {
            _qiblaAngle = calculatedQibla;
            _distanceKm = distanceMeters / 1000.0;
          });
        }
      }
    } catch (_) {
      // Keep defaults if location permission is not granted
    }
  }

  double _calculateQiblaBearing(double lat, double lng) {
    const double kaabaLat = 21.422487;
    const double kaabaLng = 39.826206;

    final double phi1 = lat * (math.pi / 180.0);
    final double phi2 = kaabaLat * (math.pi / 180.0);
    final double lam1 = lng * (math.pi / 180.0);
    final double lam2 = kaabaLng * (math.pi / 180.0);

    final double y = math.sin(lam2 - lam1);
    final double x = math.cos(phi1) * math.tan(phi2) - math.sin(phi1) * math.cos(lam2 - lam1);

    double qibla = math.atan2(y, x) * (180.0 / math.pi);
    return (qibla + 360.0) % 360.0;
  }

  @override
  Widget build(BuildContext context) {
    final currentHeading = _heading ?? 0.0;
    final headingDiff = ((_qiblaAngle - currentHeading + 360) % 360);
    final normDiff = headingDiff > 180 ? 360 - headingDiff : headingDiff;
    final isAligned = _hasCompassSensor && normDiff.abs() <= 5.0;

    return Consumer<PrayerProvider>(
      builder: (context, prayerProv, child) {
        final city = prayerProv.currentCity.isNotEmpty
            ? prayerProv.currentCity
            : 'Jakarta, Indonesia';

        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bgKompas.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leadingWidth: 60,
              leading: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: GlassBackButton(),
              ),
              centerTitle: true,
            title: const Text(
              'Arah Kiblat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Location Badge Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                        city,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Alignment Status Banner
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isAligned ? const Color(0xFF10B981).withValues(alpha: 0.15) : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isAligned ? const Color(0xFF10B981) : AppColors.cardBorder,
                      width: isAligned ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAligned ? Icons.check_circle_rounded : Icons.explore_rounded,
                        size: 18,
                        color: isAligned ? const Color(0xFF10B981) : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAligned
                            ? 'Tepat Menghadap Ka\'bah'
                            : !_hasCompassSensor
                                ? 'Sensor Kompas Tidak Terdeteksi'
                                : 'Putar ponsel ke arah panah hijau',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isAligned ? const Color(0xFF047857) : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Dynamic Rotating Qibla Compass Centerpiece
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Outer Ring Shadow & Glow
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            boxShadow: [
                              BoxShadow(
                                color: isAligned ? const Color(0x3310B981) : const Color(0x120F766E),
                                blurRadius: isAligned ? 32 : 24,
                                spreadRadius: isAligned ? 6 : 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),

                        // Rotatable Compass Dial (Rotates reverse to device heading)
                        Transform.rotate(
                          angle: -currentHeading * (math.pi / 180),
                          child: Container(
                            width: 250,
                            height: 250,
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
                              painter: _ModernCompassPainter(
                                qiblaAngle: _qiblaAngle,
                                isAligned: isAligned,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Pointer Arrow towards Kaaba Angle on the Dial
                                  Transform.rotate(
                                    angle: _qiblaAngle * (math.pi / 180),
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        Positioned(
                                          top: 10,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: isAligned ? const Color(0xFF10B981) : AppColors.primary,
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
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Center Kaaba Image Badge
                                  Container(
                                    width: 76,
                                    height: 76,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isAligned ? const Color(0xFF10B981) : AppColors.accentGold,
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
                                      errorBuilder: (context, error, stackTrace) => const Icon(
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

                const SizedBox(height: 28),

                // Heading Degrees & Direction Badge
                Column(
                  children: [
                    Text(
                      '${_qiblaAngle.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        fontSize: 44,
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
                        _getDirectionLabel(_qiblaAngle),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Distance Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Image.asset(
                          'assets/images/kakbah.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.mosque_rounded,
                            color: AppColors.primary,
                            size: 26,
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
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_distanceKm.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} km dari lokasi Anda',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Compass Calibration Advice Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.screen_rotation_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pegang ponsel secara mendatar & gerakkan membentuk angka 8 untuk kalibrasi kompas.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            height: 1.35,
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
          ),
        ),
      );
      },
    );
  }

  String _getDirectionLabel(double degree) {
    if (degree >= 337.5 || degree < 22.5) return 'Utara (N)';
    if (degree >= 22.5 && degree < 67.5) return 'Timur Laut (NE)';
    if (degree >= 67.5 && degree < 112.5) return 'Timur (E)';
    if (degree >= 112.5 && degree < 157.5) return 'Tenggara (SE)';
    if (degree >= 157.5 && degree < 202.5) return 'Selatan (S)';
    if (degree >= 202.5 && degree < 247.5) return 'Barat Daya (SW)';
    if (degree >= 247.5 && degree < 292.5) return 'Barat (W)';
    return 'Barat Laut (NW)';
  }
}

// Custom Painter for Sleek Modern Compass Dial Ticks & N/S/E/W Labels
class _ModernCompassPainter extends CustomPainter {
  final double qiblaAngle;
  final bool isAligned;

  _ModernCompassPainter({
    required this.qiblaAngle,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    final paintMajor = Paint()
      ..color = isAligned ? const Color(0xFF10B981) : AppColors.primary.withValues(alpha: 0.6)
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
    const textStyleN = TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red);
    const textStyleOther = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary);

    _drawText(canvas, center, 'N', -90, radius - 22, textStyleN);
    _drawText(canvas, center, 'E', 0, radius - 22, textStyleOther);
    _drawText(canvas, center, 'S', 90, radius - 22, textStyleOther);
    _drawText(canvas, center, 'W', 180, radius - 22, textStyleOther);
  }

  void _drawText(Canvas canvas, Offset center, String text, double angleDegrees, double distance, TextStyle style) {
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
  bool shouldRepaint(covariant _ModernCompassPainter oldDelegate) {
    return oldDelegate.qiblaAngle != qiblaAngle || oldDelegate.isAligned != isAligned;
  }
}
