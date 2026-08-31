import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_back_button.dart';
import '../../../providers/prayer_provider.dart';
import '../../main_navigation_screen.dart';

class JadwalSholatScreen extends StatefulWidget {
  const JadwalSholatScreen({super.key});

  @override
  State<JadwalSholatScreen> createState() => _JadwalSholatScreenState();
}

class _JadwalSholatScreenState extends State<JadwalSholatScreen> {
  final Map<String, bool> _adhanEnabled = {
    'subuh': true,
    'dzuhur': true,
    'ashar': true,
    'maghrib': true,
    'isya': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: Consumer<PrayerProvider>(
        builder: (context, prayerProv, child) {
          final data = prayerProv.data;
          final city = prayerProv.currentCity.isNotEmpty
              ? prayerProv.currentCity
              : 'Jakarta, Indonesia';

          // Countdown calculation
          final duration = data?.timeRemaining ?? Duration.zero;
          final hours = duration.inHours;
          final minutes = duration.inMinutes.remainder(60);
          final seconds = duration.inSeconds.remainder(60);
          final countdownStr =
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

          final isRamadhan = data?.isRamadhan ?? false;
          String rawNextPrayer =
              (data != null && data.nextPrayerName.isNotEmpty)
              ? data.nextPrayerName
              : 'Subuh';
          String nextPrayerLabel = 'Subuh';

          if (!isRamadhan) {
            if (rawNextPrayer.toLowerCase().contains('imsak')) {
              nextPrayerLabel = 'Subuh';
            } else {
              nextPrayerLabel = rawNextPrayer
                  .replaceAll('(Buka Puasa)', '')
                  .trim();
            }
          } else {
            if (rawNextPrayer.toLowerCase().contains('imsak')) {
              nextPrayerLabel = 'Imsak (Sahur)';
            } else if (rawNextPrayer.toLowerCase().contains('maghrib')) {
              nextPrayerLabel = 'Buka Puasa (Maghrib)';
            } else {
              nextPrayerLabel = rawNextPrayer
                  .replaceAll('(Buka Puasa)', '')
                  .trim();
            }
          }

          final nowStr = _getFormattedDate();

          // Main 5 Prayers list
          List<Map<String, dynamic>> displayPrayers;
          if (data != null && data.prayers.isNotEmpty) {
            final mainIds = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];
            final filtered = data.prayers
                .where((p) => mainIds.contains(p.id.toLowerCase()))
                .toList();

            bool hasAnyHighlight = filtered.any((p) => p.isNext);

            if (filtered.isNotEmpty) {
              displayPrayers = filtered.map((p) {
                String cleanName = p.name;
                final pid = p.id.toLowerCase();
                bool isHighlight = p.isNext;

                if (pid.contains('subuh')) {
                  cleanName = 'Subuh';
                  if (!hasAnyHighlight) isHighlight = true;
                } else if (pid.contains('dzuhur')) {
                  cleanName = 'Dzuhur';
                } else if (pid.contains('ashar')) {
                  cleanName = 'Ashar';
                } else if (pid.contains('maghrib')) {
                  cleanName = 'Maghrib';
                } else {
                  cleanName = 'Isya';
                }

                return {
                  'id': p.id.toLowerCase(),
                  'name': cleanName,
                  'time': p.time,
                  'isHighlight': isHighlight,
                };
              }).toList();
            } else {
              displayPrayers = _getFallbackPrayers();
            }
          } else {
            displayPrayers = _getFallbackPrayers();
          }

          // Subuh, Terbit & Terbenam times (from API data or default)
          String subuhTime = '04:38';
          String terbitTime = '05:58';
          String terbenamTime = '18:07';
          if (data != null) {
            final maghribItem = data.prayers.firstWhere(
              (p) => p.id.toLowerCase().contains('maghrib'),
              orElse: () => data.prayers.first,
            );
            terbenamTime = maghribItem.time;

            final subuhItem = data.prayers.firstWhere(
              (p) => p.id.toLowerCase().contains('subuh'),
              orElse: () => data.prayers.first,
            );
            subuhTime = subuhItem.time;
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final bottomPadding = MediaQuery.of(context).padding.bottom;

              // Give more portion to the sholatSiang / sholatMalam image as requested:
              // Bottom card needs ~295-340px for the 5 prayer rows and countdown card.
              // So cardHeight is clamped to ~300-345px, and header takes ALL the rest (~440-500px on typical devices).
              final double cardHeight = (availableHeight * 0.46).clamp(
                295.0,
                345.0,
              );
              const double overlap = 22.0;
              final double headerHeight =
                  availableHeight - cardHeight + overlap;

              // Fallback for extreme landscape/ultra-short screens to prevent RenderFlex overflow
              if (availableHeight < 460) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: _buildSholatHeader(
                          context,
                          city,
                          subuhTime,
                          terbitTime,
                          terbenamTime,
                          prayerProv,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAF6EE),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(26),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            for (
                              int index = 0;
                              index < displayPrayers.length;
                              index++
                            )
                              _buildPrayerRow(
                                displayPrayers[index],
                                isShort: true,
                              ),
                            const SizedBox(height: 12),
                            _buildBottomCountdownCard(
                              nextPrayerLabel: nextPrayerLabel,
                              countdownStr: countdownStr,
                              dateStr: nowStr,
                              isShort: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SizedBox(
                height: availableHeight,
                width: constraints.maxWidth,
                child: Stack(
                  children: [
                    // 1. Fixed Top Header (Day/Night background with generous Celestial Arc)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: headerHeight,
                      child: _buildSholatHeader(
                        context,
                        city,
                        subuhTime,
                        terbitTime,
                        terbenamTime,
                        prayerProv,
                      ),
                    ),

                    // 2. Fixed Bottom Sheet Card (Overlaps header by 22px, stretches to bottom)
                    Positioned(
                      top: headerHeight - overlap,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAF6EE),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 16,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          14,
                          16,
                          10 + (bottomPadding > 0 ? bottomPadding * 0.2 : 0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 5 Prayer List Rows
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (
                                  int index = 0;
                                  index < displayPrayers.length;
                                  index++
                                )
                                  _buildPrayerRow(displayPrayers[index]),
                              ],
                            ),

                            const Spacer(),

                            // Bottom Countdown Hero Card with Lantern Graphic
                            _buildBottomCountdownCard(
                              nextPrayerLabel: nextPrayerLabel,
                              countdownStr: countdownStr,
                              dateStr: nowStr,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPrayerRow(Map<String, dynamic> item, {bool isShort = false}) {
    final isHighlight = (item['isHighlight'] as bool?) ?? false;
    final pid = (item['id'] as String?) ?? '';
    final adhanOn = _adhanEnabled[pid] ?? true;
    final pName = (item['name'] as String?) ?? '';
    final pTime = (item['time'] as String?) ?? '';

    final double verticalPadding = isShort ? 4.5 : 6.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFE6F4F3) : const Color(0xFFF2F5F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            pName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight
                  ? const Color(0xFF063D2E)
                  : const Color(0xFF2C3E35),
            ),
          ),
          Row(
            children: [
              Text(
                pTime,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isHighlight
                      ? const Color(0xFF063D2E)
                      : const Color(0xFF2C3E35),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _toggleAdhan(pid, pName, adhanOn),
                child: Icon(
                  isHighlight
                      ? (adhanOn
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded)
                      : (adhanOn
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_outlined),
                  color: isHighlight
                      ? const Color(0xFF063D2E)
                      : (adhanOn
                            ? const Color(0xFF059669)
                            : const Color(0xFF94A3B8)),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleAdhan(String pid, String pName, bool adhanOn) {
    setState(() {
      _adhanEnabled[pid] = !adhanOn;
    });
    final newState = _adhanEnabled[pid] ?? true;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newState
              ? 'Notifikasi & suara adhan sholat $pName dibunyikan'
              : 'Notifikasi adhan sholat $pName dimatikan',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSholatHeader(
    BuildContext context,
    String city,
    String subuhTime,
    String terbitTime,
    String terbenamTime,
    PrayerProvider prayerProv,
  ) {
    final currentHour = DateTime.now().hour;
    final isDayTime = currentHour >= 6 && currentHour < 18;
    final bgImagePath = isDayTime
        ? 'assets/images/sholatSiang.png'
        : 'assets/images/sholatMalam.png';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2834), Color(0xFF184955)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Background Image (Dynamic Day / Night Header Background)
          Positioned.fill(
            child: Image.asset(
              bgImagePath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),

          // Header Content
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              left: 16,
              right: 16,
              bottom: 24, // breathing space above the card overlap
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Navigation Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const GlassBackButton(),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Jadwal Sholat',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              city,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 46),
                  ],
                ),

                // Fixed-height Celestial Arc Trajectory (Sun / Moon Path)
                // Positioned above the mosque minarets and domes in the background illustration
                SizedBox(
                  height: 160.0,
                  width: double.infinity,
                  child: Builder(
                    builder: (context) {
                      final progress = _calculateCelestialProgress(
                        terbitTime,
                        terbenamTime,
                        isDayTime,
                      );

                      final leftLabelTime = isDayTime
                          ? terbitTime
                          : terbenamTime;
                      final leftLabelName = isDayTime ? 'Terbit' : 'Terbenam';
                      final rightLabelTime = isDayTime
                          ? terbenamTime
                          : subuhTime;
                      final rightLabelName = isDayTime ? 'Terbenam' : 'Subuh';

                      return CustomPaint(
                        painter: _SunArcPainter(
                          progress: progress,
                          isDaytime: isDayTime,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Left Info Badge (Terbit at Day / Terbenam at Night)
                            Positioned(
                              left: 8,
                              bottom: -18,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.38),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isDayTime
                                              ? Icons.wb_sunny_rounded
                                              : Icons.nights_stay_rounded,
                                          color: isDayTime
                                              ? const Color(0xFFFFD54F)
                                              : const Color(0xFF81D4FA),
                                          size: 12,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          leftLabelName,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      leftLabelTime,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Right Info Badge (Terbenam at Day / Subuh at Night)
                            Positioned(
                              right: 8,
                              bottom: -18,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.38),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          rightLabelName,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Icon(
                                          isDayTime
                                              ? Icons.nights_stay_rounded
                                              : Icons.wb_sunny_rounded,
                                          color: isDayTime
                                              ? const Color(0xFF81D4FA)
                                              : const Color(0xFFFFD54F),
                                          size: 12,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      rightLabelTime,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Lifter margin to shift the entire celestial arc component ABOVE the mosques
                const SizedBox(height: 60.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateCelestialProgress(
    String terbitStr,
    String terbenamStr,
    bool isDayTime,
  ) {
    try {
      final now = DateTime.now();

      int parseHour(String time) => int.parse(time.split(':')[0]);
      int parseMinute(String time) => int.parse(time.split(':')[1]);

      final terbitTime = DateTime(
        now.year,
        now.month,
        now.day,
        parseHour(terbitStr),
        parseMinute(terbitStr),
      );
      final terbenamTime = DateTime(
        now.year,
        now.month,
        now.day,
        parseHour(terbenamStr),
        parseMinute(terbenamStr),
      );

      if (isDayTime) {
        // Daytime (06:00 -> 18:00): Sun moves from Left (Terbit) to Right (Terbenam)
        if (now.isBefore(terbitTime)) return 0.05;
        if (now.isAfter(terbenamTime)) return 0.95;
        final totalSeconds = terbenamTime.difference(terbitTime).inSeconds;
        if (totalSeconds <= 0) return 0.5;
        final elapsedSeconds = now.difference(terbitTime).inSeconds;
        return (elapsedSeconds / totalSeconds).clamp(0.05, 0.95);
      } else {
        // Nighttime (18:00 -> 06:00): Moon resets to LEFT at 18:00 and moves to Right until 06:00 AM
        DateTime nightStart = terbenamTime;
        DateTime nightEnd = terbitTime.add(const Duration(days: 1));

        if (now.isBefore(terbenamTime)) {
          // Early morning before 06:00 AM (e.g. 03:00 AM)
          nightStart = terbenamTime.subtract(const Duration(days: 1));
          nightEnd = terbitTime;
        }

        final totalSeconds = nightEnd.difference(nightStart).inSeconds;
        if (totalSeconds <= 0) return 0.5;
        final elapsedSeconds = now.difference(nightStart).inSeconds;
        return (elapsedSeconds / totalSeconds).clamp(0.05, 0.95);
      }
    } catch (_) {
      return 0.5;
    }
  }

  Widget _buildBottomCountdownCard({
    required String nextPrayerLabel,
    required String countdownStr,
    required String dateStr,
    bool isShort = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isShort ? 8 : 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Waktu tersisa menuju $nextPrayerLabel',
                  style: TextStyle(
                    fontSize: isShort ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: isShort ? 2 : 4),
                Text(
                  countdownStr,
                  style: TextStyle(
                    fontSize: isShort ? 20 : 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(height: isShort ? 2 : 3),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: isShort ? 10 : 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Lantern Graphic standing directly on the right without square box
          SizedBox(
            height: isShort ? 48 : 56,
            child: Image.asset(
              'assets/images/komponenKalender.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.wb_incandescent_outlined,
                color: AppColors.primary,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = [
      'Sabtu',
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
    ];
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dayName = days[now.weekday % 7];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  List<Map<String, dynamic>> _getFallbackPrayers() {
    return [
      {'id': 'subuh', 'name': 'Subuh', 'time': '04:33', 'isHighlight': false},
      {'id': 'dzuhur', 'name': 'Dzuhur', 'time': '12:05', 'isHighlight': false},
      {'id': 'ashar', 'name': 'Ashar', 'time': '15:15', 'isHighlight': false},
      {
        'id': 'maghrib',
        'name': 'Maghrib',
        'time': '18:07',
        'isHighlight': true,
      },
      {'id': 'isya', 'name': 'Isya', 'time': '19:18', 'isHighlight': false},
    ];
  }
}

// Premium Glowing Arc Trajectory Painter for Sun & Moon Celestial Path
class _SunArcPainter extends CustomPainter {
  final double progress;
  final bool isDaytime;

  _SunArcPainter({required this.progress, this.isDaytime = true});

  @override
  void paint(Canvas canvas, Size size) {
    // Natural celestial arch positioned above the mosque minarets and domes
    final p0 = Offset(32, size.height - 20);
    final p1 = Offset(size.width / 2, 0.0);
    final p2 = Offset(size.width - 32, size.height - 20);

    final path = Path();
    path.moveTo(p0.dx, p0.dy);
    path.quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);

    // 1. Base Dashed Track Curve
    final baseTrackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      const dashWidth = 6.0;
      const dashSpace = 4.0;
      double distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            math.min(distance + dashWidth, metric.length),
          ),
          baseTrackPaint,
        );
        distance += dashWidth + dashSpace;
      }

      // 2. Active Illuminated Trajectory Glow Line (0 -> progress)
      final activeLength = metric.length * progress.clamp(0.05, 0.95);
      final activePath = metric.extractPath(0, activeLength);

      final activeGlowPaint = Paint()
        ..shader = LinearGradient(
          colors: isDaytime
              ? const [Color(0xFFFFD54F), Color(0xFFFF9800)]
              : const [Color(0xFF81D4FA), Color(0xFFE0F7FA)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(activePath, activeGlowPaint);
    }

    // 3. Dynamic position (x, y) along quadratic Bezier curve
    final t = progress.clamp(0.05, 0.95);
    final oneMinusT = 1.0 - t;
    final x =
        oneMinusT * oneMinusT * p0.dx +
        2 * oneMinusT * t * p1.dx +
        t * t * p2.dx;
    final y =
        oneMinusT * oneMinusT * p0.dy +
        2 * oneMinusT * t * p1.dy +
        t * t * p2.dy;
    final nodeOffset = Offset(x, y);

    if (isDaytime) {
      // --- DAYTIME: Premium Glowing 3D Sun ---
      // a. Ambient Outer Radial Aura Glow
      final auraPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD54F).withValues(alpha: 0.50),
            const Color(0xFFFF9800).withValues(alpha: 0.15),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: nodeOffset, radius: 20));
      canvas.drawCircle(nodeOffset, 20, auraPaint);

      // b. Pulse Ring Frame
      final pulseRingPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(nodeOffset, 12.5, pulseRingPaint);

      // c. Sun Rays (12 Radial Coronas)
      final rayPaint = Paint()
        ..color = const Color(0xFFFFE082)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 12; i++) {
        final angle = i * (math.pi / 6);
        const rStart = 9.0;
        final rEnd = (i % 2 == 0) ? 13.5 : 11.5;
        final start = Offset(
          nodeOffset.dx + rStart * math.cos(angle),
          nodeOffset.dy + rStart * math.sin(angle),
        );
        final end = Offset(
          nodeOffset.dx + rEnd * math.cos(angle),
          nodeOffset.dy + rEnd * math.sin(angle),
        );
        canvas.drawLine(start, end, rayPaint);
      }

      // d. Solid Core Sphere with 3D Radial Gradient Fill
      final sunCorePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: const [
            Color(0xFFFFF59D),
            Color(0xFFFFD54F),
            Color(0xFFFF9800),
          ],
        ).createShader(Rect.fromCircle(center: nodeOffset, radius: 7.5));
      canvas.drawCircle(nodeOffset, 7.5, sunCorePaint);
    } else {
      // --- NIGHTTIME: Premium Glowing Crescent Moon & Twinkling Star ---
      // a. Ambient Outer Radial Aura Glow
      final auraPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF81D4FA).withValues(alpha: 0.45),
            const Color(0xFF4FC3F7).withValues(alpha: 0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: nodeOffset, radius: 20));
      canvas.drawCircle(nodeOffset, 20, auraPaint);

      // b. Outer Glow Ring
      final pulseRingPaint = Paint()
        ..color = const Color(0xFFB3E5FC).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(nodeOffset, 12.5, pulseRingPaint);

      // c. Crescent Moon Vector Path with 3D Metallic Gradient
      const moonRadius = 8.0;
      final moonPath = Path()
        ..addOval(Rect.fromCircle(center: nodeOffset, radius: moonRadius));
      final cutPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: nodeOffset.translate(3.4, -2.6),
            radius: moonRadius * 0.88,
          ),
        );
      final crescent = Path.combine(
        PathOperation.difference,
        moonPath,
        cutPath,
      );

      final moonGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Color(0xFFFFFFFF), Color(0xFFE0F7FA), Color(0xFF81D4FA)],
      ).createShader(Rect.fromCircle(center: nodeOffset, radius: moonRadius));

      final moonPaint = Paint()..shader = moonGradient;
      canvas.drawPath(crescent, moonPaint);

      // d. Decorative Twinkling Little Star next to Crescent Moon
      final starOffset = nodeOffset.translate(-11, -6);
      _drawLittleStar(canvas, starOffset, 3.0, const Color(0xFFFFF59D));
    }
  }

  void _drawLittleStar(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final rOut = size;
      final rIn = size * 0.35;

      final x1 = center.dx + rOut * math.cos(angle);
      final y1 = center.dy + rOut * math.sin(angle);
      final x2 = center.dx + rIn * math.cos(angle + math.pi / 4);
      final y2 = center.dy + rIn * math.sin(angle + math.pi / 4);

      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
      path.lineTo(x2, y2);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDaytime != isDaytime;
  }
}
