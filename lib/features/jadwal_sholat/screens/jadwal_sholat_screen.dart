import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_back_button.dart';
import '../../../providers/prayer_provider.dart';
import '../../main_navigation_screen.dart';
import '../widgets/realistic_sky_background.dart';

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

          // Subuh, Terbit, Dzuhur, Ashar, Terbenam & Isya times (from API data or default)
          String subuhTime = '04:38';
          String terbitTime = '05:58';
          String dzuhurTime = '11:58';
          String asharTime = '15:15';
          String terbenamTime = '18:07';
          String isyaTime = '19:18';

          if (data != null && data.prayers.isNotEmpty) {
            for (final p in data.prayers) {
              final pid = p.id.toLowerCase();
              if (pid.contains('subuh') || pid.contains('fajr')) subuhTime = p.time;
              if (pid.contains('dzuhur') || pid.contains('dhuhr')) dzuhurTime = p.time;
              if (pid.contains('ashar') || pid.contains('asr')) asharTime = p.time;
              if (pid.contains('maghrib')) terbenamTime = p.time;
              if (pid.contains('isya') || pid.contains('isha')) isyaTime = p.time;
            }
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
                          dzuhurTime,
                          asharTime,
                          terbenamTime,
                          isyaTime,
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
                        dzuhurTime,
                        asharTime,
                        terbenamTime,
                        isyaTime,
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
    String dzuhurTime,
    String asharTime,
    String terbenamTime,
    String isyaTime,
    PrayerProvider prayerProv,
  ) {
    return RealisticSkyBackground(
      subuhTime: subuhTime,
      terbitTime: terbitTime,
      dzuhurTime: dzuhurTime,
      asharTime: asharTime,
      maghribTime: terbenamTime,
      isyaTime: isyaTime,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                              color: Colors.black87,
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
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 46),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
