import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/modern_snack_bar.dart';
import '../../../core/widgets/update_dialog.dart';
import '../../../data/services/app_update_service.dart';
import '../../../data/services/firebase_service.dart';
import '../../../data/services/location_service.dart';
import '../../../providers/prayer_provider.dart';
import '../../../providers/quran_provider.dart';
import '../../../providers/fasting_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../quran/screens/quran_list_screen.dart';
import '../../bantuan/screens/bantuan_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../main_navigation_screen.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, prefsSnapshot) {
        final prefs = prefsSnapshot.data;
        final isPrefsLoggedIn = prefs?.getBool('is_logged_in') ?? false;
        final prefsEmail = prefs?.getString('user_email');
        final prefsDisplayName = prefs?.getString('user_display_name');

        return StreamBuilder<User?>(
          stream: firebaseService.authStateChanges,
          initialData: firebaseService.currentUser,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final isLoggedIn = user != null || isPrefsLoggedIn;

            String userName = 'Hamba Allah';
            if (isLoggedIn) {
              if (user?.displayName != null &&
                  user!.displayName!.trim().isNotEmpty) {
                userName = user.displayName!;
              } else if (prefsDisplayName != null &&
                  prefsDisplayName.trim().isNotEmpty) {
                userName = prefsDisplayName;
              } else if (user?.email != null &&
                  user!.email!.trim().isNotEmpty) {
                final emailName = user.email!.split('@').first;
                if (emailName.isNotEmpty) {
                  userName =
                      emailName[0].toUpperCase() + emailName.substring(1);
                }
              } else if (prefsEmail != null && prefsEmail.trim().isNotEmpty) {
                final emailName = prefsEmail.split('@').first;
                if (emailName.isNotEmpty) {
                  userName =
                      emailName[0].toUpperCase() + emailName.substring(1);
                }
              }
            } else {
              userName = 'Tamu';
            }

            final userEmail = isLoggedIn
                ? (user?.email ?? prefsEmail ?? 'pengguna@ramadhan.com')
                : 'Belum masuk ke akun';

            return Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bgKalender.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        // Avatar Section
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryLight,
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 56,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (isLoggedIn)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _showEditProfileDialog(
                                          context,
                                          userName,
                                        ),
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.edit_outlined,
                                            size: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Al-Qur'an Reading Progress Card (Hanya muncul jika pengguna sudah login)
                        if (isLoggedIn) ...[
                          _buildQuranProgressCard(context),
                          const SizedBox(height: 20),
                        ],

                        // Current Selected Location Card Badge
                        Consumer<PrayerProvider>(
                          builder: (context, prayerProv, child) {
                            final currentCity =
                                prayerProv.currentCity.isNotEmpty
                                ? prayerProv.currentCity
                                : 'Jakarta';

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.cardBorder),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          color: AppColors.primary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Wilayah Saat Ini',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          Text(
                                            currentCity,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _showLocationSelectorSheet(context),
                                    icon: const Icon(
                                      Icons.swap_vert_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Ubah'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Menu List Card
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.cardBorder),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                context,
                                icon: Icons.location_city_rounded,
                                title: 'Pilih Wilayah & Kota',
                                subtitle:
                                    'Atur kota untuk jadwal sholat & puasa realtime',
                                onTap: () =>
                                    _showLocationSelectorSheet(context),
                              ),
                              const Divider(
                                height: 1,
                                color: AppColors.cardBorder,
                              ),
                              _buildMenuItem(
                                context,
                                icon: Icons.notifications_active_rounded,
                                title: 'Pengaturan Notifikasi',
                                subtitle:
                                    'Pengingat suara adzan, imsak & sahur',
                                onTap: () =>
                                    _showNotificationSettingsSheet(context),
                              ),
                              const Divider(
                                height: 1,
                                color: AppColors.cardBorder,
                              ),
                              _buildMenuItem(
                                context,
                                icon: Icons.help_outline_rounded,
                                title: 'Bantuan & FAQ',
                                subtitle: 'Informasi penggunaan & kontak',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BantuanScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(
                                height: 1,
                                color: AppColors.cardBorder,
                              ),
                              _buildMenuItem(
                                context,
                                icon: Icons.system_update_rounded,
                                title: 'Pembaruan Aplikasi',
                                subtitle: 'Periksa ketersediaan versi terbaru aplikasi',
                                onTap: () => _handleCheckUpdate(context),
                              ),
                              const Divider(
                                height: 1,
                                color: AppColors.cardBorder,
                              ),
                              // Tombol Keluar Akun (Hanya muncul jika pengguna sudah login)
                              if (isLoggedIn)
                                _buildMenuItem(
                                  context,
                                  icon: Icons.logout_outlined,
                                  title: 'Keluar Akun',
                                  subtitle: 'Keluar dari akun saat ini',
                                  titleColor: Colors.red,
                                  iconColor: Colors.red,
                                  onTap: () =>
                                      _showLogoutConfirmationDialog(context),
                                )
                              else
                                _buildMenuItem(
                                  context,
                                  icon: Icons.login_rounded,
                                  title: 'Masuk Akun',
                                  subtitle:
                                      'Masuk ke akun untuk menyimpan progres & bookmark',
                                  titleColor: AppColors.primary,
                                  iconColor: AppColors.primary,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const OnboardingScreen(),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // App Version & Copyright Footer
                        Column(
                          children: [
                            FutureBuilder<PackageInfo>(
                              future: PackageInfo.fromPlatform(),
                              builder: (context, snapshot) {
                                final version = snapshot.data?.version ?? '2.3.0';
                                return Text(
                                  'Jadwal Sholat & Al-Qur\'an v$version',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Copyright © 2026 by Aldi Kurniawan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'All Rights Reserved',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleCheckUpdate(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(width: 16),
              Flexible(
                child: Text(
                  'Memeriksa pembaruan...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final updateInfo = await AppUpdateService.checkForUpdate(checkSkipped: false);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!context.mounted) return;

      if (updateInfo != null && updateInfo.isUpdateAvailable) {
        UpdateDialog.show(context, updateInfo: updateInfo);
      } else if (updateInfo != null && !updateInfo.isUpdateAvailable) {
        ModernSnackBar.show(
          context,
          message: 'Aplikasi sudah menggunakan versi terbaru (v${updateInfo.currentVersion}).',
          type: SnackBarType.success,
        );
      } else {
        ModernSnackBar.show(
          context,
          message: 'Tidak dapat memeriksa pembaruan. Pastikan internet aktif.',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ModernSnackBar.show(
          context,
          message: 'Gagal memeriksa pembaruan: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color titleColor = AppColors.textPrimary,
    Color iconColor = AppColors.primary,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildQuranProgressCard(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, quranProv, child) {
        final currentJuz = quranProv.lastReadJuzNumber;
        const totalJuz = 30;
        final progressPercent = (currentJuz / totalJuz).clamp(0.0, 1.0);
        final percentInt = (progressPercent * 100).round();
        final lastSurah = quranProv.lastReadSurahName;
        final lastAyat = quranProv.lastReadAyatNumber;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Book Icon & Target Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Progres Tadarus Al-Qur\'an',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Consumer<PrayerProvider>(
                            builder: (context, prayerProv, child) {
                              final isRamadhan =
                                  prayerProv.data?.isRamadhan ?? false;
                              final hijriYear =
                                  prayerProv.data?.hijriYear ?? '1447 H';
                              return Text(
                                isRamadhan
                                    ? 'Target Khatam Ramadhan $hijriYear'
                                    : 'Target Khatam Al-Qur\'an Harian',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$percentInt% Khatam',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Progress Bar Header Info Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progres Bacaan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Juz $currentJuz dari $totalJuz Juz',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Custom Rounded Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 10,
                  backgroundColor: AppColors.primaryLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Last Read & Stats Box Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bookmark_added_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Terakhir Dibaca',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '$lastSurah : Ayat $lastAyat',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QuranListScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Lanjutkan'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, String currentName) {
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Ubah Nama Profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nama Lengkap / Panggilan:',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama Anda...',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_display_name', newName);
                final user = FirebaseService().currentUser;
                if (user != null) {
                  try {
                    await user.updateDisplayName(newName);
                  } catch (_) {}
                }
              }
              Navigator.pop(ctx);
              ModernSnackBar.show(
                context,
                title: 'Profil Diperbarui',
                message: 'Nama profil Anda berhasil disimpan!',
                type: SnackBarType.success,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showLocationSelectorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _LocationSelectorSheet();
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              'Keluar Akun',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_logged_in', false);
              await prefs.remove('user_email');
              await prefs.remove('user_display_name');
              await prefs.remove('user_uid');
              await FirebaseService().signOut();
              if (context.mounted) {
                Provider.of<QuranProvider>(
                  context,
                  listen: false,
                ).reloadUserData();
                Provider.of<FastingProvider>(
                  context,
                  listen: false,
                ).reloadUserData();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainNavigationScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _NotificationSettingsSheet();
      },
    );
  }
}

// Location Selector Sheet Widget
class _LocationSelectorSheet extends StatefulWidget {
  const _LocationSelectorSheet({super.key});

  @override
  State<_LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<_LocationSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _popularCities = [
    'Jakarta',
    'Surabaya',
    'Bandung',
    'Medan',
    'Semarang',
    'Makassar',
    'Palembang',
    'Tangerang',
    'Tangerang Selatan',
    'Depok',
    'Bekasi',
    'Bogor',
    'Yogyakarta',
    'Surakarta',
    'Malang',
    'Denpasar',
    'Banda Aceh',
    'Padang',
    'Pekanbaru',
    'Batam',
    'Jambi',
    'Bengkulu',
    'Bandar Lampung',
    'Pangkalpinang',
    'Tanjungpinang',
    'Serang',
    'Cirebon',
    'Tasikmalaya',
    'Sukabumi',
    'Garut',
    'Ciamis',
    'Cimahi',
    'Purwokerto',
    'Cilacap',
    'Banyumas',
    'Magelang',
    'Pekalongan',
    'Tegal',
    'Kudus',
    'Pati',
    'Jepara',
    'Demak',
    'Kendal',
    'Brebes',
    'Salatiga',
    'Blitar',
    'Kediri',
    'Madiun',
    'Mojokerto',
    'Pasuruan',
    'Probolinggo',
    'Banyuwangi',
    'Jember',
    'Sidoarjo',
    'Gresik',
    'Tuban',
    'Lamongan',
    'Pontianak',
    'Banjarmasin',
    'Banjarbaru',
    'Samarinda',
    'Balikpapan',
    'Tarakan',
    'Palangkaraya',
    'Manado',
    'Palu',
    'Kendari',
    'Gorontalo',
    'Makassar',
    'Mataram',
    'Kupang',
    'Ambon',
    'Ternate',
    'Jayapura',
    'Sorong',
    'Merauke',
    'Timika',
    'Makkah',
    'Madinah',
    'Kuala Lumpur',
    'Singapore',
  ];

  List<String> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    _filteredCities = List.from(_popularCities);
  }

  void _filterCities(String query) {
    final cleanQuery = query.trim();
    setState(() {
      if (cleanQuery.isEmpty) {
        _filteredCities = List.from(_popularCities);
      } else {
        final matches = _popularCities
            .where(
              (city) => city.toLowerCase().contains(cleanQuery.toLowerCase()),
            )
            .toList();

        final exactExists = matches.any(
          (c) => c.toLowerCase() == cleanQuery.toLowerCase(),
        );
        if (!exactExists) {
          _filteredCities = [cleanQuery, ...matches];
        } else {
          _filteredCities = matches;
        }
      }
    });
  }

  void _detectGpsLocation() async {
    ModernSnackBar.show(
      context,
      title: 'Mendeteksi GPS',
      message: 'Mendapatkan lokasi presisi dari perangkat...',
      type: SnackBarType.info,
    );

    try {
      final prayerProv = Provider.of<PrayerProvider>(context, listen: false);
      final detectedCity = await prayerProv.detectAndLoadGpsLocation();

      if (!mounted) return;
      Navigator.pop(context);

      ModernSnackBar.show(
        context,
        title: 'Lokasi Terdeteksi',
        message:
            'Jadwal sholat otomatis disesuaikan untuk wilayah $detectedCity',
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
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

  void _selectCity(String cityName) {
    final cleanCity = cityName.trim();
    if (cleanCity.isEmpty) return;

    final prayerProv = Provider.of<PrayerProvider>(context, listen: false);
    prayerProv.loadPrayerTimes(city: cleanCity);

    Navigator.pop(context);

    ModernSnackBar.show(
      context,
      title: 'Wilayah Diperbarui',
      message: 'Jadwal sholat & puasa diperbarui untuk $cleanCity',
      type: SnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final showCustomCityOption =
        query.isNotEmpty &&
        !_filteredCities.any((c) => c.toLowerCase() == query.toLowerCase());

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // GPS Auto Detect Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _detectGpsLocation,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: const Text(
                'Deteksi Lokasi Otomatis (GPS)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
                elevation: 0,
                side: const BorderSide(color: AppColors.primaryMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pilih Wilayah / Kota',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Field Input
          TextField(
            controller: _searchController,
            onChanged: _filterCities,
            decoration: InputDecoration(
              hintText: 'Ketik nama kota di Indonesia atau Dunia...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filterCities('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Custom Entered City Option if not in list
          if (showCustomCityOption) ...[
            GestureDetector(
              onTap: () => _selectCity(query),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_location_alt_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gunakan Kota "$query"',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          const Text(
            'Daftar Kota Populer',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),

          // Cities List
          Expanded(
            child: ListView.separated(
              itemCount: _filteredCities.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.cardBorder),
              itemBuilder: (context, index) {
                final city = _filteredCities[index];
                final currentCity = Provider.of<PrayerProvider>(
                  context,
                  listen: false,
                ).currentCity;
                final isSelected =
                    currentCity.toLowerCase() == city.toLowerCase();

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                    size: 20,
                  ),
                  title: Text(
                    city,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                  onTap: () => _selectCity(city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Interactive Notification Settings Sheet Widget
class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet({super.key});

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  bool _masterNotification = true;
  bool _notifyImsak = true;
  bool _notifySubuh = true;
  bool _notifyDzuhur = true;
  bool _notifyAshar = true;
  bool _notifyMaghrib = true;
  bool _notifyIsya = true;

  bool _notifySahurReminder = true;
  bool _notifyIftharReminder = true;
  bool _notifyQuranReminder = false;

  String _selectedSoundType = 'Full Adzan'; // Full Adzan, Beep, Getar
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _masterNotification = prefs.getBool('notif_master') ?? true;
      _notifyImsak = prefs.getBool('notif_imsak') ?? true;
      _notifySubuh = prefs.getBool('notif_subuh') ?? true;
      _notifyDzuhur = prefs.getBool('notif_dzuhur') ?? true;
      _notifyAshar = prefs.getBool('notif_ashar') ?? true;
      _notifyMaghrib = prefs.getBool('notif_maghrib') ?? true;
      _notifyIsya = prefs.getBool('notif_isya') ?? true;
      _notifySahurReminder = prefs.getBool('notif_sahur_reminder') ?? true;
      _notifyIftharReminder = prefs.getBool('notif_ifthar_reminder') ?? true;
      _notifyQuranReminder = prefs.getBool('notif_quran_reminder') ?? false;
      _selectedSoundType = prefs.getString('notif_sound_type') ?? 'Full Adzan';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_master', _masterNotification);
    await prefs.setBool('notif_imsak', _notifyImsak);
    await prefs.setBool('notif_subuh', _notifySubuh);
    await prefs.setBool('notif_dzuhur', _notifyDzuhur);
    await prefs.setBool('notif_ashar', _notifyAshar);
    await prefs.setBool('notif_maghrib', _notifyMaghrib);
    await prefs.setBool('notif_isya', _notifyIsya);
    await prefs.setBool('notif_sahur_reminder', _notifySahurReminder);
    await prefs.setBool('notif_ifthar_reminder', _notifyIftharReminder);
    await prefs.setBool('notif_quran_reminder', _notifyQuranReminder);
    await prefs.setString('notif_sound_type', _selectedSoundType);

    await prefs.setBool('is_adhan_enabled', _masterNotification);
    await prefs.setBool('is_imsak_enabled', _notifyImsak);
    await prefs.setBool('is_iftar_enabled', _notifyMaghrib);

    if (!mounted) return;
    try {
      final notifProv = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      await notifProv.reloadSettings();

      final prayerProv = Provider.of<PrayerProvider>(context, listen: false);
      if (prayerProv.data != null) {
        await notifProv.schedulePrayerAlerts(prayerProv.data!);
      }
    } catch (e) {
      debugPrint(
        '[ProfilScreen] Non-fatal error updating notification schedule: $e',
      );
    }
  }

  void _playTestAdzan() async {
    try {
      await _audioPlayer?.stop();
      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setAsset('assets/audio/adzan.mp3');
      await _audioPlayer!.play();
    } catch (_) {}
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Pengaturan Notifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Master Notification Banner Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _masterNotification
                          ? AppColors.primaryLight
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _masterNotification
                            ? AppColors.primary
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aktifkan Semua Notifikasi Adzan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _masterNotification
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Suara adzan & pengingat waktu sholat realtime',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _masterNotification,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _masterNotification = val;
                              _notifyImsak = val;
                              _notifySubuh = val;
                              _notifyDzuhur = val;
                              _notifyAshar = val;
                              _notifyMaghrib = val;
                              _notifyIsya = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Title: Prayer Times
                  const Text(
                    'Jadwal Notifikasi Sholat 5 Waktu & Imsak',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Switches List
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          'Imsak & Sahur',
                          _notifyImsak,
                          (v) => setState(() => _notifyImsak = v),
                        ),
                        const Divider(height: 1, color: AppColors.cardBorder),
                        _buildSwitchTile(
                          'Sholat Subuh',
                          _notifySubuh,
                          (v) => setState(() => _notifySubuh = v),
                        ),
                        const Divider(height: 1, color: AppColors.cardBorder),
                        _buildSwitchTile(
                          'Sholat Dzuhur',
                          _notifyDzuhur,
                          (v) => setState(() => _notifyDzuhur = v),
                        ),
                        const Divider(height: 1, color: AppColors.cardBorder),
                        _buildSwitchTile(
                          'Sholat Ashar',
                          _notifyAshar,
                          (v) => setState(() => _notifyAshar = v),
                        ),
                        const Divider(height: 1, color: AppColors.cardBorder),
                        _buildSwitchTile(
                          'Maghrib / Buka Puasa',
                          _notifyMaghrib,
                          (v) => setState(() => _notifyMaghrib = v),
                        ),
                        const Divider(height: 1, color: AppColors.cardBorder),
                        _buildSwitchTile(
                          'Sholat Isya',
                          _notifyIsya,
                          (v) => setState(() => _notifyIsya = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Title: Special Reminders
                  Consumer<PrayerProvider>(
                    builder: (context, prayerProv, child) {
                      final isRamadhan = prayerProv.data?.isRamadhan ?? false;
                      return Text(
                        isRamadhan
                            ? 'Pengingat Khusus Ramadhan & Ibadah'
                            : 'Pengingat Sahur, Imsak & Ibadah Harian',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          'Pengingat Sahur',
                          _notifySahurReminder,
                          (v) => setState(() => _notifySahurReminder = v),
                        ),
                        const Divider(height: 1, color: AppColors.cardBorder),
                        _buildSwitchTile(
                          'Pengingat Buka Puasa',
                          _notifyIftharReminder,
                          (v) => setState(() => _notifyIftharReminder = v),
                        ),
                        const Divider(height: 1, color: AppColors.cardBorder),
                        _buildSwitchTile(
                          'Pengingat Tadarus Al-Qur\'an Harian',
                          _notifyQuranReminder,
                          (v) => setState(() => _notifyQuranReminder = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Title: Sound Preference
                  const Text(
                    'Jenis Suara & Nada Notifikasi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _buildSoundTypeCard('Full Adzan', 'Adzan Penuh'),
                      const SizedBox(width: 8),
                      _buildSoundTypeCard('Beep', 'Beep Singkat'),
                      const SizedBox(width: 8),
                      _buildSoundTypeCard('Getar', 'Getar Saja'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Buttons Action Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            _playTestAdzan();
                            try {
                              await Provider.of<NotificationProvider>(
                                context,
                                listen: false,
                              ).testInstantNotification();
                            } catch (_) {}

                            if (!context.mounted) return;
                            ModernSnackBar.show(
                              context,
                              title: 'Uji Coba Suara Adzan',
                              message:
                                  'Notifikasi push & gema suara Adzan dikirim ke perangkat Anda.',
                              type: SnackBarType.success,
                            );
                          },
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                            size: 18,
                          ),
                          label: const Text('Tes Notifikasi'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _saveSettings();
                              if (!context.mounted) return;
                              ModernSnackBar.show(
                                context,
                                title: 'Pengaturan Disimpan',
                                message:
                                    'Pengaturan notifikasi berhasil disimpan!',
                                type: SnackBarType.success,
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              if (!context.mounted) return;
                              ModernSnackBar.show(
                                context,
                                title: 'Gagal Menyimpan',
                                message:
                                    'Terjadi kesalahan saat menyimpan pengaturan.',
                                type: SnackBarType.error,
                              );
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Simpan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }

  Widget _buildSoundTypeCard(String typeKey, String label) {
    final isSelected = _selectedSoundType == typeKey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSoundType = typeKey;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
