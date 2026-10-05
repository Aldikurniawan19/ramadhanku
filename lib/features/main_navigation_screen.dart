import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/update_dialog.dart';
import '../data/services/app_update_service.dart';
import 'home/screens/home_screen.dart';
import 'jadwal_sholat/screens/jadwal_sholat_screen.dart';
import 'quran/screens/quran_list_screen.dart';
import 'kalender/screens/kalender_screen.dart';
import 'profil/screens/profil_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoUpdate();
    });
  }

  Future<void> _checkAutoUpdate() async {
    // Brief delay to ensure smooth home UI transition before presenting dialog
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    try {
      final updateInfo = await AppUpdateService.checkForUpdate(checkSkipped: true);
      if (updateInfo != null && updateInfo.isUpdateAvailable && mounted) {
        UpdateDialog.show(context, updateInfo: updateInfo);
      }
    } catch (e) {
      debugPrint('[MainNavigationScreen] Auto update check failed: $e');
    }
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    QuranListScreen(),
    JadwalSholatScreen(),
    KalenderScreen(),
    ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                iconSize: 26,
                backgroundColor: Colors.transparent,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textMuted,
                selectedLabelStyle: GoogleFonts.amiri(fontSize: 13, fontWeight: FontWeight.bold, height: 1.2),
                unselectedLabelStyle: GoogleFonts.amiri(fontSize: 12, fontWeight: FontWeight.w500, height: 1.2),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book_outlined),
                    activeIcon: Icon(Icons.menu_book_rounded),
                    label: 'Al-Qur\'an',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.mosque_outlined),
                    activeIcon: Icon(Icons.mosque_rounded),
                    label: 'Sholat',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month_outlined),
                    activeIcon: Icon(Icons.calendar_month_rounded),
                    label: 'Kalender',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded),
                    activeIcon: Icon(Icons.person_rounded),
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
