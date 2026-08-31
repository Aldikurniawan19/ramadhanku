import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/firebase_service.dart';
import '../../../providers/prayer_provider.dart';
import '../../../providers/quran_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await FirebaseService.checkAndRestoreSession();
        if (mounted) {
          Provider.of<QuranProvider>(context, listen: false).reloadUserData();
          // Await permission request so notifications are granted before scheduling
          await Provider.of<NotificationProvider>(context, listen: false).requestNotificationPermissions();
        }
      } catch (e) {
        debugPrint('[SplashScreen] Init error: $e');
      }
    });
    _startTimer();
  }

  void _startTimer() {
    Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      // Direct navigation to Main App - Users do NOT need initial login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2B36),
      body: Stack(
        children: [
          // Background Image splashScreen.png
          Positioned.fill(
            child: Image.asset(
              'assets/images/splashScreen.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF0F2B36),
              ),
            ),
          ),

          // Gradient Tint Overlay for contrast & legibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Center Content matching 1st reference image 1:1
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Animated Rub el Hizb (8-pointed Star) Loader Icon
                    const AnimatedRubElHizbLoader(size: 100),

                    const SizedBox(height: 24),

                    // App Title & Subtitle (Dynamic based on Hijri Month)
                    Consumer<PrayerProvider>(
                      builder: (context, prayerProv, child) {
                        final isRamadhan = prayerProv.data?.isRamadhan ?? false;
                        return Column(
                          children: [
                            Text(
                              isRamadhan ? 'Ramadhan' : 'Jadwal Ibadah',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isRamadhan
                                  ? 'Teman terbaik di bulan\npenuh berkah'
                                  : 'Teman terbaik ibadah harianmu\npenuh keberkahan',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFFE2E8F0),
                                height: 1.35,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const Spacer(),

                    // Animated Rub el Hizb Micro Loader Indicator at Bottom
                    const AnimatedRubElHizbLoader(size: 48),

                    const SizedBox(height: 16),

                    const Text(
                      'Copyright © 2026 by Aldi Kurniawan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0x99FFFFFF),
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedRubElHizbLoader extends StatefulWidget {
  final double size;
  const AnimatedRubElHizbLoader({super.key, this.size = 80.0});

  @override
  State<AnimatedRubElHizbLoader> createState() => _AnimatedRubElHizbLoaderState();
}

class _AnimatedRubElHizbLoaderState extends State<AnimatedRubElHizbLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size * 0.42;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating 8-pointed Rub el Hizb glowing star frame
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RubElHizbPainter(
                  progress: _controller.value,
                ),
              ),

              // Center Crescent Moon & Star
              Icon(
                Icons.nightlight_round,
                color: const Color(0xFFF8FAFC),
                size: iconSize,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RubElHizbPainter extends CustomPainter {
  final double progress;

  _RubElHizbPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 4;
    final innerRadius = outerRadius * 0.72;

    final path = Path();
    const int points = 16;
    const double angleStep = math.pi / 8;

    for (int i = 0; i < points; i++) {
      final double radius = (i % 2 == 0) ? outerRadius : innerRadius;
      final double angle = i * angleStep - math.pi / 2;
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Glow Paint Background
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..color = const Color(0xFF0F766E).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path, glowPaint);

    // Dynamic Gradient Stroke (Teal + White Accent highlight)
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.width * 0.05).clamp(2.5, 4.5)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = SweepGradient(
        colors: const [
          Color(0xFF0F766E), // Teal
          Color(0xFF2DD4BF), // Bright Teal
          Colors.white,       // White Highlight (matching user image top-right stroke)
          Color(0xFF0F766E), // Teal
        ],
        stops: const [0.0, 0.45, 0.75, 1.0],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _RubElHizbPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
