import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/modern_snack_bar.dart';
import '../../../core/router/smooth_page_route.dart';
import '../../../data/services/firebase_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/prayer_service.dart';
import '../../../providers/prayer_provider.dart';
import '../../quran/screens/quran_list_screen.dart';
import '../../murottal/screens/murottal_screen.dart';
import '../../doa/screens/doa_list_screen.dart';
import '../../kiblat/screens/kiblat_screen.dart';
import '../../hadits/screens/hadits_list_screen.dart';
import '../../kalender/screens/kalender_screen.dart';
import '../widgets/tasbih_modal.dart';
import '../widgets/mandatory_location_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowMandatoryLocationSheet();
    });
  }

  Future<void> _checkAndShowMandatoryLocationSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLocationSet = prefs.getBool('is_initial_location_set') ?? false;

    if (!isLocationSet && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return const MandatoryLocationSelectorSheet();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgHome.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeaderWithDateCard(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 42), // Space for floating date card half overlap
                    _buildPrayerScheduleCard(context),
                    const SizedBox(height: 16),
                    _buildQuickMenuSection(context),
                    const SizedBox(height: 20),
                    _buildDailyVerseOrHaditsCard(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithDateCard(BuildContext context) {
    final firebaseService = FirebaseService();

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, prefsSnapshot) {
        final prefs = prefsSnapshot.data;
        final isPrefsLoggedIn = prefs?.getBool('is_logged_in') ?? false;
        final prefsDisplayName = prefs?.getString('user_display_name');
        final prefsEmail = prefs?.getString('user_email');
        final user = firebaseService.currentUser;
        final isLoggedIn = user != null || isPrefsLoggedIn;

        String userName = 'Hamba Allah';
        if (isLoggedIn) {
          if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
            userName = user.displayName!;
          } else if (prefsDisplayName != null && prefsDisplayName.trim().isNotEmpty) {
            userName = prefsDisplayName;
          } else if (user?.email != null && user!.email!.trim().isNotEmpty) {
            final emailName = user.email!.split('@').first;
            if (emailName.isNotEmpty) {
              userName = emailName[0].toUpperCase() + emailName.substring(1);
            }
          } else if (prefsEmail != null && prefsEmail.trim().isNotEmpty) {
            final emailName = prefsEmail.split('@').first;
            if (emailName.isNotEmpty) {
              userName = emailName[0].toUpperCase() + emailName.substring(1);
            }
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Extended background header container with curved bottom corners
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 24,
                  right: 24,
                  bottom: 60, // Lengthened background to accommodate half card overlap
                ),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/home.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment(0.0, 0.5), // Taking image from center to bottom
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assalamu\'alaikum,',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Semoga hari ini penuh keberkahan.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                          shadows: const [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 15,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Floating Date Card (positioned half over header background, half over body)
        Positioned(
          bottom: -32,
          left: 20,
          right: 20,
          child: _buildDateCard(context),
        ),
      ],
    );
      },
    );
  }

  Widget _buildDateCard(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (context, prayerProv, child) {
        final data = prayerProv.data;
        final hijriDateStr = data != null
            ? '${data.hijriDay} ${data.hijriMonthName} ${data.hijriYear}'
            : _getFormattedHijriDate();
        final gregorianDateStr = _getFormattedGregorianDate();
        final isRamadhan = data?.isRamadhan ?? false;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        hijriDateStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isRamadhan) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryMedium),
                          ),
                          child: const Text(
                            'Ramadhan',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gregorianDateStr,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getFormattedGregorianDate() {
    final now = DateTime.now();
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dayName = days[now.weekday % 7];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  String _getFormattedHijriDate() {
    final hijri = PrayerService.calculateCurrentHijriDate();
    return '${hijri['day']} ${hijri['monthName']} ${hijri['year']}';
  }

  Widget _buildPrayerScheduleCard(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (context, prayerProv, child) {
        final data = prayerProv.data;
        final city = prayerProv.currentCity.isNotEmpty ? prayerProv.currentCity : 'Jakarta';

        final duration = data?.timeRemaining ?? Duration.zero;
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final seconds = duration.inSeconds.remainder(60);
        final countdownStr =
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        final totalSecondsInWindow = 3 * 3600;
        final progressVal = (1.0 - (duration.inSeconds / totalSecondsInWindow)).clamp(0.05, 1.0);

        List<Map<String, dynamic>> displayPrayers;
        if (data != null && data.prayers.isNotEmpty) {
          final mainPrayerIds = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];
          final filtered = data.prayers.where((p) => mainPrayerIds.contains(p.id.toLowerCase())).toList();

          bool hasAnyHighlight = filtered.any((p) => p.isNext);

          if (filtered.isNotEmpty) {
            displayPrayers = filtered.map((p) {
              IconData iconData;
              String cleanName = p.name;
              final pid = p.id.toLowerCase();
              bool isHighlight = p.isNext;

              if (pid.contains('subuh')) {
                iconData = Icons.brightness_2_outlined;
                cleanName = 'Subuh';
                if (!hasAnyHighlight) isHighlight = true;
              } else if (pid.contains('dzuhur')) {
                iconData = Icons.wb_sunny_outlined;
                cleanName = 'Dzuhur';
              } else if (pid.contains('ashar')) {
                iconData = Icons.wb_sunny_outlined;
                cleanName = 'Ashar';
              } else if (pid.contains('maghrib')) {
                iconData = Icons.wb_sunny_rounded;
                cleanName = 'Maghrib';
              } else {
                iconData = Icons.nights_stay_outlined;
                cleanName = 'Isya';
              }

              return {
                'name': cleanName,
                'time': p.time,
                'icon': iconData,
                'isHighlight': isHighlight,
              };
            }).toList();
          } else {
            displayPrayers = _getFallbackPrayers();
          }
        } else {
          displayPrayers = _getFallbackPrayers();
        }

        final isRamadhan = data?.isRamadhan ?? false;
        String rawNextPrayer = (data != null && data.nextPrayerName.isNotEmpty)
            ? data.nextPrayerName
            : 'Subuh';
        String nextPrayerLabel = 'Subuh';

        if (!isRamadhan) {
          // Outside Ramadhan: map Imsak to Subuh and strip fasting labels
          if (rawNextPrayer.toLowerCase().contains('imsak')) {
            nextPrayerLabel = 'Subuh';
          } else {
            nextPrayerLabel = rawNextPrayer.replaceAll('(Buka Puasa)', '').trim();
          }
        } else {
          // During Ramadhan: show Imsak (Sahur) or Buka Puasa (Maghrib)
          if (rawNextPrayer.toLowerCase().contains('imsak')) {
            nextPrayerLabel = 'Imsak (Sahur)';
          } else if (rawNextPrayer.toLowerCase().contains('maghrib')) {
            nextPrayerLabel = 'Buka Puasa (Maghrib)';
          } else {
            nextPrayerLabel = rawNextPrayer.replaceAll('(Buka Puasa)', '').trim();
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location & Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jadwal Sholat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      ModernSnackBar.show(
                        context,
                        title: 'Mendeteksi GPS',
                        message: 'Mendapatkan lokasi presisi dari perangkat...',
                        type: SnackBarType.info,
                      );
                      try {
                        final prayerProv = Provider.of<PrayerProvider>(context, listen: false);
                        final detectedCity = await prayerProv.detectAndLoadGpsLocation();
                        if (context.mounted) {
                          ModernSnackBar.show(
                            context,
                            title: 'Lokasi Terdeteksi',
                            message: 'Jadwal sholat otomatis disesuaikan untuk wilayah $detectedCity',
                            type: SnackBarType.success,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          if (e is GpsDisabledException || e.toString().contains('GPS')) {
                            LocationService.showGpsPromptDialog(context);
                          } else {
                            ModernSnackBar.show(
                              context,
                              title: 'Gagal Mendeteksi Lokasi',
                              message: e.toString(),
                              type: SnackBarType.error,
                            );
                          }
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            city,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 5 Prayer Times Row (Dynamic for current time & city API)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: displayPrayers.map((item) {
                  final isHighlight = item['isHighlight'] as bool;
                  if (isHighlight) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.activePrayerBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3027827B),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['name'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['time'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Expanded(
                    child: Column(
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: AppColors.textMuted,
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['name'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['time'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Divider
              Container(
                height: 1,
                color: AppColors.cardBorder,
              ),

              const SizedBox(height: 16),

              // Countdown & Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Menuju waktu $nextPrayerLabel',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressVal,
                            minHeight: 4,
                            backgroundColor: AppColors.primaryLight,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    countdownStr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }



  List<Map<String, dynamic>> _getFallbackPrayers() {
    return [
      {'name': 'Subuh', 'time': '04:33', 'icon': Icons.brightness_2_outlined, 'isHighlight': false},
      {'name': 'Dzuhur', 'time': '12:05', 'icon': Icons.wb_sunny_outlined, 'isHighlight': false},
      {'name': 'Ashar', 'time': '15:15', 'icon': Icons.wb_sunny_outlined, 'isHighlight': false},
      {'name': 'Maghrib', 'time': '18:07', 'icon': Icons.wb_sunny_rounded, 'isHighlight': true},
      {'name': 'Isya', 'time': '19:18', 'icon': Icons.nights_stay_outlined, 'isHighlight': false},
    ];
  }

  Widget _buildQuickMenuSection(BuildContext context) {
    final menuItemsRow1 = [
      {
        'title': 'Al-Qur\'an',
        'imagePath': 'assets/icons/alquran.jpg',
        'onTap': () => SmoothPageRoute.navigate(context, const QuranListScreen()),
      },
      {
        'title': 'Murottal',
        'imagePath': 'assets/icons/murottal.jpg',
        'onTap': () => SmoothPageRoute.navigate(context, const MurottalScreen()),
      },
      {
        'title': 'Doa Harian',
        'imagePath': 'assets/icons/doa-harian.jpg',
        'onTap': () => SmoothPageRoute.navigate(context, const DoaListScreen()),
      },
      {
        'title': 'Hadits',
        'imagePath': 'assets/icons/hadits.jpg',
        'onTap': () => SmoothPageRoute.navigate(context, const HaditsListScreen()),
      },
    ];

    final menuItemsRow2 = [
      {
        'title': 'Kalender',
        'imagePath': 'assets/icons/kalender.jpg',
        'onTap': () => SmoothPageRoute.navigate(context, const KalenderScreen()),
      },
      {
        'title': 'Qibla',
        'imagePath': 'assets/icons/qibla.jpg',
        'onTap': () => SmoothPageRoute.navigate(context, const KiblatScreen()),
      },
      {
        'title': 'Tasbih Digital',
        'imagePath': 'assets/icons/tasbih.jpg',
        'onTap': () => TasbihModal.show(context),
      },
    ];

    final cardWidth = (MediaQuery.of(context).size.width - 40 - 54) / 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Cepat',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Row 1: 4 Items evenly distributed
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: menuItemsRow1.map((item) {
            return SizedBox(
              width: cardWidth + 8,
              child: _buildMenuItemCard(context, item, cardWidth),
            );
          }).toList(),
        ),

        const SizedBox(height: 10),

        // Row 2: 3 Items perfectly centered underneath
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: menuItemsRow2.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: cardWidth + 8,
                child: _buildMenuItemCard(context, item, cardWidth),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(BuildContext context, Map<String, dynamic> item, double cardWidth) {
    final imagePath = item['imagePath'] as String?;
    final svgPath = item['svgPath'] as String?;

    Widget iconWidget;
    if (imagePath != null && imagePath.isNotEmpty) {
      iconWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.menu_book_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      );
    } else if (svgPath != null && svgPath.isNotEmpty) {
      iconWidget = SvgPicture.asset(
        svgPath,
        fit: BoxFit.contain,
      );
    } else {
      iconWidget = const Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 20);
    }

    return GestureDetector(
      onTap: item['onTap'] as VoidCallback,
      child: Column(
        children: [
          Container(
            width: cardWidth,
            height: cardWidth,
            padding: const EdgeInsets.all(11.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: iconWidget,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item['title'] as String,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyVerseOrHaditsCard(BuildContext context) {
    final now = DateTime.now();

    return Consumer<PrayerProvider>(
      builder: (context, prayerProv, child) {
        final isRamadhan = prayerProv.data?.isRamadhan ?? false;

        final List<Map<String, String>> ramadhanQuotes = [
          {
            'type': 'Hadits Hari Ini',
            'quote': 'Barangsiapa berpuasa Ramadhan karena iman dan mengharapkan pahala dari Allah, niscaya diampuni dosa-dosanya yang telah lalu.',
            'source': '(HR. Bukhari No. 1901)',
          },
          {
            'type': 'Ayat Hari Ini',
            'quote': 'Wahai orang-orang yang beriman! Diwajibkan atas kamu berpuasa sebagaimana diwajibkan atas orang sebelum kamu agar kamu bertakwa.',
            'source': '(QS. Al-Baqarah: 183)',
          },
          {
            'type': 'Ayat Hari Ini',
            'quote': 'Bulan Ramadhan adalah (bulan) yang di dalamnya diturunkan Al-Qur\'an sebagai petunjuk bagi manusia.',
            'source': '(QS. Al-Baqarah: 185)',
          },
        ];

        final List<Map<String, String>> generalQuotes = [
          {
            'type': 'Ayat Hari Ini',
            'quote': 'Dan bertasbihlah dengan memuji Tuhanmu sebelum terbit matahari dan sebelum terbenamnya.',
            'source': '(QS. Thaha: 130)',
          },
          {
            'type': 'Ayat Hari Ini',
            'quote': 'Allah tidak membebani seseorang melainkan sesuai dengan kesanggupannya.',
            'source': '(QS. Al-Baqarah: 286)',
          },
          {
            'type': 'Hadits Hari Ini',
            'quote': 'Amalan yang paling dicintai oleh Allah adalah sholat pada waktunya.',
            'source': '(HR. Bukhari & Muslim)',
          },
          {
            'type': 'Hadits Hari Ini',
            'quote': 'Senyummu di hadapan saudaramu adalah (bernilai) sedekah bagimu.',
            'source': '(HR. Tirmidzi No. 1956)',
          },
        ];

        final targetQuotes = isRamadhan ? ramadhanQuotes : generalQuotes;
        final dayIndex = (now.day + now.month * 31) % targetQuotes.length;
        final item = targetQuotes[dayIndex];

        String formattedDate = '';
        try {
          formattedDate = DateFormat('d MMMM yyyy', 'id_ID').format(now);
        } catch (_) {
          formattedDate = '${now.day} Agustus ${now.year}';
        }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Quote Icon Badge & Date
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['type']!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Quote Translation Text
          Text(
            '"${item['quote']}"',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 10),

          // Source Tag in Green Teal Font
          Text(
            item['source']!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  },
);
  }
}
