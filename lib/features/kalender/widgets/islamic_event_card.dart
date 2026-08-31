import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/islamic_event_service.dart';

class IslamicEventCountdownCard extends StatefulWidget {
  final int currentHijriYear;
  const IslamicEventCountdownCard({
    super.key,
    this.currentHijriYear = 1448,
  });

  @override
  State<IslamicEventCountdownCard> createState() => _IslamicEventCountdownCardState();
}

class _IslamicEventCountdownCardState extends State<IslamicEventCountdownCard> {
  Timer? _timer;
  late IslamicEventItem _currentEvent;
  late List<IslamicEventItem> _allEvents;

  @override
  void initState() {
    super.initState();
    _loadEvent();
    _startTimer();
  }

  void _loadEvent() {
    _allEvents = IslamicEventService.getAllEvents(currentHijriYear: widget.currentHijriYear);
    _currentEvent = IslamicEventService.getNearestUpcomingEvent(currentHijriYear: widget.currentHijriYear);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // If current event target has passed, automatically refresh to next event
          if (_currentEvent.isPassed) {
            _loadEvent();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _currentEvent.remainingDuration;
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/bgCard.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Top Pill Badge "Hitung Mundur"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Hitung Mundur',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 2. Event Title & Hijri Date Subtitle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _currentEvent.title,
                      style: GoogleFonts.lora(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F3D2E),
                      ),
                    ),
                    if (_currentEvent.titleArabic.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        _currentEvent.titleArabic,
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _currentEvent.formattedHijriDate,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 10),

                // 3. Four Compact Countdown Digit Boxes (Hari, Jam, Menit, Detik)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDigitBox(days.toString().padLeft(2, '0'), 'Hari'),
                    _buildColonSeparator(),
                    _buildDigitBox(hours.toString().padLeft(2, '0'), 'Jam'),
                    _buildColonSeparator(),
                    _buildDigitBox(minutes.toString().padLeft(2, '0'), 'Menit'),
                    _buildColonSeparator(),
                    _buildDigitBox(seconds.toString().padLeft(2, '0'), 'Detik'),
                  ],
                ),

                const SizedBox(height: 10),

                // 4. Description Note
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentEvent.descriptionLine1,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentEvent.descriptionLine2,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitBox(String value, String label) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F3D2E),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColonSeparator() {
    return const Text(
      ':',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}
