import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_back_button.dart';
import '../../../providers/prayer_provider.dart';
import '../../main_navigation_screen.dart';
import '../widgets/islamic_event_card.dart';

class KalenderScreen extends StatefulWidget {
  const KalenderScreen({super.key});

  @override
  State<KalenderScreen> createState() => _KalenderScreenState();
}

class _KalenderScreenState extends State<KalenderScreen> {
  int? _selectedDay;
  DateTime _displayedMonth = DateTime.now();
  final List<String> _weekdays = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];
  final List<String> _months = [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgKalender.png'),
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
            title: Consumer<PrayerProvider>(
              builder: (context, prayerProv, child) {
                final data = prayerProv.data;
                final isRamadhan = data?.isRamadhan ?? false;
                final hijriMonthName = data?.hijriMonthName ?? 'Sya\'ban';
                final hijriYear = data?.hijriYear ?? '1447 H';

                return Column(
                  children: [
                    Text(
                      isRamadhan ? 'Kalender Ramadhan' : 'Kalender Hijriah',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$hijriMonthName $hijriYear',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          body: Consumer<PrayerProvider>(
            builder: (context, prayerProv, child) {
              final data = prayerProv.data;
              final isRamadhan = data?.isRamadhan ?? false;

              // Automatic current day highlight calculation based on Gregorian today date
              final now = DateTime.now();
              final isCurrentMonth =
                  _displayedMonth.year == now.year &&
                  _displayedMonth.month == now.month;
              final todayDay = isCurrentMonth ? now.day : -1;
              final currentSelectedDay =
                  _selectedDay ?? (isCurrentMonth ? now.day : 1);

              // Calculate Hijri day relative to today's Hijri day
              final baseHijriDay = (data != null && data.hijriDay > 0)
                  ? data.hijriDay
                  : now.day;
              final currentHijriDay =
                  (baseHijriDay + (currentSelectedDay - now.day)).clamp(1, 30);

              // Grid calculation for month days, previous month days, and weekday offset
              final previousMonthDays = DateTime(
                _displayedMonth.year,
                _displayedMonth.month,
                0,
              ).day;
              final daysInMonth = DateTime(
                _displayedMonth.year,
                _displayedMonth.month + 1,
                0,
              ).day;
              final firstWeekday = DateTime(
                _displayedMonth.year,
                _displayedMonth.month,
                1,
              ).weekday;
              final weekdayOffset =
                  firstWeekday - 1; // 0 for Monday (Sen), 6 for Sunday (Min)
              final totalGridItems =
                  ((weekdayOffset + daysInMonth + 6) ~/ 7) * 7;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 4),

                    // Calendar Grid Container (translucent white card)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.cardBorder.withOpacity(0.8),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Dynamic Month Header above weekday names
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      setState(() {
                                        _displayedMonth = DateTime(
                                          _displayedMonth.year,
                                          _displayedMonth.month - 1,
                                          1,
                                        );
                                        _selectedDay = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.chevron_left_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${_months[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    if (!isCurrentMonth) ...[
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _displayedMonth = DateTime.now();
                                            _selectedDay = now.day;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Text(
                                            'Bulan Ini',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      setState(() {
                                        _displayedMonth = DateTime(
                                          _displayedMonth.year,
                                          _displayedMonth.month + 1,
                                          1,
                                        );
                                        _selectedDay = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 8),

                          // Weekday Headers (Sen, Sel, Rab, Kam, Jum, Sab, Min)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _weekdays.map((day) {
                              return SizedBox(
                                width: 36,
                                child: Text(
                                  day,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 6),

                          // Days Grid with proper weekday alignment, previous month overflow, and next month overflow
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: totalGridItems,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 4,
                                  crossAxisSpacing: 4,
                                  childAspectRatio: 1.0,
                                ),
                            itemBuilder: (context, index) {
                              // 1. Previous Month Dates (Faded / Dimmed)
                              if (index < weekdayOffset) {
                                final prevDayNum =
                                    previousMonthDays -
                                    (weekdayOffset - 1 - index);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _displayedMonth = DateTime(
                                        _displayedMonth.year,
                                        _displayedMonth.month - 1,
                                        1,
                                      );
                                      _selectedDay = prevDayNum;
                                    });
                                  },
                                  child: Center(
                                    child: Text(
                                      '$prevDayNum',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Color(
                                          0xFFCBD5E1,
                                        ), // Faded / Dimmed Grey
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // 2. Next Month Dates (Faded / Dimmed)
                              if (index >= weekdayOffset + daysInMonth) {
                                final nextDayNum =
                                    index - (weekdayOffset + daysInMonth) + 1;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _displayedMonth = DateTime(
                                        _displayedMonth.year,
                                        _displayedMonth.month + 1,
                                        1,
                                      );
                                      _selectedDay = nextDayNum;
                                    });
                                  },
                                  child: Center(
                                    child: Text(
                                      '$nextDayNum',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Color(
                                          0xFFCBD5E1,
                                        ), // Faded / Dimmed Grey
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // 3. Current Month Dates
                              final dayNum = index - weekdayOffset + 1;
                              final isSelected = dayNum == currentSelectedDay;
                              final isToday = dayNum == todayDay;

                              if (isSelected) {
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedDay = dayNum),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$dayNum',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          isRamadhan
                                              ? '$currentHijriDay Ramadhan'
                                              : '$currentHijriDay Hijriah',
                                          style: const TextStyle(
                                            fontSize: 7,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedDay = dayNum),
                                child: Container(
                                  decoration: isToday
                                      ? BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.primary,
                                            width: 1.5,
                                          ),
                                        )
                                      : null,
                                  child: Center(
                                    child: Text(
                                      '$dayNum',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isToday
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isToday
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Upcoming Islamic Event Countdown Card (with bgCard.png)
                    const IslamicEventCountdownCard(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
